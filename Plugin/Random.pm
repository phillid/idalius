package Plugin::Random;

use strict;
use warnings;

use List::Util;

my %config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	my $cref = shift;
	%config = %$cref;

	$cmdref->("shuffle", sub { $self->shuffle(@_); } );
	$cmdref->("choose", sub { $self->choose(@_); } );

	return $self;
}

sub shuffle {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return join " ", List::Util::shuffle(@arguments);
}

sub choose {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;
	return (List::Util::shuffle(@arguments))[0];
}
1;
