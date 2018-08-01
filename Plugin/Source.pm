#!/usr/bin/env perl

package Plugin::Source;

use strict;
use warnings;

my %config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	my @source_commands = ("guts", "help", "source");
	$cmdref->($_, sub { $self->source(@_); }) for @source_commands;
	return $self;
}

sub source {
	my ($self, $logger, $who, $where, $rest, @arguments) = @_;
	my @urls = ("https://gitlab.com/dphillips/idalius");
	my $help_message = "My guts can be browsed at: ";
	return $help_message . join " ", @urls;
}
1;
