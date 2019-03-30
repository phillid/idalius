package Plugin::Convert;

use strict;
use warnings;
use IPC::Open2;

sub configure {
	my $self = shift;
	my $cmdref = shift;

	$cmdref->($self, "convert", sub { $self->convert(@_); } );

	return $self;
}

sub convert {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	my $from = (split / to /, $rest)[0];
	my $to = (split / to /, $rest)[1];

	return "Syntax: convert <from> [to <to>]\n" unless ($from);

	my ($out, $in);
	my $pid;
	if ($to) {
		$pid = open2($out, $in, 'units', '-1', '--compact', '--quiet', $from, $to);
	} else {
		$pid = open2($out, $in, 'units', '-1', '--compact', '--quiet', $from);
	}

	my $converted = <$out>;
	chomp $converted;

	close($in);
	waitpid($pid, 0);

	my $exit_status = $? >> 8;
	# `units` doesn't actually seem to set this non-zero, but use it anyway
	return "Error: $converted" if $exit_status;

	if ($to) {
		return "Convert $from -> $to: $converted\n";
	} else {
		return "Define $from: $converted\n";
	}
}
1;
