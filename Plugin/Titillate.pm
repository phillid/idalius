package Plugin::Titillate;

use strict;
use warnings;

my %config;

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	my $cref = $_[2];
	%config = %$cref;
	return $self;
}

sub on_message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $gathered = "";
	my @expressions = (keys %{$config{triggers}});
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
		$gathered .= $config{triggers}->{$key};
	}
	return $gathered;
}

sub on_action {
	on_message(@_);
}
1;
