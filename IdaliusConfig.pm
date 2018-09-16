package IdaliusConfig;

use strict;
use warnings;
use Config::Tiny;

use ListParser;

sub check_config
{
	# FIXME to do: check that passed config is sane for core config vars
	my @scalar_configs = (
		'nick',
		'username',
		'ircname',
		'server',
		'port',
		'usessl',
		'sslcert',
		'sslkey',
		'password',
		'must_id',
		'quit_msg',
		'user',
		'group',
		'url_len',
		'prefix_nick',
		'prefix');
	my @list_configs = (
		'channels',
		'ignore',
		'admins',
		'plugins');
	my @optional_configs = (
		'password');

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
				my ($error, @listified) = ListParser::parse_list($config->{$section}->{$opt}, 0);
				die $error if $error;
				$config->{$section}->{$opt} = \@listified;
			} elsif ($c eq "{") {
				my ($error, %hashified) = ListParser::parse_list($config->{$section}->{$opt}, 1);
				die $error if $error;
				$config->{$section}->{$opt} = \%hashified;
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

	return $config;
}
1;
