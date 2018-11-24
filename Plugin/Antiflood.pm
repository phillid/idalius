package Plugin::Antiflood;

use strict;
use warnings;

my $message_count = 5;
my $message_period = 11;


my %lastmsg = ();

sub configure {
	my $self = shift;
	my $cmdref = shift;
	return $self;
}

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
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

sub on_action {
	on_message(@_);
}
1;
