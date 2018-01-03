#!/usr/bin/env perl

package plugin::url_title;

use strict;
use warnings;
use HTTP::Tiny;
use HTML::HeadParser;

my %config;

sub configure {
	my $self = $_[0];
	my $cref = $_[1];
	%config = %$cref;
	return $self;
}

sub message
{
	my ($self, $logger, $me, $who, $where, $raw_what, $what, $irc) = @_;
	my $url;

	return if ($config{url_on} == 0);

	if ($what =~ /(https?:\/\/[^ ]+)/i) {
		$url = $1;
	}
	return unless $url;

	my $http = HTTP::Tiny->new((default_headers => {'Range' => "bytes=0-65536", 'Accept' => 'text/html'}, timeout => 3));

	my $response = $http->get($url);

	if (!$response->{success}) {
		$logger->("Something broke: $response->{reason}");
		return;
	}

	if (!($response->{headers}->{"content-type"} =~ m,text/html ?,)) {
		$logger->("Not html, giving up now");
		return;
	}

	my $html = $response->{content};

	my $parser = HTML::HeadParser->new;
	$parser->parse($html);

	# get title and unpack from utf8 (assumption)
	my $title = $parser->header("title");
	return unless $title;

	my $shorturl = $url;
	$shorturl = (substr $url, 0, $config{url_len}) . "…" if length ($url) > $config{url_len};

	# remove http(s):// to avoid triggering other poorly configured bots
	$shorturl =~ s,^https?://,,g;
	$shorturl =~ s,/$,,g;

	my $composed_title = "$title ($shorturl)";
	return $composed_title;
}
1;
