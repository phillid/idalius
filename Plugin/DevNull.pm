package Plugin::DevNull;

use strict;
use warnings;

my %config;
my $run_command;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	my $cref = shift;
	$run_command = shift;
	%config = %$cref;

	$cmdref->("hush", sub { $self->hush(@_); } );
	$cmdref->("devnull", sub { $self->hush(@_); } );

	return $self;
}

sub hush {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	$run_command->($rest);

	return;
}
1;
