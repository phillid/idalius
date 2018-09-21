package Plugin::Random;

use strict;
use warnings;

use List::Util;

sub configure {
	my $self = shift;
	my $cmdref = shift;

	$cmdref->($self, "shuffle", sub { $self->shuffle(@_); } );
	$cmdref->($self, "choose", sub { $self->choose(@_); } );

	return $self;
}

sub shuffle {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;

	return join " ", List::Util::shuffle(@arguments);
}

sub choose {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;
	return (List::Util::shuffle(@arguments))[0];
}
1;
