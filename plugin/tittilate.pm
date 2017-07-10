#!/usr/bin/env perl

package plugin::tittilate;

use strict;
use warnings;
use IRC::Utils qw(strip_color strip_formatting);

my %config;

sub configure {
	my $self = $_[0];
	my $cref = $_[1];
	%config = %$cref;
	return $self;
}

sub message {
	my ($self, $me, $who, $where, $what) = @_;
	$what = strip_color(strip_formatting($what));
	my $gathered = "";
	my @expressions = (keys %{$config{triggers}});
	my $expression = join '|', @expressions;
	while ($what =~ /($expression)/gi) {
		my $matched = $1;
		my $key;
		# figure out which key matched
		foreach (@expressions) {
			if ($matched =~ /$_/i) {
				$key = $_;
				last;
			}
		}
		$gathered .= $config{triggers}->{$key};
	}
	return $gathered;
}
1;
