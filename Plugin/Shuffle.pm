package Plugin::Shuffle;

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

	return $self;
}

sub shuffle {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return join " ", List::Util::shuffle(@arguments);
}
1;
