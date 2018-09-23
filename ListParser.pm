package ListParser;

sub parse_mapping {
	my ($input) = @_;
	my $key, $value;
	my $i = 0;
	my $string_start, $string_end;
	$string_start = $string_end = undef;

	# Are we currently lexing inside a string literal?
	my $is_string = 0;

	# Currently parsing key or value?
	my $is_key = 1;

	while ($i < length($input)) {
		my $c = substr($input, $i, 1);
		my $lookahead = substr($input, $i+1, 1);

		if ($is_string and $c eq "'") {
			$is_string = 0;
			$string_end = $i;
			if (not $is_key) {
				$value = substr($input, $string_start, $string_end - $string_start);
			}
			$i++;
			next;
		}
		if (not $is_string) {
			if ($c =~ /\s/) {
				# allow whitespace
			} elsif ($c eq "'") {
				return (("Key/value must consist of single string", $string_start, $i)) if defined $string_end;
				$is_string = 1;
				$string_start = $i + 1;
			} elsif ($c eq "=") {
				return (("Expected > after =, got $lookahead", $i + 1, $i + 1)) unless $lookahead eq ">";
				return (("Unexpected '=>'.", $i, $i)) unless $is_key;
				$i++;

				$key = substr($input, $string_start, $string_end - $string_start);
				$string_start = $string_end = undef;
				$is_key = 0;
			} else {
				return (("Unexpected $c", $i, $i));
			}
		}
		$i++;
	}

	return ((undef, $i, $i), ($key, $value));
}

sub parse_list {
	my ($input, $is_hash) = @_;
	my $c_start = $is_hash ? "{" : "[";
	my $c_end   = $is_hash ? "}" : "]";
	my %h_res;
	my @a_res;
	my $i = 0;

	# Index of the start of the current item
	my $item_i = 0;

	# Level of nested lists, 1 being the minimum
	my $nest = 1;

	return (("Error: expected $c_start", $i, $i)) unless substr($input, $i, 1) eq $c_start;

	$i++;
	$item_i = $i;

	while ($nest != 0 && $i < length($input)) {
		my $c = substr($input, $i, 1);

		if ($c eq $c_start) {
			$nest++;
		} elsif ($c eq $c_end) {
			$nest--;
		}

		if (($nest == 1 and $c eq ",") || ($nest == 0 and $c eq $c_end)) {
			my $item = substr($input, $item_i, $i - $item_i);
			$item =~ s/^\s+|\s+$//g;
			if ($is_hash) {
				my (($error, $from, $to), ($key, $value)) = parse_mapping($item);
				$from += $item_i;
				$to += $item_i;
				return (($error, $from, $to)) if $error;
				return (("Error: duplicate key \"$key\"", $item_i, $to)) if grep {$_ eq $key} (keys %h_res);
				$h_res{$key} = $value;
			} else {
				push @a_res, $item;
			}
			$item_i = $i+1;
		}
		$i++;
	}

	return (("Error: expected $c_end, got end of line", $i, $i)) unless $nest == 0;

	if ($i != length($input)) {
		return (("Error: unexpected item in the bagging area (after '$c_end')", $i, $i));
	}

	return ((undef, undef, undef), %h_res) if $is_hash;
	return ((undef, undef, undef), @a_res);
}
1;
