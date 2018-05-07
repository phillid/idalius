#!/usr/bin/env perl

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
	utf8::decode($html);

	$title = "";
	my $p = HTML::Parser->new(api_version => 3);
	$p->handler( start => \&start_handler, "tagname,self");
	$p->parse($html);
	die "Error: $!\n" if $!;

	utf8::upgrade($title);
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
