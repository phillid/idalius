package IdaliusConfig;

use strict;
use warnings;
use Config::Tiny;

use ListParser;

sub config_describe {
	my ($plugin, $parm) = @_;

	# Plugin "_" is the root config
	return $parm unless $plugin ne "_";
	return "$plugin -> $parm";
}

sub assert_common {
	my ($config, $plugin, $parm, $human_type, $ref_type) = @_;
	my $ref = $config->{$parm};
	my $name = config_describe($plugin, $parm);

	die "Error: Configuration \"$name\" must be of type $human_type" unless
		defined $ref
		and ref($ref) eq $ref_type;
}

sub assert_scalar {
	my ($config, $plugin, $parm) = @_;
	assert_common($config, $plugin, $parm, "scalar", "");
}

sub assert_list {
	my ($config, $plugin, $parm) = @_;
	assert_common($config, $plugin, $parm, "list", "ARRAY");
}

sub assert_dict {
	my ($config, $plugin, $parm) = @_;
	assert_common($config, $plugin, $parm, "dictionary", "HASH");
}

# Check presence and/or sanity of config parameters for the bot's core
# I.e. it is up to each module to ensure its own config is there and sane,
# normally in sub configure.
sub check_config
{
	my ($config) = @_;

	# Lists of mandatory config variables 
	my @scalars = qw/nick username ircname server port usessl sslcert sslkey user group prefix_nick prefix log_debug/;
	my @lists   = qw/plugins ignore/;

	foreach my $name (@scalars) {
		assert_scalar($config->{_}, "_", $name);
	}

	foreach my $name (@lists) {
		assert_list($config->{_}, "_", $name);
	}

	# Special case: password is optional scalar
	if (defined $config->{_}->{password}) {
		assert_scalar($config->{_}, "_", "password");
	}

}

sub parse_die {
	my ($parsed, $line) = @_;
	my $pad = " " x ($parsed->{column_start} + 1);
	my $underline = "^" x ($parsed->{column_end} - $parsed->{column_start} + 1);

	die "$parsed->{error}:\n$line\n$pad$underline\n";
}

sub parse_config
{
	my $file = $_[0];
	my %built_config;
	my $config = Config::Tiny->read($file);

	foreach my $section (keys %{$config}) {
		foreach my $opt (keys %{$config->{$section}}) {
			# Detect list or hash config option
			my $c = substr $config->{$section}->{$opt}, 0, 1;
			if ($c eq "[") {
				my $parsed = ListParser::parse_list($config->{$section}->{$opt}, 0);
				parse_die($parsed, $config->{$section}->{$opt}) if $parsed->{error};
				$config->{$section}->{$opt} = $parsed->{array};
			} elsif ($c eq "{") {
				my $parsed = ListParser::parse_list($config->{$section}->{$opt}, 1);
				parse_die($parsed, $config->{$section}->{$opt}) if $parsed->{error};
				$config->{$section}->{$opt} = $parsed->{hash};
			}
		}
	}

#	my ($error, @tmp) = ListParser::parse_list($config->{_}->{plugins});
#	$config->{_}->{plugins} = \@tmp;


	# Special case
	$config->{_}->{uid} = getpwnam($config->{_}->{user})
		or die "Cannot get uid of $config->{_}->{user}: $!\n";
	$config->{_}->{gid} = getgrnam($config->{_}->{group})
		or die "Cannot get gid of $config->{_}->{group}: $!\n";

	check_config($config);

	return $config;
}
1;
