package Plugin::Greet;

# FIXME add configurable messages

use strict;
use warnings;

my $config;
my $root_config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	$config = shift;
	$root_config = shift;

	IdaliusConfig::assert_scalar($config, $self, "chance_self");
	IdaliusConfig::assert_scalar($config, $self, "chance_other");
	die "chance_self must be from 0 to 100"
		if ($config->{chance_self} < 0 || $config->{chance_self} > 100);
	die "chance_other must be from 0 to 100"
		if ($config->{chance_other} < 0 || $config->{chance_other} > 100);

	return $self;
}

sub self_odds {
	return int(rand(100)) < $config->{chance_self};
}

sub other_odds {
	return int(rand(100)) < $config->{chance_other};
}

# FIXME factor out `some` with other plugins
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
	my ($self, $logger, $who, $where, $irc) = @_;
	my $nick = (split /!/, $who)[0];
	my $response;
	if ($nick eq $irc->nick_name()) {
		return unless self_odds();
		$response = some @own_responses;
	} else {
		return unless other_odds();
		$response = some(
			"hi $nick",
			"oh look, $nick is here",
			"look who came crawling back",
			"look at what the cat dragged in",
			"$nick!!!!! guys!!!!!! $nick is here !!!!!!!!",
			"weclome $nick",
			"Welcome to $where, $nick. Leave your sanity at the door",
			"I feel sick");
	}
	$irc->delay([privmsg => $where => $response], 1+rand(5));
	return;
}
1;
