package Plugin::Timezone;

use strict;
use warnings;

use DateTime;
use IdaliusConfig qw/assert_dict/;

my $config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	$config = shift;

	IdaliusConfig::assert_dict($config, $self, "timezone");

	$cmdref->($self, "time", sub { $self->time(@_); } );

	return $self;
}

sub time {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	my $requester = (split /!/, $who)[0];
	my @known_zones = (keys %{$config->{timezone}});

	return "Syntax: time [nick]" unless @arguments <= 1;

	my $nick = $arguments[0] || $requester;

	my ($case_nick) = grep {/^$nick$/i} @known_zones;
	my $tz;
	if ($case_nick) {
		$tz = $config->{timezone}->{$case_nick};
	} else {
		$tz = $nick;
	}

	eval {
		my $d = DateTime->now();
		$d->set_time_zone($tz);
		my $timestr = $d->strftime("%H:%M on %a %d %b, %Y (%Z)");
		return "$nick\'s clock reads $timestr" if $case_nick;
		return "Clocks in $tz read $timestr";
	} or do {
		return "$requester: I'm unsure what the time is for $nick";
	}
}
1;
