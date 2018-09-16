package Plugin::DevNull;

use strict;
use warnings;

my $run_command;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	$run_command = shift;

	$cmdref->("hush", sub { $self->hush(@_); } );
	$cmdref->("devnull", sub { $self->hush(@_); } );

	return $self;
}

sub hush {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	$run_command->($rest, $who, $where);

	return;
}
1;
