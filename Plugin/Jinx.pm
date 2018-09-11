package Plugin::Jinx;

# Makes idalius join in on streaks of a person/some people saying the same
# thing more than once in a row

use strict;
use warnings;

# Last message we responded to with a jinx
my %last_response;

# Last message said on the channel
my %last;
my %config;

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	my $cref = $_[2];
	%config = %$cref;
	return $self;
}

sub on_message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $channel = $where->[0];

	return if $last_response{$channel} and $what eq $last_response{$channel};

	if ($last{$channel} and $last{$channel} eq $what) {
		$last_response{$channel} = $what;
		return $what;
	}

	$last{$channel} = $what;
	$last_response{$channel} = undef;
	return;
}

sub on_action {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $channel = $where->[0];

	return if $last_response{$channel} and $what eq $last_response{$channel};

	if ($last{$channel} and $last{$channel} eq $what) {
		$last_response{$channel} = $what;
		$irc->yield(ctcp => $channel->[0] => "ACTION" => $what);
		return;
	}

	$last{$channel} = $what;
	$last_response{$channel} = undef;
	return;
}
1;
