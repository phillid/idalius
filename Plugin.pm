package Plugin;

use strict;
use warnings;

my $unload_callback;

sub load_plugin {
	my ($logger, $config, $module) = @_;
	(my $path = $module) =~ s,::,/,g;

	return "$module is already loaded, no changes made" if grep {$_ eq $module} @{$config->{active_plugins}};

	eval {
		require $path . ".pm";
		push @{$config->{active_plugins}}, $module;
	} or do {
		chomp $@;
		$logger->($@);
		return "Cannot load $module: $!";
	};
	return undef;
}

sub unload_plugin {
	my ($logger, $config, $module) = @_;

	return "$module is not loaded, no changes made" unless grep {$_ eq $module} @{$config->{active_plugins}};

	my @new_plugins = grep {$_ ne $module} @{$config->{active_plugins}};
	$config->{active_plugins} = \@new_plugins;
	return undef;
}
1;
