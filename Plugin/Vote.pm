package Plugin::Vote;

use strict;
use warnings;

my %has_voted;
my %vote_topic;
my %ayes;
my %noes;

sub configure {
	my $self = shift;
	my $cmdref = shift;

	$cmdref->($self, "vote on", sub { $self->begin(@_); } );
	$cmdref->($self, "vote end", sub { $self->end(@_); } );
	$cmdref->($self, "vote yes", sub { $self->yes(@_); } );
	$cmdref->($self, "vote no", sub { $self->no(@_); } );

	return $self;
}

sub get_channel {
	my ($where) = @_;

	return $where unless ref($where) eq "ARRAY";
	return $where->[0];
}

sub has_voted {
	my ($nick, $channel) = @_;
	return 0 unless $has_voted{$channel};
	return grep {$_ eq $nick} @{$has_voted{$channel}};
}

sub begin {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;
	my $channel = get_channel($where);
	my $nick = (split /!/, $who)[0];

	return "Syntax: vote on <topic/question>" unless $rest;
	return "A vote is currently in progress: $vote_topic{$channel}" if $vote_topic{$channel};

	$ayes{$channel} = $noes{$channel} = 0;
	$vote_topic{$channel} = $rest;
	$has_voted{$channel} = ();
	return "Call to vote (from $nick): $rest. 'vote yes' or 'vote no' to vote";
}

sub end {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;
	my $channel = get_channel($where);

	return "No vote is in progress" unless $vote_topic{$channel};

	my $old_vote_topic = $vote_topic{$channel};
	$vote_topic{$channel} = undef;
	$has_voted{$channel} = ();
	return "The votes are in ($old_vote_topic)! Ayes: $ayes{$channel}. Noes: $noes{$channel}";
}

sub yes {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;
	my $nick = (split /!/, $who)[0];
	my $channel = get_channel($where);

	return "No vote is in progress" unless $vote_topic{$channel};
	return "$nick: You have already voted on this" if has_voted($nick, $channel);

	push @{$has_voted{$channel}}, $nick;
	$ayes{$channel}++;
	return "$nick: Thank you for your vote";
}

sub no {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, @arguments) = @_;
	my $nick = (split /!/, $who)[0];
	my $channel = get_channel($where);

	return "No vote is in progress" unless $vote_topic{$channel};
	return "$nick: You have already voted on this" if has_voted($nick, $channel);

	push @{$has_voted{$channel}}, $nick;
	$noes{$channel}++;
	return "$nick: Thank you for your vote";
}

1;
