package Plugin::Men;

use strict;
use warnings;

my $config;
my $root_config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	shift; # module config
	$root_config = shift;

	return $self;
}

sub on_message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;

	if (ref($where) eq "ARRAY") {
		$where = $where->[0];
	}

	if ($what =~ /(\w*men\w*)/) {
		my ($w, $c, $target);
		$w = $c = $target = $1;
		$w =~ s/men/women/;
		$c =~ s/men/children/;
		return "not just the $target, but the $w and $c too";
	}
	return;
}

sub on_action {
	on_message(@_);
}
1;
