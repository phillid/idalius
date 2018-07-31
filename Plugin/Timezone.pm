#!/usr/bin/env perl

package Plugin::Timezone;

use strict;
use warnings;

use DateTime;

my %config;

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	my $cref = $_[2];
	%config = %$cref;

	$cmdref->("time", sub { $self->time(@_); } );

	return $self;
}

sub time {
	my ($self, $logger, $who, $where, $rest, @arguments) = @_;

	my $requester = (split /!/, $who)[0];
	my @known_zones = (keys %{$config{timezone}});

	return "Syntax: time [nick]" unless @arguments == 1;

	my $nick = $arguments[0];
	if (grep {$_ eq $nick} @known_zones) {
		my $d = DateTime->now();
		$d->set_time_zone($config{timezone}->{$nick});
		my $timestr = $d->strftime("%Y-%m-%d %H:%M %Z");
		return "$requester: $nick\'s clock reads $timestr";
	} else {
		return "$requester: I don't know what timezone $nick is in";
	}
}
1;
