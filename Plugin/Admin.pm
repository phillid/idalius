package Plugin::Admin;

use strict;
use warnings;

use IdaliusConfig qw/assert_scalar assert_list/;
use Plugin qw/load_plugin unload_plugin/;

my $config;
my $root_config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	$config = shift;
	$root_config = shift;

	IdaliusConfig::assert_list($config, $self, "admins");
	IdaliusConfig::assert_scalar($config, $self, "must_id");
	IdaliusConfig::assert_scalar($config, $self, "quit_msg");

	$cmdref->($self, "say", sub { $self->say(@_); } );
	$cmdref->($self, "action", sub { $self->do_action(@_); } );

	$cmdref->($self, "nick", sub { $self->nick(@_); } );
	$cmdref->($self, "join", sub { $self->join_channel(@_); } );
	$cmdref->($self, "part", sub { $self->part(@_); } );
	$cmdref->($self, "mode", sub { $self->mode(@_); } );
	$cmdref->($self, "kick", sub { $self->kick(@_); } );
	$cmdref->($self, "topic", sub { $self->topic(@_); } );
	$cmdref->($self, "reconnect", sub { $self->reconnect(@_); } );

	$cmdref->($self, "ignore", sub { $self->ignore(@_); } );
	$cmdref->($self, "don't ignore", sub { $self->do_not_ignore(@_); } );
	$cmdref->($self, "who are you ignoring?", sub { $self->dump_ignore(@_); } );
	$cmdref->($self, "prefix rm", sub { $self->prefix_rm(@_); } );
	$cmdref->($self, "prefix del", sub { $self->prefix_rm(@_); } );
	$cmdref->($self, "prefix set", sub { $self->prefix_set(@_); } );

	$cmdref->($self, "exit", sub { $self->exit(@_); } );

	$cmdref->($self, "plugins", sub { $self->dump_plugins(@_); } );
	$cmdref->($self, "load", sub { $self->load_plugin(@_); } );
	$cmdref->($self, "unload", sub { $self->unload_plugin(@_); } );

	return $self;
}

sub is_channel {
	return $_[0] =~ m/^#+/;
}

sub is_admin {
	my ($logger, $who, $ided) = @_;
	if ($config->{must_id} and not $ided) {
		$logger->("$who hasn't identified, but tried to use a command");
		return 0;
	}
	my $is_admin = grep {$_ eq $who} @{$config->{admins}};
	if (!$is_admin) {
		$logger->("$who isn't an admin, but tried to use a command");
	}
	return $is_admin;
}

sub nick {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: nick <new nick>" unless @arguments == 1;

	$irc->yield(nick => $arguments[0]);
}

sub say {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: say <channel> <msg>" unless @arguments >= 2;

	# Strip nick/channel from message
	$rest =~ s/^(.*?\s)//;

	$irc->yield(privmsg => $arguments[0] => $rest);
}

sub do_action {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: action <channel> <action text>" unless @arguments >= 2;

	# Strip nick/channel from message
	$rest =~ s/^(.*?\s)//;

	$irc->yield(ctcp => $arguments[0] => "ACTION $rest");
}

sub join_channel {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: join <channel1> [channel2 ...]" unless @arguments >= 1;

	$irc->yield(join => $_) for @arguments;
}

sub part {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	$where = $where->[0] if ref($where) eq "ARRAY";

	return unless is_admin($logger, $who, $ided);
	return "Syntax: part <channel1> [channel2 ...] [partmsg]" unless
		is_channel($where) or
		(@arguments >= 1 and is_channel($arguments[0]));

	if ((@arguments == 0 and is_channel($where)) or @arguments >= 1 and not is_channel($arguments[0])) {
		$rest = "$where $rest";
	}

	my $nick = (split /!/, $who)[0];
	my ($chan_str, $reason) = split /\s+(?!#)/, $rest, 2;
	my @channels = split /\s+/, $chan_str;
	$reason = "Commanded by $nick" unless $reason;
	$irc->yield(part => @channels => $reason);
}

sub mode {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	$where = $where->[0] if ref($where) eq "ARRAY";

	return unless is_admin($logger, $who, $ided);
	return "Syntax: mode <everything>" unless @arguments > 0;

	if (not is_channel($arguments[0]) and is_channel($where)) {
		$rest = "$where $rest";
	}

	$irc->yield(mode => $rest);
}

sub kick {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	$where = $where->[0] if ref($where) eq "ARRAY";

	return unless is_admin($logger, $who, $ided);
	return "Syntax: kick <channel> <nick> [reason]" unless
		@arguments >= 2 and is_channel($arguments[0])
		or @arguments >= 1 and is_channel($where);

	if (is_channel($where) and not is_channel($arguments[0])) {
		$rest = "$where $rest";
	}

	my ($channel, $kickee, undef, $reason) = $rest =~ /^(\S+)\s(\S+)((?:\s)(.*))?$/;
	if ($channel and $kickee) {
		my $nick = (split /!/, $who)[0];
		$reason = "Requested by $nick" unless $reason;
		$irc->yield(kick => $channel => $kickee => $reason);
	}
}

sub topic {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: topic <new topic>" unless @arguments >= 2;

	# Strip nick/channel from message
	$rest =~ s/^(.*?\s)//;

	# FIXME use $where if it's a channel
	$irc->yield(topic => $arguments[0] => $rest);
}

sub reconnect {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);

	my $reason = $rest;
	$reason = $config->{quit_msg} unless $reason;

	$irc->yield(quit => $reason);
}

sub ignore {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: ignore <nick>" unless @arguments == 1;

	push @{$root_config->{ignore}}, $arguments[0];

	return "Ignoring $arguments[0]";
}

sub do_not_ignore {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: don't ignore <nick>" unless @arguments == 1;

	my $target = $arguments[0];

	if (grep { $_ eq $target} @{$root_config->{ignore}}) {
		@{$root_config->{ignore}} = grep { $_ ne $target } @{$root_config->{ignore}};
		return "No longer ignoring $target.";
	} else {
		return "I wasn't ignoring $target anyway.";
	}
}

sub dump_ignore {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return "Syntax: who are you ignoring?" unless @arguments == 0;

	return "I am ignoring nobody" unless @{$root_config->{ignore}};
	return "I am ignoring: " . join ", ", @{$root_config->{ignore}};
}

sub prefix_rm {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);

	return "Syntax: prefix rm" unless @arguments == 0;

	my $old = $root_config->{prefix};
	$root_config->{prefix} = undef;

	return "Prefix removed (used to be $old)" if $old;
	return "Prefix was already removed";
}

sub prefix_set {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);

	return "Syntax: prefix set <new prefix>" unless @arguments > 0;

	$root_config->{prefix} = $rest;
	return "Prefix set to $root_config->{prefix}";
}

sub exit {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: exit" unless @arguments == 0;

	exit;
}

sub dump_plugins {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;
	return "Active plugins: " . join ", ", @{$root_config->{active_plugins}};
}

sub unload_plugin {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: unload <plugin>" unless @arguments == 1;

	my $module = $arguments[0];

	my $error = Plugin::unload_plugin($logger, $root_config, $module);
	return $error if $error;
	return "$module unloaded";
}

sub load_plugin {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	return unless is_admin($logger, $who, $ided);
	return "Syntax: load <plugin>" unless @arguments == 1;

	my $module = $arguments[0];

	my $error = Plugin::load_plugin($logger, $root_config, $module);
	return $error if $error;
	return "$module loaded";
}

1;
