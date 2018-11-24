package Plugin::Jinx;

# Makes idalius join in on streaks of a person/some people saying the same
# thing more than once in a row

use strict;
use warnings;

# Last message we responded to with a jinx
my %last_response;

# Last message said on the channel
my %last;

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	return $self;
}

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	my $channel = $where->[0];

	return if $last_response{$channel} and lc $what eq lc $last_response{$channel};

	if ($last{$channel} and lc $last{$channel} eq lc $what) {
		$last_response{$channel} = $what;
		return $what;
	}

	$last{$channel} = $what;
	$last_response{$channel} = undef;
	return;
}

sub on_action {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	my $channel = $where->[0];

	return if $last_response{$channel} and lc $what eq lc $last_response{$channel};

	if ($last{$channel} and lc $last{$channel} eq lc $what) {
		$last_response{$channel} = $what;
		$irc->yield(ctcp => $channel => "ACTION" => $what);
		return;
	}

	$last{$channel} = $what;
	$last_response{$channel} = undef;
	return;
}

# Even ignored nicks should be allowed to break a streak
sub on_message_yes_really_even_from_ignored_nicks {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	my $channel = $where->[0];

	return if $last{$channel} and lc $last{$channel} eq lc $what;

	$last{$channel} = undef;

	return;
}

# Even ignored nicks should be allowed to break a streak
sub on_action_yes_really_even_from_ignored_nicks {
	on_message_yes_really_even_from_ignored_nicks(@_);
}
1;
