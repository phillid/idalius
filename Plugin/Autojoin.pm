package Plugin::Autojoin;

use strict;
use warnings;

my $config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	$config = shift;
	shift; # root config

	return $self;
}

sub on_001_welcome {
	my ($self, $logger, $server, $message, $irc) = @_;
	$irc->yield(join => $_) for @{$config->{channels}};
	return;
}
1;
