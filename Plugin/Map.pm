package Plugin::Map;

use strict;
use warnings;

use ListParser;

my $run_command;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	$run_command = shift;

	$cmdref->($self, "map", sub { $self->map(@_); } );

	return $self;
}


sub map {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;
	my ($command, $subjects_raw) = ($rest =~ /^(.+)\s+(\[.*\])$/);

	return "Syntax: map command [item1, item2, ...]" unless $command and $subjects_raw;

	my ($e, $from, $to, @subjects) = ListParser::parse_list($subjects_raw);
	return $e if $e;

	my @results = map { $run_command->("$command $_", $who, $where, $ided) } @subjects;
	return "[" . (join ", ", @results). "]";
}
1;
