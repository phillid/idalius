package Plugin::Titillate;

use strict;
use warnings;

use IdaliusConfig qw/assert_dict/;

my $config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	$config = shift;

	IdaliusConfig::assert_dict($config, $self, "triggers");

	return $self;
}

sub on_message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $gathered = "";
	my @expressions = (keys %{$config->{triggers}});
	my %responses;

	foreach (@expressions) {
		my $e = $_;
		while ($what =~ /($e)/gi) {
			$responses{$-[0]} .= $config->{triggers}->{$e};
		}
	}
	$gathered .= $responses{$_} foreach (sort { $a <=> $b } (keys %responses));

	return $gathered;
}

sub on_action {
	on_message(@_);
}
1;
