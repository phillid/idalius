package Plugin::Introspect;

use strict;
use warnings;

my %config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	my $cref = shift;
	%config = %$cref;

	$cmdref->("plugins", sub { $self->dump_plugins(@_); } );

	return $self;
}

sub dump_plugins {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;
	return "Plugins: " . join ", ", @{$config{plugins}};
}
1;
