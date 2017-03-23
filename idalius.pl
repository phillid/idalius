#!/usr/bin/env perl

use strict;
use warnings;
use POSIX qw(setuid setgid);
use POE;
use POE::Kernel;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::NickServID;
use sb_config;

my %config = sb_config::parse_config('bot.conf');

my $current_nick = $config{nick};

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
$irc->plugin_add('NickServID', POE::Component::IRC::Plugin::NickServID->new(
	Password => $config{password}
));

POE::Session->create(
	package_states => [
		main => [ qw(_default _start irc_001 irc_kick irc_ctcp_action irc_public irc_msg irc_nick irc_disconnected ) ],
	],
	heap => { irc => $irc },
);

drop_priv();

$poe_kernel->run();

sub drop_priv {
	setgid($config{gid}) or die "Failed to setgid: $!\n";
	setuid($config{uid}) or die "Failed to setuid: $!\n";
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

	print "Connected to server ", $irc->server_name(), "\n";

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
		print "I was kicked by $kicker ($reason). Rejoining now.\n";
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

	print("$channel $who: $what\n");

	# reject ignored nicks first
	return if (grep {$_ eq $nick} @{$config{ignore}});

	my $me = $irc->nick_name;

	my $collected_response = "";
	my @expressions = (keys %{$config{triggers}});
	my $expression = join '|', @expressions;
	while ($what =~ /($expression)/gi) {
		my $matched = $1;
		my $key;
		# figure out which key matched
		foreach (@expressions) {
			if ($matched =~ /$_/i) {
				$key = $_;
				last;
			}
		}
		$collected_response .= $config{triggers}->{$key};
	}
	$irc->yield(privmsg => $channel => $collected_response) if $collected_response;

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
	if ($what =~ /^nick\s/) {
		my ($channel) = $what =~ /^nick\s+(\S+)$/;
		if ($channel) {
			$irc->yield(nick => $channel);
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
			$irc->yield(part => @channels => $reason);
		} else {
			$irc->yield(privmsg => $nick => "Syntax: part <channel1> [channel2 ...] [partmsg]");
		}
	}
	if ($what =~ /^join\s/) {
		if ($what =~ /^join(\s+(\S+))+$/) {
			$what =~ s/^join\s+//;
			my @channels = split /\s+/, $what;
			$irc->yield(join => $_) for @channels;
		} else {
			$irc->yield(privmsg => $nick => "Syntax: join <channel1> [channel2 ...]");
		}
	}
	if ($what =~ /^say\s/) {
		my ($channel, $message) = $what =~ /^say\s+(\S+)\s(.*)$/;
		if ($channel and $message) {
			$irc->yield(privmsg => $channel => $message);
		} else {
			$irc->yield(privmsg => $nick => "Syntax: say <channel> <msg>");
		}
	}
	if ($what =~ /^reconnect/) {
		my ($reason) = $what =~ /^reconnect\s+(.+)$/;
		if (!$reason) {
			$reason = $config{quit_msg};
		}
		$irc->yield(quit => $reason);
	}
	return;
}

sub irc_disconnected {
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
	print join ' ', @output, "\n";
	return;
}
