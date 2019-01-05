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
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;
	my ($command, $subjects_raw) = ($rest =~ /^(.+)\s+(\[.*\])$/);

	return "Syntax: map command [item1, item2, ...]" unless $command and $subjects_raw;

	my $parsed = ListParser::parse_list($subjects_raw);
	return $parsed->{error} if $parsed->{error};

	my @results = map { $run_command->("$command $_", $who, $where, $ided) } @{$parsed->{array}};
	return "[" . (join ", ", @results). "]";
}
1;
