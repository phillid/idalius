package Plugin::Log;

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

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	$logger->("[$where->[0]] $who: $raw_what");
	return;
}

sub on_action {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	$logger->("[$where->[0]] * $who $raw_what");
	return;
}

sub on_part {
	my ($self, $logger, $who, $where, $why, $irc) = @_;
	$logger->("[$where] --- $who left ($why)");
	return;
}

sub on_join {
	my ($self, $logger, $who, $where, $irc) = @_;
	$logger->("[$where] --- $who joined");
	return;
}

sub on_kick {
	my ($self, $logger, $kicker, $where, $kickee, $why, $irc) = @_;
	$logger->("[$where] !!! $kicker kicked $kickee ($why)");
	return;
}

sub on_nick {
	my ($self, $logger, $who, $new_nick, $irc) = @_;
	$logger->("$who changed nick to $new_nick");
	return;
}

sub on_invite {
	my ($self, $logger, $who, $where, $irc) = @_;
	$logger->("$who invited me to join $where");
	return;
}
1;
