package Plugin::Ping;

use strict;
use warnings;

my %config;

sub configure {
	my $self = shift;
	my $cmdref = shift;

	$cmdref->("ping", sub { $self->ping(@_); } );

	return $self;
}

sub ping {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;
	my $nick = (split /!/, $who)[0];
	return "$nick: pong";
}
1;
