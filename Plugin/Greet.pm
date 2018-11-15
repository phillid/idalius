package Plugin::Greet;

use strict;
use warnings;

my $root_config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	shift; # module config
	$root_config = shift;

	return $self;
}

sub some {
	my @choices = @_;
	return $choices[rand(@choices)];
}

my @own_responses = (
	"It's me! I was the turkey all along!",
	"Meeeeeee!",
	"Hello, fellow humans",
	"Hello",
	"Hi",
	"Morning all",
	"Greetings, fellow earthlings",
	"I'm back, baby!",
	"I only came back to grab my keys",
	"Has anyone seen my keys?",
	"Anyone wanna listen to my podcast?"
);

sub on_join {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $nick = (split /!/, $who)[0];
	if ($nick eq $root_config->{current_nick}) {
		return some @own_responses;
	} else {
		return some(
			"hi $nick",
			"oh look, $nick is here",
			"look who came crawling back",
			"look at what the cat dragged in",
			"$nick!!!!! guys!!!!!! $nick is here !!!!!!!!",
			"weclome $nick",
			"Welcome to $where->[0], $nick. Leave your sanity at the door",
			"I feel sick");
	}
}
1;
