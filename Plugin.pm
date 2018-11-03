package Plugin;

use strict;
use warnings;

my $load_callback;

sub set_load_callback {
	($load_callback) = @_;
};

sub load_plugin {
	my ($logger, $config, $module) = @_;
	(my $path = $module) =~ s,::,/,g;

	return "$module is already loaded, no changes made" if grep {$_ eq $module} @{$config->{active_plugins}};

	eval {
		require $path . ".pm";
	} or do {
		chomp $@;
		$logger->($@);
		return "Cannot load $module: $!";
	};

	if (not $module->can("configure")) {
		$logger->("Loaded $module but it can't be configured. Probably not a module for us");
		return "Can't configure $module. It probably isn't a module for me. Unloaded it.";
	}

	push @{$config->{active_plugins}}, $module;
	$load_callback->($module);
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
