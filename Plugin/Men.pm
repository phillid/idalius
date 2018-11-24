package Plugin::Men;

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

	if ($what =~ /(\w*men\w*)/i) {
		my ($w, $c, $target);
		$w = $c = $target = $1;
		$w =~ s/men/women/i;
		$c =~ s/men/children/i;
		return "not just the $target, but the $w and $c too";
	}
	return;
}

sub on_action {
	on_message(@_);
}
1;
