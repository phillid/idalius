package Plugin::Antiflood;

use strict;
use warnings;

my $message_count = 5;
my $message_period = 11;


my %config;
my %lastmsg = ();

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	my $cref = $_[2];
	%config = %$cref;
	return $self;
}

sub message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $channel = $where->[0];
	my $nick = (split /!/, $who)[0];

	my $now = time();
	push @{$lastmsg{$nick}}, $now;

	if (@{$lastmsg{$nick}} >= $message_count) {
		@{$lastmsg{$nick}} = splice @{$lastmsg{$nick}}, 1, $message_count - 1;
		my $first = @{$lastmsg{$nick}}[0];
		if ($now - $first <= $message_period) {
			$irc->yield(kick => $channel => $nick => "Flood");
		}
	}
	return;
}

sub action {
	message(@_);
}
1;
