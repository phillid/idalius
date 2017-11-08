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
use Module::Pluggable search_path => "plugin", instantiate => 'configure';

my $config_file = "bot.conf";
my %config = config_file::parse_config($config_file);

$| = 1;

my $current_nick = $config{nick};

# Hack: coerce into numeric type
+$config{url_on};
+$config{url_len};

my @plugin_list = plugins("dummy", \%config);

# New PoCo-IRC object
my $irc = POE::Component::IRC->spawn(
	UseSSL => $config{usessl},
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
			irc_socketerr) ],
	],
	heap => { irc => $irc },
);

drop_priv();

$poe_kernel->run();

sub drop_priv {
	setgid($config{gid}) or die "Failed to setgid: $!\n";
	setuid($config{uid}) or die "Failed to setuid: $!\n";
}

sub log_info {
	# FIXME direct to a log file instead of stdout
	my $stamp = strftime("%Y-%m-%d %H:%M:%S %z", localtime);
	print "$stamp | @_\n";
}

sub _start {
	my $heap = $_[HEAP];
	my $irc = $heap->{irc};
	$irc->yield(register => 'all');
	$irc->yield(connect => { });
	return;
}

sub irc_001 {
	my $sender = $_[SENDER];
	my $irc = $sender->get_heap();

	log_info("Connected to server ", $irc->server_name());

	$irc->yield( join => $_ ) for @{$config{channels}};
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

	log_info("[$channel] $who: $what");

	# reject ignored nicks first
	return if (grep {$_ eq $nick} @{$config{ignore}});

	for my $module (@plugin_list) {
		my $stripped_what = strip_color(strip_formatting($what));
		my $output = $module->message(\&log_info, $irc->nick_name, $who, $where, $what, $stripped_what, $irc);
		$irc->yield(privmsg => $where => $output) if $output;
	}

	return;
}

sub irc_msg {
	my ($who, $to, $what, $ided) = @_[ARG0 .. ARG3];
	my $nick = (split /!/, $who)[0];
	if ($config{must_id} && $ided != 1) {
		$irc->yield(privmsg => $nick => "You must identify with services");
		return;
	}
	if (!grep {$_ eq $who} @{$config{admins}}) {
		$irc->yield(privmsg => $nick => "I am bot, go away");
		return;
	}
	# FIXME this needs tidying. Some of this can be factored out, surely.
	if ($what =~ /^nick\s/) {
		my ($newnick) = $what =~ /^nick\s+(\S+)$/;
		if ($newnick) {
			$irc->yield(nick => $newnick);
			$irc->yield(privmsg => $nick => "Requested.");
		} else {
			$irc->yield(privmsg => $nick => "Syntax: nick <nick>");
		}
	}
	if ($what =~ /^part\s/) {
		my $message;
		if ($what =~ /^part(\s+(\S+))+$/m) {
			$what =~ s/^part\s+//;
			my ($chan_str, $reason) = split /\s+(?!#)/, $what, 2;
			my @channels = split /\s+/, $chan_str;
			$reason = "Commanded by $nick" unless $reason;
			$irc->yield(part => @channels => $reason);
			$irc->yield(privmsg => $nick => "Requested.");
		} else {
			$irc->yield(privmsg => $nick =>
			            "Syntax: part <channel1> [channel2 ...] [partmsg]");
		}
	}
	if ($what =~ /^join\s/) {
		if ($what =~ /^join(\s+(\S+))+$/) {
			$what =~ s/^join\s+//;
			my @channels = split /\s+/, $what;
			$irc->yield(join => $_) for @channels;
			$irc->yield(privmsg => $nick => "Requested.");
		} else {
			$irc->yield(privmsg => $nick =>
			            "Syntax: join <channel1> [channel2 ...]");
		}
	}
	if ($what =~ /^say\s/) {
		my ($channel, $message) = $what =~ /^say\s+(\S+)\s(.*)$/;
		if ($channel and $message) {
			$irc->yield(privmsg => $channel => $message);
			$irc->yield(privmsg => $nick => "Requested.");
		} else {
			$irc->yield(privmsg => $nick => "Syntax: say <channel> <msg>");
		}
	}
	if ($what =~ /^action\s/) {
		my ($channel, $action) = $what =~ /^action\s+(\S+)\s(.*)$/;
		if ($channel and $action) {
			$irc->yield(ctcp => $channel => "ACTION $action");
			$irc->yield(privmsg => $nick => "Requested.");
		} else {
			$irc->yield(privmsg => $nick => "Syntax: action <channel> <action text>");
		}
	}
	if ($what =~ /^kick\s/) {
		my ($channel, $kickee, undef, $reason) = $what =~ /^kick\s+(\S+)\s(\S+)((?:\s)(.*))?$/;
		if ($channel and $kickee) {
			$reason = "Requested by $nick" unless $reason;
			$irc->yield(kick => $channel => $kickee => $reason);
			$irc->yield(privmsg => $nick => "Requested.");
		} else {
			$irc->yield(privmsg => $nick => "Syntax: kick <channel> <nick> [reason]");
		}
	}
	if ($what =~ /^reconnect/) {
		my ($reason) = $what =~ /^reconnect\s+(.+)$/;
		$irc->yield(privmsg => $nick => "Doing that now");
		if (!$reason) {
			$reason = $config{quit_msg};
		}
		$irc->yield(quit => $reason);
	}
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
