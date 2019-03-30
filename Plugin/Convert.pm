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

	return "Syntax: convert <from> to <to>\n" unless ($from and $to);

	my ($out, $in);
	my $pid = open2($out, $in, 'units', '-1', '--compact', '--quiet');

	print $in "$from\n$to\n";
	my $converted = <$out>;
	chomp $converted;

	close($in);
	waitpid($pid, 0);
	my $exit_status = $? >> 8;
	# `units` doesn't actually seem to set this non-zero, but use it anyway
	return "Conversion error" if $exit_status;

	return "Converted: $converted\n";
}
1;
