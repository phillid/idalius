#!/usr/bin/env perl

package plugin::timezone;

use strict;
use warnings;

use DateTime;

my %config;

sub configure {
	my $self = $_[0];
	my $cref = $_[1];
	%config = %$cref;
	return $self;
}

sub message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;

	my $who_nick = ( split /!/, $who )[0];

	my @known_zones = (keys %{$config{timezone}});
	if ($what =~ /^%time\s/) {
		if ($what =~ /^%time\s+(.+?)\s*$/) {
			my $nick = $1;
			if (grep {$_ eq $nick} @known_zones) {
				my $d = DateTime->now();
				$d->set_time_zone($config{timezone}->{$nick});
				return "$who_nick: $nick\'s clock reads $d";
			} else {
				return "$who_nick: I don't know what timezone $nick is in";
			}
		} else {
			return "$who_nick: Syntax: %time [nick]";
		}
	}
}
1;
