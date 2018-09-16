package Plugin::Echo;

use strict;
use warnings;

sub configure {
	my $self = shift;
	my $cmdref = shift;

	$cmdref->("echo", sub { $self->echo(@_); } );

	return $self;
}

sub echo {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return $rest;
}
1;
