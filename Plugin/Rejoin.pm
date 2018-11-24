package Plugin::Rejoin;

use strict;
use warnings;

my $config;
my $root_config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	$config = shift;
	$root_config = shift;

	return $self;
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

	$irc->yield(join => $where) if (grep {$_ eq $where} @{$root_config->{channels}});
	return;
}
1;
