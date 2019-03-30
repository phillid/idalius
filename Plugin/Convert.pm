package Plugin::Convert;

use strict;
use warnings;
use IPC::Open2;

sub configure {
	my $self = shift;
	my $cmdref = shift;

	$cmdref->($self, "convert", sub { $self->convert(@_); } );
	$cmdref->($self, "define", sub { $self->define(@_); } );

	return $self;
}

sub convert_common {
	my ($from, $to) = @_;

	my ($out, $in, $pid);
	my @command = (
		'units',
		'-1',
		'--compact',
		'--quiet',
		'--',
		$from
	);

	if ($to) {
		push @command, $to;
	}

	eval {
		$pid = open2($out, $in, @command);
	} or do {
		return "Error: units command not installed";
	};

	my $output = <$out>;
	chomp $output;
	waitpid($pid, 0);
	my $exit_status = $? >> 8;
	return "Error: $output" if $exit_status;

	return "$output"
}

sub convert {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	my $from = (split / to /, $rest)[0];
	my $to = (split / to /, $rest)[1];

	return "Syntax: convert <from> [to <to>]\n" unless ($from);

	my $converted = convert_common($from, $to);
	return "Define $from: $converted\n" unless $to;
	return "Convert $from -> $to: $converted\n";
}

sub define {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return "Syntax: define [unit/expression]\n" unless ($rest);

	my $defn = convert_common($rest, undef);
	return "Define $rest: $defn\n";
}

1;
