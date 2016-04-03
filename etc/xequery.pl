#
# xequery.pl
#

my $xeq_temp_base = '__xeq_temp' . $$ . 'x';
my $xeq_opt_batch = '--interaction=batchmode';
my $xeq_xetex_cmd = 'xetex';

sub xequery {
  my ($query, $param) = @_;
  my $pfx = (defined $param->{prefix}) ? $param->{prefix} : '!OUT!';
  my $cmd = (defined $param->{tex}) ? $param->{tex} : $xeq_xetex_cmd;
  $cmd = "$cmd $xeq_opt_batch";
  open(my $ho, '>', "$xeq_temp_base.tex") or return;
  print $ho ($query); close($ho);
  system("$cmd $xeq_temp_base");
  (-s "$xeq_temp_base.log") or return;
  my $lin; my $par = {};
  my $rxout = qr/^\Q$pfx\E(.*)/;
  open(my $hi, '<', "$xeq_temp_base.log") or return;
  while ($lin = <$hi>) {
    if ($lin =~ m/^! /) { return; }
    elsif ($lin =~ $rxout) {
      xeq_nest_assign($par, $param->{filter}, $1) or return;
    }
  }
  close($hi);
  return $par;
}

sub xeq_nest_assign {
  my ($hash, $conv, $text) = @_;
  my ($pname, $value) = ($text =~ m/^(.*?)=(.*)$/) or return;
  my @plist = split(m/:/, $pname);
  if (defined $conv) { $value = $conv->($value); }
  xeq_nest_assign_sub_($hash, \@plist, $value);
  return 1;
}

sub xeq_nest_assign_sub_ {
  my ($hash, $plist, $value) = @_;
  my ($name, @plist1) = @$plist;
  if (!@plist1) {
    $hash->{$name} = $value;
  } else {
    (exists $hash->{$name}) or $hash->{$name} = {};
    xeq_nest_assign_sub_($hash->{$name}, \@plist1, $value);
  }
}

sub xeq_subst {
  my ($text, $subst) = @_;
  foreach my $key (keys %$subst) {
    my $val = $subst->{$key};
    $text =~ s/\?\Q$key\E\?/$val/g;
  }
  return $text;
}

END {
  unlink("$xeq_temp_base.tex", "$xeq_temp_base.aux",
         "$xeq_temp_base.log", "$xeq_temp_base.pdf");
}

1;
