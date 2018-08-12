package Plugin::URL_Title;

use strict;
use warnings;
use HTTP::Tiny;
use HTML::Parser;
use utf8;

my %config;

sub configure {
	my $self = $_[0];
	my $cmdref = $_[1];
	my $cref = $_[2];
	%config = %$cref;
	return $self;
}

my $title;

sub start_handler
{
	return if shift ne "title";
	my $self = shift;
	$self->handler(text => sub { $title = shift; }, "dtext");
	$self->handler(end  => sub { shift->eof if shift eq "title"; },
	                    "tagname,self");
}

sub message
{
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $url;

	return if ($config{url_on} == 0);

	# Drawn from RFC 3986§2
	if ($what =~ /(https?:\/\/[a-z0-9\-\._~:\/\?#\[\]@\!\$&'()\*\+,;=%]+)/i) {
		$url = $1;
	}
	return unless $url;

	# FIXME add more XML-based formats that we can theoretically extract titles from
	# FIXME factor out accepted formats and response match into accepted formats array
	my $http = HTTP::Tiny->new((default_headers => {'Range' => "bytes=0-65536", 'Accept' => 'text/html, image/svg+xml'}, timeout => 3));

	my $response = $http->get($url);

	if (!$response->{success}) {
		$logger->("Something broke: $response->{reason}");
		return;
	}

	if (!($response->{headers}->{"content-type"} =~ m,(text/html|image/svg\+xml),)) {
		$logger->("I don't think I can parse titles from $response->{headers}->{'content-type'} - stopping here");
		return;
	}

	my $html = $response->{content};
	utf8::decode($html);

	$title = "";
	my $p = HTML::Parser->new(api_version => 3);
	$p->handler( start => \&start_handler, "tagname,self");
	$p->parse($html);
	die "Error: $!\n" if $!;

	$title =~ s/\s+/ /g;
	$title =~ s/(^\s+|\s+$)//g;

	utf8::upgrade($title);
	return unless $title;

	my $shorturl = $url;
	# remove http(s):// to avoid triggering other poorly configured bots
	$shorturl =~ s,^https?://,,g;
	$shorturl =~ s,/$,,g;

	# truncate URL without http(s):// to configured length if needed
	$shorturl = (substr $shorturl, 0, $config{url_len}) . "…" if length ($shorturl) > $config{url_len};

	my $composed_title = "$title ($shorturl)";
	return $composed_title;
}
1;
