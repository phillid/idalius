#!/usr/bin/env perl

package sb_config;

use strict;
use warnings;
use Config::Tiny;

sub parse_config
{
	my @scalar_configs = ('nick', 'username', 'ircname', 'server', 'port', 'password', 'must_id');
	my @list_configs = ('channels', 'ignore', 'admins', 're', 'rep' );
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

	return %built_config;
}
1;
