package Plugin::URL_Title;

use strict;
use warnings;
use HTTP::Tiny;
use HTML::Parser;
use utf8;

use IdaliusConfig qw/assert_scalar/;

my $config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	$config = shift;

	IdaliusConfig::assert_scalar($config, $self, "url_len");
	die "url_len must be positive" if $config->{url_len} <= 0;

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

sub on_message
{
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;
	my $url;

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

	if (not $response->{headers}->{"content-type"}) {
		$logger->("No content-type in reponse header, not continuing");
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
	$shorturl = (substr $shorturl, 0, $config->{url_len}) . "…" if length ($shorturl) > $config->{url_len};

	my $composed_title = "$title ($shorturl)";
	return $composed_title;
}

sub on_action {
	on_message(@_);
}
1;
