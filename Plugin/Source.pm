package Plugin::Source;

use strict;
use warnings;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	my @source_commands = ("guts", "help", "source");
	$cmdref->($self, $_, sub { $self->source(@_); }) for @source_commands;
	return $self;
}

sub source {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;
	my @urls = (
		"https://git.nah.nz/idalius/",
		"https://gitlab.com/dphillips/idalius");
	my $help_message = "My guts can be browsed at: ";
	return $help_message . join " ", @urls;
}
1;
