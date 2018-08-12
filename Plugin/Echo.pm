package Plugin::Echo;

use strict;
use warnings;

my %config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	my $cref = shift;
	%config = %$cref;

	$cmdref->("echo", sub { $self->echo(@_); } );

	return $self;
}

sub echo {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return $rest;
}
1;
