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
	my $expression = join '|', @expressions;
	while ($what =~ /($expression)/gi) {
		my $matched = $1;
		my $key;
		# figure out which key matched
		foreach (@expressions) {
			if ($matched =~ /$_/i) {
				$key = $_;
				last;
			}
		}
		$gathered .= $config->{triggers}->{$key};
	}
	return $gathered;
}

sub on_action {
	on_message(@_);
}
1;
