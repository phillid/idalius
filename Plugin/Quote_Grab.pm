package Plugin::Quote_Grab;

use strict;
use warnings;

use DBI qw/:sql_types/;

my $config;
my $db;

# Last message said on a channel, by a person e.g $last["#chan"]["person"]
my %last;

my $insert_quote;
my $random_quote;
my $random_quote_person;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	$config = shift;

	IdaliusConfig::assert_scalar($config, $self, "database");

	$cmdref->($self, "grab", sub { $self->grab(@_); } );
	$cmdref->($self, "rq", sub { $self->random_quote(@_); } );

	$db = DBI->connect("dbi:SQLite:dbname=$config->{database}", undef, undef);

	my $create_table = $db->prepare(
		"CREATE TABLE IF NOT EXISTS quotes(time, grabber, grabee, channel, text);"
	);
	$create_table->execute();

	# Prepare prepared statements
	$insert_quote = $db->prepare(
		"INSERT INTO quotes(time, grabber, grabee, channel, text) VALUES(strftime('%s', 'now'), ?, ?, ?, ?);"
	);
	$random_quote = $db->prepare(
		"SELECT text FROM quotes ORDER BY RANDOM() LIMIT ?"
	);
	$random_quote_person = $db->prepare(
		"SELECT text FROM quotes WHERE (grabee = ?) ORDER BY RANDOM() LIMIT ?"
	);

	return $self;
}

sub grab {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	if (ref($where) eq "ARRAY") {
		$where = $where->[0];
	}

	return "This command must be issued in a channel" unless $where =~ m/^#/;

	my $grabee = shift @arguments;
	return "No message to grab" unless exists($last{$where}{$grabee});

	my $grabber = (split /!/, $who)[0];
	my $grab_text = $last{$where}{$grabee};

	$insert_quote->bind_param(1, $grabber, SQL_VARCHAR);
	$insert_quote->bind_param(2, $grabee, SQL_VARCHAR);
	$insert_quote->bind_param(3, $where, SQL_VARCHAR);
	$insert_quote->bind_param(4, $grab_text, SQL_VARCHAR);
	$insert_quote->execute();

	return "yeet👌👌💯";
}

sub random_quote {
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	my $q;
	my $grabee = shift @arguments;

	if ($grabee) {
		$q = $random_quote_person;
		$q->bind_param(1, $grabee, SQL_VARCHAR);
		$q->bind_param(2, 1, SQL_INTEGER); # LIMIT 1
	} else {
		$q = $random_quote;
		$q->bind_param(1, 1, SQL_INTEGER); # LIMIT 1
	}
	$q->execute();
	my ($quote) = $q->fetchrow();

	return "No quotes match" unless $quote;
	return $quote;
}

sub on_message {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;

	if (ref($where) eq "ARRAY") {
		$where = $where->[0];
	}

	return unless $where =~ m/^#/;

	$who = (split /!/, $who)[0];
	$last{$where}{$who} = "<$who> $what";

	return;
}

sub on_action {
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;

	if (ref($where) eq "ARRAY") {
		$where = $where->[0];
	}

	return unless $where =~ m/^#/;

	$who = (split /!/, $who)[0];
	$last{$where}{$who} = "* $who $what";

	return;
}
1
