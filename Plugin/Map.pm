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

sub parse_list {
	my ($input) = @_;
	my @res;
	my $i = 0;

	# Index of the start of the current item
	my $item_i = 0;

	# Level of nested lists, 1 being the minimum
	my $nest = 1;

	# Are we currently lexing inside a string literal?
	my $is_string = 0;

	return ("Error: expected [", undef) unless substr($input, $i, 1) eq "[";
	$i++;
	$item_i = $i;

	while ($nest != 0 && $i < length($input)) {
		my $c = substr($input, $i, 1);

		if ($c eq "[") {
			$nest++;
		} elsif ($c eq "]") {
			$nest--;
		}

		if ($c eq "," || ($nest == 0 and $c eq "]")) {
			my $item = substr($input, $item_i, $i - $item_i);
			$item =~ s/^\s+|\s+$//g;
			push @res, $item;
			$item_i = $i+1;
		}
		$i++;
	}

	return ("Error: expected ], got end of line", undef) unless $nest == 0;

	return (undef, @res);
}

sub map {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;
	my ($command, $subjects_raw) = ($rest =~ /^(.+?)\s+(.*)$/);

	return "Syntax: map command [item1, item2, ...]" unless $command and $subjects_raw;

	my ($e, @subjects) = parse_list($subjects_raw);
	if ($e) {
		print "It's error";
	}
	$logger->("Error: $e");
	return $e if $e;

	my @results = map { $run_command->("$command $_", $who, $where) } @subjects;
	return "[" . (join ", ", @results). "]";
}
1;
