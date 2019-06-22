package Plugin::Log;

use strict;
use warnings;

use Term::ANSIColor;

my $config;
my $root_config;

# FIXME turn theme into config parms?
my %t = (
	bracket => color("white"),
	nick => color("cyan"),
	info => color("yellow"),
	kick => color("red"),
	host => color("magenta"),
	channel => color("blue"),
	message => color("reset"),
	misc => color("bright_black"),
	reset => color("reset")
);

sub configure {
	my $self = shift;
	shift; # cmdref
	shift; # run_command
	$config = shift;
	$root_config = shift;

	return $self;
}

# FIXME Not triggered yet
sub on_001 {
	my ($self, $logger, $server, $message, $irc) = @_;
	$logger->("$t{info}Connected to $t{host}$server$t{info} --- \"$t{message}$message$t{info}\"$t{reset}");
}

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	$logger->("$t{bracket}\[$t{channel}$where->[0]$t{bracket}\] $t{nick}$who: $t{message}$what$t{reset}");
	return;
}

sub on_action {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	$logger->("$t{bracket}\[$t{channel}$where->[0]$t{bracket}\] $t{message}* $t{nick}$who $t{message}$raw_what$t{reset}");
	return;
}

sub on_part {
	my ($self, $logger, $who, $where, $why, $irc) = @_;
	$logger->("$t{bracket}\[$t{channel}$where$t{bracket}\]$t{info} --- $t{nick}$who $t{info}left ($why)$t{reset}");
	return;
}

sub on_join {
	my ($self, $logger, $who, $where, $irc) = @_;
	$logger->("$t{bracket}\[$t{channel}$where$t{bracket}\]$t{info} --- $t{nick}$who $t{info}joined$t{reset}");
	return;
}

sub on_kick {
	my ($self, $logger, $kicker, $where, $kickee, $why, $irc) = @_;
	$logger->("$t{bracket}\[$t{channel}$where$t{bracket}\]$t{kick} !!! $t{nick}$kicker $t{kick}kicked $t{nick}$kickee $t{kick}($why)$t{reset}");
	return;
}

sub on_nick {
	my ($self, $logger, $who, $new_nick, $irc) = @_;
	$logger->("$t{nick}$who $t{info}changed nick to $t{nick}$new_nick$t{reset}");
	return;
}

sub on_invite {
	my ($self, $logger, $who, $where, $irc) = @_;
	$logger->("$t{nick}$who $t{info}invited me to join $t{channel}$where$t{reset}");
	return;
}

sub on_topic {
	my ($self, $logger, $who, $where, $topic, $irc) = @_;
	if ($topic) {
		$logger->("$t{bracket}\[$t{channel}$where$t{bracket}\]$t{info} --- $t{nick}$who $t{info}set topic to $t{message}$topic$t{reset}");
	} else {
		$logger->("$t{bracket}\[$t{channel}$where$t{bracket}\]$t{info} --- $t{nick}$who $t{info}unset the topic$t{reset}");
	}
	return;
}

sub on_ping {
	my ($self, $logger, $server, $irc) = @_;
	$logger->("$t{misc}IRC ping from $server$t{reset}");
}
1;
