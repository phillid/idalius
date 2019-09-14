package Plugin::URL_Title;

use strict;
use warnings;
use HTTP::Tiny;
use HTML::Parser;
use HTML::Entities;
use utf8;
use Encode;

use IdaliusConfig qw/assert_scalar/;

my $config;

sub configure {
	my $self = shift;
	my $cmdref = shift;
	shift; # run_command
	$config = shift;

	IdaliusConfig::assert_scalar($config, $self, "url_len");
	die "url_len must be positive" if $config->{url_len} <= 0;

	$cmdref->($self, "title of", sub { $self->get_title_cmd(@_); });

	return $self;
}

# Globals set by HTML parser, used by get_title
my $title;
my $charset;
my $content_type; # Content-Type header, picked from HTTP or http-equiv

sub start_handler
{
	my $tag = shift;
	my $attr = shift;
	my $self = shift;
	if ($tag eq "title") {
		# Note: NOT dtext. leave entities until after decoding text. See comment below
		$self->handler(text => sub { $title = shift; }, "text");
		$self->handler(end  => sub { shift->eof if shift eq "title"; },
		                    "tagname,self");
	} elsif ($tag eq "meta") {
		if ($attr->{charset}) {
			$charset = $attr->{charset};
		} elsif (   $attr->{"http-equiv"}
			     && lc($attr->{"http-equiv"}) eq "content-type"
			     && $attr->{content}) {
			$content_type = $attr->{"content"};
		}
	}
}

sub get_title
{
	my ($what) = @_;
	my $url;

	# Drawn from RFC 3986§2
	if ($what =~ /(https?:\/\/[a-z0-9\-\._~:\/\?#\[\]@\!\$&'()\*\+,;=%]+)/i) {
		$url = $1;
	}
	return (undef, "No URL found in that string", undef) unless $url;

	# FIXME add more XML-based formats that we can theoretically extract titles from
	# FIXME factor out accepted formats and response match into accepted formats array
	my $http = HTTP::Tiny->new((default_headers => {'Range' => "bytes=0-65536", 'Accept' => 'text/html, image/svg+xml'}, timeout => 3));

	my $response = $http->get($url);

	if (!$response->{success}) {
		if ($response->{status} == 599) {
			chomp $response->{content};
			return (undef, undef, "Error: HTTP client: $response->{content}");
		} else {
			return (undef, undef, "Error: HTTP $response->{status} ($response->{reason})");
		}
	}

	if (not $response->{headers}->{"content-type"}) {
		return (undef, undef, "No content-type in reponse header, not continuing");
	}

	if (!($response->{headers}->{"content-type"} =~ m,(text/html|image/svg\+xml),)) {
		return (undef, undef, "I don't think I can parse titles from $response->{headers}->{'content-type'} - stopping here");
	}

	my $html = $response->{content};

	$title = "";
	my $p = HTML::Parser->new(api_version => 3);
	$p->handler( start => \&start_handler, "tagname,attr,self" );
	$p->parse($html);
	return (undef, undef, "Error parsing HTML: $!") if $!;

	# Pick out charset from the following in order of precedence:
	# 1. <meta charset="…"> (stored in $charset already, if present)
	# 2. <meta http-equiv="Content-Type">
	# 3. Content-Type HTTP header
	# 4. Default to "utf8"
	if (!$charset) {
		$content_type //= $response->{headers}->{"content-type"};
		if ($content_type =~ m/;\s*charset=(\S+)/) {
			$charset = $1;
		} else {
			$charset = "utf8";
		}
	}

	# Decode raw bytes from document's title
	my $dc = Encode::find_encoding($charset);
	return (undef, undef, "Error: Unknown encoding $charset") unless $dc;
	$title = $dc->decode($title);

	# Finally, collapse entities into the characters they represent. Note this
	# must be done instead of pulling dtext from the HTML parser, else you can
	# end up with a bad mix of encodings (see documents with wchars mixed with
	# entities representing more wchars in titles)
	decode_entities($title);

	# Normalise and trim whitespace for tidiness
	$title =~ s/\s+/ /g;
	$title =~ s/(^\s+|\s+$)//g;

	return (undef, undef, "Error: No title") unless $title;

	my $shorturl = $url;
	# remove http(s):// to avoid triggering other poorly configured bots
	$shorturl =~ s,^https?://,,g;
	$shorturl =~ s,/$,,g;

	# truncate URL without http(s):// to configured length if needed
	$shorturl = (substr $shorturl, 0, $config->{url_len}) . "…" if length ($shorturl) > $config->{url_len};

	my $composed_title = "$title ($shorturl)";
	return $composed_title;
}

sub get_title_cmd
{
	my ($self, $irc, $logger, $who, $where, $ided, $rest, $no_reenter, @arguments) = @_;

	my ($title, $warning, $error) = get_title($rest);
	$logger->($error) if $error;

	return $error if $error;
	return $warning if $warning;
	$no_reenter->();
	return $title if $title;

}

sub on_message
{
	my ($self, $logger, $who, $where, $raw_what, $what, $irc) = @_;

	my ($title, $warning, $error) = get_title($what);

	# Log only errors, not warnings
	$logger->($error) if $error;

	return $title if $title;
}

sub on_action {
	on_message(@_);
}
1;
