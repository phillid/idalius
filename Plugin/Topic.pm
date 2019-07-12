package Plugin::Topic;

use strict;
use warnings;

my %channel_topics;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command

	$cmdref->($self, "topic", sub { $self->topic(@_); } );

	return $self;
}

sub topic {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;
	$where = $where->[0] if ref($where) eq "ARRAY";

	# use current channel unless one is specified
	my $channel = @arguments ? $arguments[0] : $where;
	return "Syntax: topic [channel]" unless $channel =~ m/^#.*$/;

	my $topic = $channel_topics{$channel} || "(unknown)";
	return "Topic for $channel: $topic";
}

sub on_topic {
	my ($self, $logger, $who, $where, $topic, $irc) = @_;
	$channel_topics{$where} = $topic;
}

sub on_331_rpl_notopic {
	my ($self, $logger, $where, $irc) = @_;
	delete $channel_topics{$where};
}

sub on_332_rpl_topic {
	my ($self, $logger, $where, $topic, $irc) = @_;
	$channel_topics{$where} = $topic;
}
1;
