#!/usr/bin/env perl

use strict;
use warnings;
use POSIX qw(setuid setgid strftime);
use POE;
use POE::Kernel;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::NickServID;
use IdaliusConfig;
use Plugin qw/load_plugin/;
use IRC::Utils qw(strip_color strip_formatting);

my $config_file = "bot.conf";
my $config = IdaliusConfig::parse_config($config_file);
my %laststrike = ();
my $ping_delay = 300;
my %commands = ();

sub log_info {
	# FIXME direct to a log file instead of stdout
	my $stamp = strftime("%Y-%m-%d %H:%M:%S %z", localtime);
	print "$stamp | @_\n";
}

eval {
	for my $module (@{$config->{_}->{plugins}}) {
		Plugin::load_plugin(\&log_info, $config->{_}, $module);
		$module->configure(
			\&register_command,
			\&run_command,
			$config->{$module},
			$config->{_});
	}
	1;
} or do {
	log_info "Error: failed to load module: $@";
	die;
};

$| = 1;

my $current_nick = $config->{_}->{nick};

# New PoCo-IRC object
my $irc = POE::Component::IRC->spawn(
	UseSSL => $config->{_}->{usessl},
	SSLCert => $config->{_}->{sslcert},
	SSLKey => $config->{_}->{sslkey},
	nick => $config->{_}->{nick},
	ircname => $config->{_}->{ircname},
	port    => $config->{_}->{port},
	server  => $config->{_}->{server},
	username => $config->{_}->{username},
) or die "Failed to create new PoCo-IRC: $!";

# Plugins
$config->{_}->{password} and $irc->plugin_add(
	'NickServID',
	POE::Component::IRC::Plugin::NickServID->new(
		Password => $config->{_}->{password}
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

sub module_is_enabled {
	my $module = $_[0];

	return grep {$_ eq $module} @{$config->{_}->{active_plugins}};
}

# Register a command name to a certain sub
sub register_command {
	my ($owner, $command, $action) = @_;
	$command = lc $command;
	log_info "Registering command: $command (from $owner)";
	$commands{$owner}{$command} = $action;
}

sub run_command {
	my ($command_string, $who, $where, $ided) = @_;
	my @arguments;
	my $owner;
	my $command_verbatim;
	my $command;

	OUTER: for my $o (keys %commands) {
		next unless module_is_enabled($o);
		for my $c (keys %{$commands{$o}}) {
			if (($command_verbatim) = $command_string =~ m/^(\Q$c\E( |$))/i) {
				$command = lc $c;
				$owner = $o;
				last OUTER;
			}
		}
	}

	return "No such command" unless $command;

	my $rest = (split "\Q$command_verbatim", $command_string, 2)[1];
	@arguments = split /\s+/, $rest if $rest;

	my $action = $commands{$owner}{$command};
	return $action->($irc, \&log_info, $who, $where, $ided, $rest, @arguments);
}
sub custom_ping {
	my ($irc, $heap) = @_[KERNEL, HEAP];
	$irc->yield(userhost => $current_nick);
	$irc->delay(custom_ping => $ping_delay);
}

sub drop_priv {
	setgid($config->{_}->{gid}) or die "Failed to setgid: $!\n";
	setuid($config->{_}->{uid}) or die "Failed to setuid: $!\n";
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
			push @{$config->{_}->{ignore}}, $nick;
		}
	}
}

sub should_ignore {
	my ($nick) = @_;
	return grep {$_ eq $nick} @{$config->{_}->{ignore}};
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

	$current_nick = $config->{_}->{nick};
	$heap->yield(join => $_) for @{$config->{_}->{channels}};
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

sub handle_common {
	my ($message_type, $who, $where, $what, $ided) = @_;
	my $nick = (split /!/, $who)[0];
	my $channel = $where->[0];
	my $output;

	$what =~ s/^\s+|\s+$//g;

	my $stripped_what = strip_color(strip_formatting($what));
	my $no_prefix_what = $stripped_what;
	if (!should_ignore($nick) && ($config->{_}->{prefix_nick} && $no_prefix_what =~ s/^\Q$current_nick\E[:,]\s+//g ||
	    $no_prefix_what =~ s/^$config->{_}->{prefix}//)) {
		$output = run_command($no_prefix_what, $who, $where, $ided);
		$irc->yield(privmsg => $where => $output) if $output;
		strike_add($nick, $channel) if $output;
	}

	# handler names are defined as being prefixed with on_
	$message_type = "on_$message_type";
	my $ignore_suffix = "_yes_really_even_from_ignored_nicks";
	for my $module (@{$config->{_}->{active_plugins}}) {
		if (module_is_enabled($module)) {
			if (!should_ignore($nick) and $module->can($message_type)) {
				# Leave message type unchanged
			} elsif ($module->can($message_type.$ignore_suffix)) {
				# Handler for non-ignored and ignored exists
				$message_type = $message_type.$ignore_suffix;
			} else {
				# No handler
				next;
			}
			$output = $module->$message_type(\&log_info, $irc->nick_name, $who, $where, $what, $stripped_what, $irc);
			$irc->yield(privmsg => $where => $output) if $output;
			strike_add($nick, $channel) if $output;
		}
	}

	return;
}

sub irc_ctcp_action {
	my ($sender, $who, $where, $what) = @_[SENDER, ARG0 .. ARG2];
	my $nick = ( split /!/, $who )[0];
	my $channel = $where->[0];

	log_info("[$channel] [action] $who $what");

	return handle_common("action", $who, $where, $what);
}

sub irc_public {
	my ($who, $where, $what, $ided) = @_[ARG0 .. ARG3];
	my $nick = ( split /!/, $who )[0];
	my $channel = $where->[0];

	log_info("[$channel] $who: $what");

	return handle_common("message", $who, $where, $what, $ided);
}

sub irc_msg {
	my ($who, $to, $what, $ided) = @_[ARG0 .. ARG3];
	my $nick = (split /!/, $who)[0];

	my $stripped_what = strip_color(strip_formatting($what));
	my $output = run_command($stripped_what, $who, $nick, $ided);
	$irc->yield(privmsg => $nick => $output) if $output;

	return;
}

sub irc_invite {
	my ($who, $where) = @_[ARG0 .. ARG1];
	$irc->yield(join => $where) if (grep {$_ eq $where} @{$config->{_}->{channels}});
}

sub irc_disconnected {
	_default(@_); # Dump the message
	$config = IdaliusConfig::parse_config($config_file);
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
