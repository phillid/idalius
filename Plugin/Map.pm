package Plugin::Map;

use strict;
use warnings;

my %config;
my $run_command;


sub configure {
	my $self = shift;
	my $cmdref = shift;
	my $cref = shift;
	%config = %$cref;
	$run_command = shift;

	$cmdref->("map", sub { $self->map(@_); } );

	return $self;
}

sub map {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;
	my ($command, $subjects) = ($rest =~ /^(.+?)\s+(.*)$/);

	return "[]" unless $subjects;

	my @array = map { $run_command->("$command $_", $who, $where) } (split /,/, $subjects);

	return "[" . (join ", ", @array). "]";
}
1;
