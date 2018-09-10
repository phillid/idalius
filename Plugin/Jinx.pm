package Plugin::Jinx;

# Makes idalius join in on streaks of a person/some people saying the same
# thing more than once in a row

use strict;
use warnings;

# Last message we responded to with a jinx
my $last_response = undef;

# Last message said on the channel, and whether it's action or message
my $last = undef;
my %config;

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	my $cref = $_[2];
	%config = %$cref;
	return $self;
}

sub message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;

	return if defined $last_response and $what eq $last_response;

	if (defined $last and $last eq $what) {
		$last_response = $last;
		return $last;
	}

	$logger->("Storing $what");

	$last = $what;
	$last_response = undef;
	return;
}

sub action {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;

	return if defined $last_response and $what eq $last_response;

	if (defined $last and $last eq $what) {
		$last_response = $last;
		$irc->yield(ctcp => $where->[0] => "ACTION" => $what);
		return;
	}

	$logger->("Storing action $what");

	$last = $what;
	$last_response = undef;
	return;
}
1;
