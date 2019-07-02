package Plugin::Autojoin;

use strict;
use warnings;

my $config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	$config = shift;
	shift; # root config

	return $self;
}

sub on_001_welcome {
	my ($self, $logger, $server, $message, $irc) = @_;
	$irc->yield(join => $_) for @{$config->{channels}};
	return;
}

sub on_kick {
	my ($self, $logger, $kicker, $where, $kickee, $why, $irc) = @_;
	if ($kickee eq $irc->nick_name) {
		$logger->("I was kicked from $where. Rejoining now...");
		$irc->yield(join => $where);
	}
	return;
}

sub on_invite {
	my ($self, $logger, $who, $where, $irc) = @_;

	$irc->yield(join => $where) if (grep {$_ eq $where} @{$config->{channels}});
	return;
}
1;
