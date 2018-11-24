package Plugin::Natural;

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

	IdaliusConfig::assert_scalar($config, $self, "chance_mentioned");
	IdaliusConfig::assert_scalar($config, $self, "chance_otherwise");
	die "chance_mentioned must be from 0 to 100"
		if ($config->{chance_mentioned} < 0 || $config->{chance_mentioned} > 100);
	die "chance_otherwise must be from 0 to 100"
		if ($config->{chance_otherwise} < 0 || $config->{chance_otherwise} > 100);

	return $self;
}

sub mention_odds {
	return int(rand(100)) < $config->{chance_mentioned};
}

sub normal_odds {
	return int(rand(100)) < $config->{chance_otherwise};
}

# FIXME factor out with other modules
sub some {
	my @choices = @_;
	return $choices[rand(@choices)];
}

sub choose_mention_response {
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

sub choose_normal_response {
	my ($what, $nick) = @_;

	if ($what =~ /\b(hi|hey|sup|morning|hello|hiya)\b/i) {
		return some("hi", "hello", "hellooooo", "hey") . some("", ", how are ya");
	} elsif ($what =~ /\boof\b/i) {
		return "ouch";
	} elsif ($what =~ /\bouch\b/i) {
		return some("owie", ":(");
	} elsif ($what =~ /(\b(ow|owie|yow|yowie|ouchie)\b|(:\(|:'\())/i) {
		return some("oh no!", "*hugs $nick", "*bakes a cake for $nick");
	} elsif ($what =~ /^\b(lol\b|kek\b|lel\b|lolol|haha|hehe|jaja)$/i) {
		return some(":)", ":D", "hehe");
	} elsif ($what =~ /\b(:o)\b/i) {
		return some("?", "ö", ":O", "!!");
	} elsif ($what =~ /^help\b/i) {
		return some("D:", "ono", "*throws a lifeline to $nick");
	} elsif ($what =~ /(:D|:\)|D:|:\||:\\|:C|:S)/) {
		return some(":D", ":)", "D:", ":|", ":/", ":\\", ":S", ">:D", ">:(", ">>>:CCCC");
	} elsif ($what eq "o/") {
		return "\\o";
	} elsif ($what eq "\\o") {
		return "o/";
	}
	return;
}

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	my $nick = (split /!/, $who)[0];

	if (ref($where) eq "ARRAY") {
		$where = $where->[0];
	}

	my $response;
	if ($what =~ /\b\Q$irc->nick_name()\E\b/) {
		return unless mention_odds();
		$response = choose_mention_response($what, $nick);
	} else {
		return unless normal_odds();
		$response = choose_normal_response($what, $nick);
	}

	return unless $response;

	if (my ($rest) = ($response =~ m/^\*(.*)$/)) {
		$irc->delay([ctcp => $where => "ACTION $rest"], 1+rand(9));
	} else {
		$irc->delay([privmsg => $where => $response], 1+rand(9));
	}

	return;
}

sub on_action {
	on_message @_;
}
1;
