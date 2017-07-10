#!/usr/bin/env perl

package plugin::url_title;

use strict;
use warnings;
use HTTP::Tiny;
use HTML::HeadParser;
use IRC::Utils qw(strip_color strip_formatting);

my %config;

sub configure {
	my $self = $_[0];
	my $cref = $_[1];
	%config = %$cref;
	return $self;
}

sub message
{
	my ($self, $me, $who, $where, $what) = @_;
	my $url;

	$what = strip_color(strip_formatting($what));

	if ($what =~ /(https?:\/\/[^ ]+)/i) {
		$url = $1;
	}
	return unless $url;

	my $http = HTTP::Tiny->new((default_headers => {'Range' => "bytes=0-65536", 'Accept' => 'text/html'}, timeout => 3));

	my $response = $http->get($url);

	if (!$response->{success}) {
		print "Something broke: $response->{reason}\n";
		return;
	}

	if (!($response->{headers}->{"content-type"} =~ m,text/html ?,)) {
		print("Not html, giving up now\n");
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
