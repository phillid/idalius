package Plugin::Dad;

use strict;
use warnings;
use Encode qw/decode/;

use IdaliusConfig qw/assert_scalar/;

my $config;
my $root_config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	$config = shift;
	$root_config = shift;

	IdaliusConfig::assert_scalar($config, $self, "chance");
	die "chance must be from 0 to 100"
		unless $config->{chance} >= 0 && $config->{chance} <= 100;

	return $self;
}

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;

	return unless rand(100) < $config->{chance};

	if (ref($where) eq "ARRAY") {
		$where = $where->[0];
	}

	$what = Encode::decode('utf8', $what);

	print "$what\n";
	if ($what =~ /^i('|\s+a)m\s+(\w+)\s*$/) {
		return "Hi ".$2.", I'm dad";
	}
	return;
}
1;
