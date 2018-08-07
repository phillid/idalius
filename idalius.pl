#!/usr/bin/env perl

use strict;
use warnings;
use POSIX qw(setuid setgid strftime);
use POE;
use POE::Kernel;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::NickServID;
use config_file;
use IRC::Utils qw(strip_color strip_formatting);
use Module::Pluggable search_path => "Plugin", instantiate => 'configure';

my $config_file = "bot.conf";
my %config = config_file::parse_config($config_file);
my %laststrike = ();
my $ping_delay = 300;

my %commands = ();

$| = 1;

my $current_nick = $config{nick};

# Hack: coerce into numeric type
+$config{url_on};
+$config{url_len};

my @plugin_list = plugins("dummy", \&register_command, \%config, \&run_command);

# New PoCo-IRC object
my $irc = POE::Component::IRC->spawn(
	UseSSL => $config{usessl},
	SSLCert => $config{sslcert},
	SSLKey => $config{sslkey},
	nick => $config{nick},
	ircname => $config{ircname},
	port    => $config{port},
	server  => $config{server},
	username => $config{username},
) or die "Failed to create new PoCo-IRC: $!";

# Plugins
$config{password} and $irc->plugin_add(
	'NickServID',
	POE::Component::IRC::Plugin::NickServID->new(
		Password => $config{password}
	));

POE::Session->create(
	package_states => [
		main => [ qw(
			_default
			_start
			irc_001
			irc_kick
			irc_ctcp_action
			irc_public
			irc_msg
			irc_invite
			irc_nick
			irc_disconnected
			irc_error
			irc_socketerr
			custom_ping) ],
	],
	heap => { irc => $irc },
);

drop_priv();

$poe_kernel->run();

sub log_info {
	# FIXME direct to a log file instead of stdout
	my $stamp = strftime("%Y-%m-%d %H:%M:%S %z", localtime);
	print "$stamp | @_\n";
}

# Register a command name to a certain sub
sub register_command {
	my ($command, $action) = @_;
	log_info "Registering command: $command";
	$commands{$command} = $action;
}

sub run_command {
	my ($command_string, $who, $where) = @_;
	my @arguments;
	my $command_verbatim;
	my $command;

	for my $c (keys %commands) {
		if (($command_verbatim) = $command_string =~ m/^(\Q$c\E( |$))/) {
			$command = $c;
			last;
		}
	}

	return "No such command" unless $command;

	my $rest = (split "\Q$command_verbatim", $command_string, 2)[1];
	@arguments = split /\s+/, $rest if $rest;

	return ($commands{$command})->($irc, \&log_info, $who, $where, $rest, @arguments);
}

sub custom_ping {
	my ($irc, $heap) = @_[KERNEL, HEAP];
	$irc->yield(userhost => $current_nick);
	$irc->delay(custom_ping => $ping_delay);
}

sub drop_priv {
	setgid($config{gid}) or die "Failed to setgid: $!\n";
	setuid($config{uid}) or die "Failed to setuid: $!\n";
}

# Add a strike against a nick for module flood protection
# This differs from antiflood.pm in that it is used only for when users have
# triggered a response from the bot.
sub strike_add {
	my $strike_count = 14;
	my $strike_period = 45;

	my ($nick, $channel) = @_;
	my $now = time();
	push @{$laststrike{$nick}}, $now;
	if (@{$laststrike{$nick}} >= $strike_count) {
		@{$laststrike{$nick}} = splice @{$laststrike{$nick}}, 1, $strike_count - 1;
		my $first = @{$laststrike{$nick}}[0];
		if ($now - $first <= $strike_period) {
			log_info "Ignoring $nick because of command flood";
			$irc->yield(privmsg => $channel => "$nick: I'm ignoring you now, you've caused me to talk too much");
			push @{$config{ignore}}, $nick;
		}
	}
}

sub _start {
	my $heap = $_[HEAP];
	my $irc = $heap->{irc};
	$irc->yield(register => 'all');
	$irc->yield(connect => { });
	return;
}

sub irc_001 {
	my ($irc, $sender) = @_[KERNEL, SENDER];
	my $heap = $sender->get_heap();

	log_info("Connected to server ", $heap->server_name());

	$heap->yield(join => $_) for @{$config{channels}};
	$irc->delay(custom_ping => $ping_delay);
	return;
}

sub irc_nick {
	my ($who, $new_nick) = @_[ARG0 .. ARG1];
	my $oldnick = (split /!/, $who)[0];
	if ($oldnick eq $current_nick) {
		$current_nick = $new_nick;
	}
	return;
}

sub irc_kick {
	my ($kicker, $channel, $kickee, $reason) = @_[ARG0 .. ARG3];
	if ($kickee eq $current_nick) {
		log_info("I was kicked by $kicker ($reason). Rejoining now.");
		$irc->yield(join => $channel);
	}
	return;
}

sub irc_ctcp_action {
	irc_public(@_);
}

sub irc_public {
	my ($sender, $who, $where, $what) = @_[SENDER, ARG0 .. ARG2];
	my $nick = ( split /!/, $who )[0];
	my $channel = $where->[0];
	my $output;

	log_info("[$channel] $who: $what");

	# reject ignored nicks first
	return if (grep {$_ eq $nick} @{$config{ignore}});

	my $stripped_what = strip_color(strip_formatting($what));
	if ($stripped_what =~ s/^$config{prefix}//) {
		$output = run_command($stripped_what, $who, $where);
		$irc->yield(privmsg => $where => $output) if $output;
		strike_add($nick, $channel) if $output;
	}

	for my $module (@plugin_list) {
		$output = "";
		if ($module->can("message")) {
			$output = $module->message(\&log_info, $irc->nick_name, $who, $where, $what, $stripped_what, $irc);
		}
		$irc->yield(privmsg => $where => $output) if $output;
		strike_add($nick, $channel) if $output;
	}

	return;
}

sub irc_msg {
	my ($who, $to, $what, $ided) = @_[ARG0 .. ARG3];
	my $nick = (split /!/, $who)[0];
	my $is_admin = grep {$_ eq $who} @{$config{admins}};

	# reject ignored nicks who aren't also admins (prevent lockout)
	return if (grep {$_ eq $nick} @{$config{ignore}} and not $is_admin);

	if ($config{must_id} && $ided != 1) {
		$irc->yield(privmsg => $nick => "You must identify with services");
		return;
	}
	return unless $is_admin;

	my $stripped_what = strip_color(strip_formatting($what));
	my $output = run_command($stripped_what, $who, $nick);
	$irc->yield(privmsg => $nick => $output) if $output;

	return;
}

sub irc_invite {
	my ($who, $where) = @_[ARG0 .. ARG1];
	$irc->yield(join => $where) if (grep {$_ eq $where} @{$config{channels}});
}

sub irc_disconnected {
	_default(@_); # Dump the message
	%config = config_file::parse_config($config_file);
	$irc->yield(connect => { });
}

sub irc_error {
	_default(@_); # Dump the message
	$irc->yield(connect => { });
}

sub irc_socketerr {
	_default(@_); # Dump the message
	$irc->yield(connect => { });
}

sub _default {
	my ($event, $args) = @_[ARG0 .. $#_];
	my @output = ( "$event: " );

	for my $arg (@$args) {
		if ( ref $arg eq 'ARRAY' ) {
			push( @output, '[' . join(', ', @$arg ) . ']' );
		}
		else {
			push ( @output, "'$arg'" );
		}
	}
	log_info(join ' ', @output);
	return;
}
