package Plugin::Admin;

use strict;
use warnings;

my %config;

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	my $cref = $_[2];
	%config = %$cref;

	$cmdref->("say", sub { $self->say(@_); } );
	$cmdref->("action", sub { $self->do_action(@_); } );

	$cmdref->("nick", sub { $self->nick(@_); } );
	$cmdref->("join", sub { $self->join_channel(@_); } );
	$cmdref->("part", sub { $self->part(@_); } );
	$cmdref->("mode", sub { $self->mode(@_); } );
	$cmdref->("kick", sub { $self->kick(@_); } );
	$cmdref->("topic", sub { $self->topic(@_); } );
	$cmdref->("reconnect", sub { $self->reconnect(@_); } );

	$cmdref->("ignore", sub { $self->ignore(@_); } );
	$cmdref->("don't ignore", sub { $self->do_not_ignore(@_); } );
	$cmdref->("who are you ignoring?", sub { $self->dump_ignore(@_); } );
	$cmdref->("exit", sub { $self->exit(@_); } );

	return $self;
}

sub is_admin {
	my $who = shift;
	my $is_admin = grep {$_ eq $who} @{$config{admins}};
	if (!$is_admin) {
		# Uhh log this rather than print
		print "$who isn't an admin, but tried to use a command";
	}
	return $is_admin;
}

sub nick {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: nick <new nick>" unless @arguments == 1;

	$irc->yield(nick => $arguments[0]);
}

sub say {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: say <channel> <msg>" unless @arguments >= 2;

	# Strip nick/channel from message
	$rest =~ s/^(.*?\s)//;

	$irc->yield(privmsg => $arguments[0] => $rest);
}

sub do_action {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: action <channel> <action text>" unless @arguments >= 2;

	# Strip nick/channel from message
	$rest =~ s/^(.*?\s)//;

	$irc->yield(ctcp => $arguments[0] => "ACTION $rest");
}

sub join_channel {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: join <channel1> [channel2 ...]" unless @arguments >= 1;

	$irc->yield(join => $_) for @arguments;
}

sub part {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: part <channel1> [channel2 ...] [partmsg]" unless @arguments >= 1;

	my $nick = (split /!/, $who)[0];
	my ($chan_str, $reason) = split /\s+(?!#)/, $rest, 2;
	my @channels = split /\s+/, $chan_str;
	$reason = "Commanded by $nick" unless $reason;
	$irc->yield(part => @channels => $reason);
}

sub mode {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: mode <everything>" unless @arguments > 0;

	# FIXME should use $where if it's a channel (?)
	$irc->yield(mode => $rest);
}

sub kick {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: kick <channel> <nick> [reason]" unless @arguments >= 2;

	# FIXME should use $where if it's a channel (?)
	my ($channel, $kickee, undef, $reason) = $rest =~ /^(\S+)\s(\S+)((?:\s)(.*))?$/;
	if ($channel and $kickee) {
		my $nick = (split /!/, $who)[0];
		$reason = "Requested by $nick" unless $reason;
		$irc->yield(kick => $channel => $kickee => $reason);
	}
}

sub topic {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: topic <new topic>" unless @arguments >= 2;

	# Strip nick/channel from message
	$rest =~ s/^(.*?\s)//;

	# FIXME use $where if it's a channel
	$irc->yield(topic => $arguments[0] => $rest);
}

sub reconnect {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);

	my $reason = $rest;
	$irc->yield(quit => $reason);
}

sub ignore {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: ignore <nick>" unless @arguments == 1;

	push @{$config{ignore}}, $arguments[0];

	return "Ignoring $arguments[0]";
}

sub do_not_ignore {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return unless is_admin($who);
	return "Syntax: don't ignore <nick>" unless @arguments == 1;

	my $target = $arguments[0];

	if (grep { $_ eq $target} @{$config{ignore}}) {
		@{$config{ignore}} = grep { $_ ne $target } @{$config{ignore}};
		return "No longer ignoring $target.";
	} else {
		return "I wasn't ignoring $target anyway.";
	}
}

sub dump_ignore {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return "Syntax: who are you ignoring?" unless @arguments == 0;

	# FIXME special case for empty ignore
	return "I am ignoring: " . join ", ", @{$config{ignore}};
}

sub exit {
	my ($self, $irc, $logger, $who, $where, $rest, @arguments) = @_;

	return "Syntax: exit" unless @arguments == 0;

	exit;
}

1;
