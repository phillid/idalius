#!/usr/bin/env perl

package sb_config;

use strict;
use warnings;
use Config::Tiny;

sub parse_config
{
	my @scalar_configs = ('nick', 'username', 'ircname', 'server', 'port', 'usessl', 'password', 'must_id', 'quit_msg', 'user', 'group');
	my @list_configs = ('channels', 'ignore', 'admins');
	my $file = $_[0];
	my %built_config;
	my $config = Config::Tiny->read($file);

	# FIXME catch undefined/missing config options
	foreach my $option (@scalar_configs) {
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

	$built_config{uid} = getpwnam($built_config{user})
		or die "Cannot get uid of $built_config{user}: $!\n";
	$built_config{gid} = getgrnam($built_config{group})
		or die "Cannot get gid of $built_config{group}: $!\n";


	$built_config{triggers} = \%triggers;

	return %built_config;
}
1;
