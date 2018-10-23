package Plugin::Natural;

use strict;
use warnings;
use threads;

my $root_config;

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	shift; # module config
	$root_config = shift;

	return $self;
}

sub mention_odds {
	return int(rand(2)) == 1;
}

sub some {
	my @choices = @_;
	return $choices[rand(@choices)];
}

sub choose_response {
	my ($what, $nick) = @_;

	if ($what =~ /\b(hi|hey|sup|morning|hello|hiya)\b/i) {
		return some("hi $nick", "hey $nick", "sup $nick") . some("", ", how goes it?");
	} elsif ($what =~ /\b(thanks|thx|ta)\b/i) {
		return some("don't mention it", "that's ok", ":)", "not a problem");
	} elsif ($what =~ /\b(shush|(shit|shut)(\s+the\s+fuck|)\s+up|stfu)\b/i) {
		return some("$nick: shush yourself", "shut up, $nick", "nou $nick", "sorry $nick", ":(");
	} elsif ($what =~ /\b(fuck\s+(off?|you|u)|fucking)\b/i) {
		return some("$nick: take your meds", "stop harassing me", "ease up on the drink, mate", "ooh big boy angry $nick has come out to play");
	} elsif ($what =~ /\b(lol|g(g|j))\b/i) {
		return some(":)", ":D");
	} elsif ($what =~ /\bstop(|\s+it)\b/i) {
		return some(":(", "fine", "whatever, dude", "god");
	} elsif ($what =~ /\bhelp\b/i) {
		return some("D:", "ono");
	}
	return;
}

sub on_message {
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $nick = (split /!/, $who)[0];

	if (ref($where) eq "ARRAY") {
		$where = $where->[0];
	}

	return unless $what =~ /\b\Q$root_config->{current_nick}\E\b/;
	return unless mention_odds();

	my $response = choose_response($what, $nick);
	$irc->delay([privmsg => $where => $response], rand(10)) if $response;

	return;
}

sub on_action {
	on_message @_;
}
1;
