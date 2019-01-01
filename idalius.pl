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

my $ignore_suffix = "_yes_really_even_from_ignored_nicks";
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

Plugin::set_load_callback(\&module_loaded_callback);

load_configure_all_plugins();

$| = 1;

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
			irc_join
			irc_part
			irc_invite
			irc_nick
			irc_disconnected
			irc_error
			irc_socketerr
			irc_delay_set
			irc_delay_removed
			custom_ping) ],
	],
	heap => { irc => $irc },
);

drop_priv();

$poe_kernel->run();


################################################################################
# Helpers and module framework
sub load_configure_all_plugins {
	eval {
		for my $module (@{$config->{_}->{plugins}}) {
			Plugin::load_plugin(\&log_info, $config->{_}, $module);
		}
		1;
	} or do {
		log_info "Error: failed to load module: $@";
		die;
	};
}

sub module_loaded_callback {
	my ($module) = @_;

	$module->configure(
		\&register_command,
		\&run_command,
		$config->{$module},
		$config->{_});
}

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

# Send an effect-free client->server message as a form of ping to allegedly
# help POE realise when a connection is down. It otherwise seems to not realise
# a connection has fallen over otherwise.
sub custom_ping {
	my ($poek) = $_[KERNEL];
	$poek->yield(userhost => $irc->nick_name());
	$poek->delay(custom_ping => $ping_delay);
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
	my ($who) = @_;
	for my $mask (@{$config->{_}->{ignore}}) {
		my $expr = $mask;
		$expr =~ s/([^[:alnum:]\*])/$1/g;
		$expr =~ s/\*/.*/g;
		if ($who =~ /^$expr$/) {
			return 1;
		}
	}
	return;
}

sub reconnect {
	my $reconnect_delay = 20;

	log_info("Reconnecting in $reconnect_delay seconds");
	sleep($reconnect_delay);

	$irc->yield(connect => { });
}


################################################################################
# Plugin event handling helpers
sub handle_common {
	my ($message_type, $who, $where, $what, $ided) = @_;
	my $nick = (split /!/, $who)[0];
	my $channel = $where->[0];
	my $output;

	$what =~ s/\s+$//g;

	# Firstly, trigger commands
	my $stripped_what = strip_color(strip_formatting($what));
	my $no_prefix_what = $stripped_what;
	my $current_nick = $irc->nick_name();
	if (!should_ignore($who) && ($config->{_}->{prefix_nick} && $no_prefix_what =~ s/^\Q$current_nick\E[:,]\s+//g ||
	    ($config->{_}->{prefix} && $no_prefix_what =~ s/^\Q$config->{_}->{prefix}//))) {
		$output = run_command($no_prefix_what, $who, $where, $ided);
		$irc->yield(privmsg => $where => $output) if $output;
		strike_add($nick, $channel) if $output;
	}

	# Secondly, trigger non-command handlers
	trigger_modules($message_type, $who, $where, ($who, $where, $what, $stripped_what));

	return;
}

# Trigger applicable non-command-bound handlers in any active modules for
# a given message type, passing them only the given arguments
sub trigger_modules {
	my ($message_type, $who, $where, @arguments) = @_;
	my $nick = (split /!/, $who)[0];

	for my $handler (handlers_for($message_type, $who)) {
		my @base_args = (\&log_info);
		push @base_args, @arguments;
		push @base_args, $irc;
		my $output = $handler->(@base_args);
		if ($output and $where) {
			$irc->yield(privmsg => $where => $output);
			strike_add($nick, $where->[0]);
		}
	}
	return;
}

# Return a list of subs capable of handling the given message type for a nick
sub handlers_for {
	my ($message_type, $who) = @_;
	my @handlers = ();
	my $nick = (split /!/, $who)[0];

	$message_type = "on_$message_type";
	for my $module (@{$config->{_}->{active_plugins}}) {
		if (module_is_enabled($module)) {
			if (!should_ignore($who) and $module->can($message_type)) {
				# Leave message type unchanged
			} elsif ($module->can($message_type.$ignore_suffix)) {
				$message_type = $message_type.$ignore_suffix;
			} else {
				# No handler
				next;
			}
			push @handlers, sub { $module->$message_type(@_); };
		}
	}
	return @handlers;
}


###############################################################################
# Begin internal/core handlers
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

	$heap->yield(join => $_) for @{$config->{_}->{channels}};
	$irc->delay(custom_ping => $ping_delay);
	return;
}

sub irc_ctcp_action {
	my ($sender, $who, $where, $what) = @_[SENDER, ARG0 .. ARG2];
	my $nick = ( split /!/, $who )[0];
	my $channel = $where->[0];

	handle_common("action", $who, $where, $what);
	return;
}

sub irc_public {
	my ($who, $where, $what, $ided) = @_[ARG0 .. ARG3];
	my $nick = ( split /!/, $who )[0];
	my $channel = $where->[0];
	handle_common("message", $who, $where, $what, $ided);
	return;
}

sub irc_join {
	my ($who, $channel) = @_[ARG0 .. ARG1];
	trigger_modules("join", $who, $channel, ($who, $channel));
	return;
}

sub irc_part {
	my ($who, $channel, $why) = @_[ARG0 .. ARG2];
	my $nick = ( split /!/, $who )[0];
	my @where = ($channel);

	trigger_modules("part", $who, $channel, ($who, $channel, $why));
	return;
}

sub irc_kick {
	my ($kicker, $channel, $kickee, $reason) = @_[ARG0 .. ARG3];
	trigger_modules("kick", $kicker, $channel, ($kicker, $channel, $kickee, $reason));
	return;
}

sub irc_nick {
	my ($who, $new_nick) = @_[ARG0 .. ARG1];
	trigger_modules("nick", $who, undef, ($who, $new_nick));
	return;
}

sub irc_invite {
	my ($who, $where) = @_[ARG0 .. ARG1];
	trigger_modules("invite", $who, undef, ($who, $where));
	return;
}

# FIXME these need implementing even if just for logging:
# irc_registered
# irc_shutdown
# irc_connected
# irc_ctcp_*
# irc_ctcpreply_*
# irc_disconnected
# irc_error
# irc_mode
# irc_notice
# irc_quit
# irc_socketerr
# irc_topic
# irc_whois
# irc_whowas

sub irc_msg {
	my ($who, $to, $what, $ided) = @_[ARG0 .. ARG3];
	my $nick = (split /!/, $who)[0];

	# FIXME trigger plugins with on_msg or something. Currently no privmsg
	# are logged, but Log.pm can do this for us.

	my $stripped_what = strip_color(strip_formatting($what));
	my $output = run_command($stripped_what, $who, $nick, $ided);
	$irc->yield(privmsg => $nick => $output) if $output;

	return;
}

###############################################################################

sub irc_disconnected {
	_default(@_); # Dump the message
	my $reconnect_delay = 20;

	$config = IdaliusConfig::parse_config($config_file);
	load_configure_all_plugins();
	reconnect();
}

sub irc_error {
	_default(@_); # Dump the message
	reconnect();
}

sub irc_socketerr {
	_default(@_); # Dump the message
	reconnect();
}

sub irc_delay_set {
	# nop, silence this
}
sub irc_delay_removed {
	# nop, silence this
}

sub _default {
	my ($event, $args) = @_[ARG0 .. $#_];

	# exit early unless in debug mode
	return unless $config->{_}->{log_debug};

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
