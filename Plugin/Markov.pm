package Plugin::Markov;

use strict;
use warnings;
use HTTP::Tiny;
use HTML::Parser;
use HTML::Entities;
use utf8;
use Encode;

use IdaliusConfig qw/assert_scalar/;

my $config;
my %markov_data;

sub configure
{
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	$config = shift;

	IdaliusConfig::assert_scalar($config, $self, "chance");
	die "chance must be non-negative" unless $config->{chance};

	IdaliusConfig::assert_scalar($config, $self, "log_file");
	die "log_file must be specified" unless $config->{log_file};

	# Perform the actual learning from log file
	die "Failed to learn markov\n" unless markov_learn();

	$cmdref->($self, "markov", sub { $self->markov_cmd(@_); });

	return $self;
}

sub markov_learn
{
	open(my $f, "<", $config->{log_file})
		or die ("Cannot open $config->{log_file}: $!\n");

	while (<$f>) {
		chomp;
		utf8::decode($_);
		my @words = split /\s+/, $_;

		# Learning is the same for all but last word
		for (my $i = 0; $i < @words - 1; $i++) {
			my $word = $words[$i];
			my $next_word = $words[$i + 1]; # +1 safe beacuse of loop bounds

			push @{$markov_data{$word}}, $next_word;
		}

		# Now handle special case; last word must be learned as being followed by EOL ("")
		push @{$markov_data{$words[@words - 1]}}, "";
	}

	close($f);
	return 1;
}

sub random_trigger_odds
{
	return int(rand(100)) < $config->{chance};
}

# FIXME factor out with other modules
sub some
{
	my @choices = @_;
	return $choices[rand(@choices)];
}

sub do_markov
{
	my $word = $_[0];
	$word = some(keys %markov_data) unless $word;
	my $message = "";
	my $i = 0;
	do {
		$i++;
		$message .= "$word ";
		$word = some(@{$markov_data{$word}});
	} until(not $word or $word eq "" or $i == 1000);

	return $message;
}

sub markov_cmd
{
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	my $seed = $arguments[0];
	return do_markov($seed);
	return "foo";
}

sub on_message
{
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;

	return "" unless random_trigger_odds();
	return do_markov(some(split " ", $what));
}

sub on_action {
	on_message(@_);
}
1;
