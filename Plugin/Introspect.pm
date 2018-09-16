package Plugin::Introspect;

use strict;
use warnings;

my $root_config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	shift; # module config
	$root_config = shift;

	$cmdref->("plugins", sub { $self->dump_plugins(@_); } );

	return $self;
}

sub dump_plugins {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;
	return "Plugins: " . join ", ", $root_config->{plugins};
}
1;
