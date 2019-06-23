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
	private => color("magenta"),
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

# IRC 001
sub on_welcome {
	my ($self, $logger, $server, $message, $irc) = @_;
	$logger->("$t{info}Connected to $t{host}$server$t{info} --- \"$t{message}$message$t{info}\"$t{reset}");
}

# IRC 002
sub on_your_host {
	my ($self, $logger, $message, $irc) = @_;
	$logger->("$t{info} --- \"$t{message}$message$t{info}\"$t{reset}");
}

# IRC 003
sub on_created {
	my ($self, $logger, $message, $irc) = @_;
	$logger->("$t{info} --- \"$t{message}$message$t{info}\"$t{reset}");
}

# IRC 004
sub on_my_info {
	my ($self, $logger, $message, $irc) = @_;
	$logger->("$t{info} --- \"$t{message}$message$t{info}\"$t{reset}");
}

# IRC 251
sub on_251_user_client {
	my ($self, $logger, $message, $irc) = @_;
	$logger->("$t{info}Online: \"$t{message}$message$t{info}\"$t{reset}");
}

# IRC 252
sub on_252_user_op {
	my ($self, $logger, $count, $message, $irc) = @_;
	$logger->("$t{info}Online: \"$t{message}$count $message$t{info}\"$t{reset}");
}

# IRC 253
sub on_253_user_unknown {
	my ($self, $logger, $count, $message, $irc) = @_;
	$logger->("$t{info}Online: \"$t{message}$count $message$t{info}\"$t{reset}");
}

# IRC 254
sub on_254_user_channels {
	my ($self, $logger, $count, $message, $irc) = @_;
	$logger->("$t{info}Online: \"$t{message}$count $message$t{info}\"$t{reset}");
}

# IRC 255
sub on_255_user_me {
	my ($self, $logger, $message, $irc) = @_;
	$logger->("$t{info}Online: \"$t{message}$message$t{info}\"$t{reset}");
}


sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	$logger->("$t{bracket}\[$t{channel}$where->[0]$t{bracket}\] $t{nick}$who: $t{message}$what$t{reset}");
	return;
}

sub on_privmsg {
	my ($self, $logger, $who, $to, $raw_what, $what, $irc) = @_;
	$logger->("$t{bracket}\[$t{channel}private$t{bracket}\] $t{nick}$who$t{bracket}: $t{private}$what$t{reset}");
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
	return;
}

sub on_motd_content {
	my ($self, $logger, $server, $motd, $irc) = @_;
	$logger->("$t{info}MOTD: $t{message}$motd$t{reset}");
	return;
}

sub on_motd_begin {
	my ($self, $logger, $server, $message, $irc) = @_;
	$logger->("$t{info}$message$t{reset}");
	return;
}

sub on_motd_end {
	my ($self, $logger, $server, $message, $irc) = @_;
	$logger->("$t{info}$message$t{reset}");
	return;
}

1;
