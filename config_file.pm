#!/usr/bin/env perl

package config_file;

use strict;
use warnings;
use Config::Tiny;

sub parse_config
{
	my @scalar_configs = (
		'nick',
		'username',
		'ircname',
		'server',
		'port',
		'usessl',
		'password',
		'must_id',
		'quit_msg',
		'user',
		'group',
		'url_on',
		'url_len',
		'antiflood_on');
	my @list_configs = (
		'channels',
		'ignore',
		'admins');
	my @optional_configs = (
		'password');
	my $file = $_[0];
	my %built_config;
	my $config = Config::Tiny->read($file);

	# FIXME catch undefined/missing config options
	foreach my $option (@scalar_configs) {
		my $value = $config->{_}->{$option};
		if (! defined $value && ! grep {$_ eq $option} @optional_configs) {
			die "Option \"$option\" must be set in $file\n";
		}
		$built_config{$option} = $config->{_}->{$option};
	}

	foreach my $option (@list_configs) {
		my $vals = $config->{_}->{$option};
		$vals =~ s/^\s+|\s+$//g;
		@built_config{$option} = [split /\s*,\s*/, $vals];
	}

	# special case: triggers hash
	my %triggers;
	foreach (split ',', $config->{_}->{triggers}) {
		my ($match, $response) = split /=>/;
		# strip outer quotes
		$match =~ s/^[^']*'|'[^']*$//g;
		$response =~ s/^[^']*'|'[^']*$//g;
		$triggers{$match} = $response;
	}

	# special case: timezones hash
	my %timezone;
	foreach (split ',', $config->{_}->{timezone}) {
		my ($who, $tz) = split /=>/;
		# strip outer quotes
		$who =~ s/^[^']*'|'[^']*$//g;
		$tz =~ s/^[^']*'|'[^']*$//g;
		$timezone{$who} = $tz;
	}

	$built_config{uid} = getpwnam($built_config{user})
		or die "Cannot get uid of $built_config{user}: $!\n";
	$built_config{gid} = getgrnam($built_config{group})
		or die "Cannot get gid of $built_config{group}: $!\n";


	$built_config{triggers} = \%triggers;
	$built_config{timezone} = \%timezone;

	return %built_config;
}
1;
