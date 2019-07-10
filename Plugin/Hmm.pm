package Plugin::Hmm;

use strict;
use warnings;

my $root_config;
my $config;
my %current_alarm;
my %lines_since;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	$config = shift;
	$root_config = shift;

	IdaliusConfig::assert_scalar($config, $self, "min_delay_sec");
	IdaliusConfig::assert_scalar($config, $self, "max_delay_sec");
	IdaliusConfig::assert_scalar($config, $self, "lines_break");

	return $self;
}

# FIXME dedup with Natural.pm
sub some {
	my @choices = @_;
	return $choices[rand(@choices)];
}

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	my $nick = (split /!/, $who)[0];

	# Don't perform this in q to users
	return if ref($where) ne "ARRAY";
	$where = $where->[0];

	# Require some minimum number of lines in a channel before hmming again
	return unless $lines_since{$where}++ >= $config->{lines_break};

	if (defined $current_alarm{$where}) {
		$irc->delay_remove($current_alarm{$where});
	}

	my $response = some("Hmm", "hmm", "hmmmmmm", "oof", "mmm", "Hi Animatronio!");

	$current_alarm{$where} = $irc->delay([privmsg => $where => $response],
		$config->{min_delay_sec} + rand($config->{max_delay_sec} - $config->{min_delay_sec}));

	$lines_since{$where} = 0;

	return;
}

sub on_action {
	on_message @_;
}
1;
