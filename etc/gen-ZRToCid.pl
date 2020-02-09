#!perl
use strict;
my $TEXMF = "C:/texlive/2019/texmf-dist";
my $cmap_dir = "$TEXMF/fonts/cmap/adobemapping/cmap-resources";
my $out_version = v0.3.1;
my $out_mod_date = "2020/02/08";

use constant {
  AJ1 => 0, AK1 => 1, AG1 => 2, AC1 => 3, AKR => 4
};
my @data_file = (
  "$cmap_dir/Adobe-Japan1-7/cid2code.txt",
  "$cmap_dir/Adobe-Korea1-2/cid2code.txt",
  "$cmap_dir/Adobe-GB1-5/cid2code.txt",
  "$cmap_dir/Adobe-CNS1-7/cid2code.txt",
  "$cmap_dir/Adobe-KR-9/cid2code.txt",
);
#
use constant { UNDEF_SYM => 'U_' };
my @ccname = qw( AJ1 AK1 AG1 AC1 AKR );
my @column = (
  [ # AJ1
     1, # C_N
    11, # C_90ms_RKSJ
    13, # C_78
    17, # C_UniJIS_UCS2
    21, # C_UniJIS_UTF32
    24, # C_UniJIS2004_UTF32
    25, # C_UniJISX0213_UTF32
    26, # C_UniJISX02132004_UTF32
    50, # C_UniJISPro_UCS2
  ],
  [ #AK1
     7, # C_UniKS_UCS2
    10, # C_UniKS_UTF32
  ],
  [ # AG1
    10, # C_UniGB_UCS2
    13, # C_UniGB_UTF32
  ],
  [ # AC1
     8, # C_UniCNS_UCS2
    11, # C_UniCNS_UTF32
  ],
  [ # AKR
     2, # C_UniAKR-UTF16
     3, # C_UniAKR-UTF32
  ],
);
my @interceptor = (
  { # AJ1
    pre  => \&unijispro_pre,
    line => \&unijispro_line,
  }
);
my @source_prologue = (
  \&source_aj1_prologue,
  \&source_ak1_prologue,
  \&source_ag1_prologue,
  \&source_ac1_prologue,
  \&source_akr_prologue,
);
my @max_cid;

sub main {
  foreach my $idx (0 .. $#ccname) {
    main_inner($idx);
  }
  open(my $ho, '>', "ZRToCid.pm") or die;
  print $ho (source_outer());
  close($ho);
}

sub main_inner {
  my ($idx) = @_;
  my $file = "ZRToCid/" . $ccname[$idx] . ".pm";
  open(my $ho, '>', $file) or die;
  print $ho ($source_prologue[$idx]->(),
             source_cid2code($idx),
             source_inner_epilogue());
  close($ho);
}

sub source_cid2code {
  my ($idx) = @_; my @cnks; my $cnt = 0;
  my $inter = $interceptor[$idx];
  open(my $hi, '<', $data_file[$idx]) or die;
  if (defined $inter) { $inter->{pre}->($hi); }
  while (my $txt = <$hi>) {
    if ($txt =~ m/^\d/) {
      chomp($txt); my @fs = split(m/\t/, $txt);
      if (defined $inter) { $inter->{line}->($cnt, \@fs); }
      @fs = map { conv_cell($_) } (@fs[@{$column[$idx]}]);
      push(@cnks, form_list(\@fs), ",\n"); ++$cnt;
    }
  }
  close($hi);
  $max_cid[$idx] = $cnt - 1;
  return join('', @cnks);
}

sub conv_cell {
  my ($txt) = @_;
  if ($txt eq '*') {
    return undef;
  } elsif ($txt =~ m/^[0-9a-f]+$/) {
    return hex($txt);
  } else {
    my (@h, @v);
    foreach my $f (split(m/,/, $txt)) {
      if ($f =~ m/^[0-9a-f]+$/) {
        push(@h, hex($f));
      } elsif ($f =~ m/^([0-9a-f]+)v$/) {
        push(@v, hex($1));
      } else { die; }
    }
    return [\@h, \@v];
  }
}

sub form_list {
  my ($v) = @_;
  if (ref $v) {
    while (@$v && !defined $v->[-1]) { pop(@$v); }
    if (!@$v) { return UNDEF_SYM; }
    my $r = join(",", map { form_list($_) } (@$v));
    return "[$r]";
  } elsif (defined $v) { return $v; }
  else { return UNDEF_SYM; }
}
{
  my (%unijispro);
  sub unijispro_pre {
    my ($hi) = @_; local ($_); my $st = 0; my @fs;
    while (<$hi>) {
      if ($st == 1) {
        if (@fs = m/^\#\s+U\+(\w+)\s+(\w+)\s+(?:(\w+)|n.a)/) {
          $unijispro{$fs[1]} = hex($fs[0]);
          $unijispro{$fs[2]} = -hex($fs[0]) if ($fs[2] ne 'n/a'); 
        } else { last; }
      }
      if (m/^\#\s+UniJISPro-UCS2-V\s+UniJIS-UCS2-V/) { $st = 1; }
    }
  }
  sub unijispro_line {
    my ($cid, $fs) = @_;
    my $ent = $fs->[17]; my $up = $unijispro{$cid};
    if (defined $up) {
      my $ux = sprintf("%04xv", abs($up));
      if ($up < 0) {
        ($ux eq $ent) or die "Oops($cid)";
        $ent = "*";
      } else {
        $ent = ($ent eq "*") ? $ux : "$ent,$ux";
      }
      #printf("%05d: %s -> %s\n", $cid, $fs->[17], $ent);
    }
    $fs->[50] = $ent;
  }
}

sub source_outer {
  local $_ = <<'END'; #-------------------------------------------------
package ZRToCid;
use strict qw( refs vars subs );
our $VERSION = ?VERSION?;
our $mod_date = ?MODDATE?;
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
  DIR_HORIZ DIR_VERT ?MAXCIDS?
);
our %EXPORT_TAGS = (
  all => [@EXPORT]
);

use constant {
  DIR_HORIZ => 0,
  DIR_VERT => 1,
};
use constant {
?MAXCIDH?};

sub init_rev_map {
  my ($set, $dir, $cid2code) = @_; my (%map);
  if ($dir == DIR_VERT) {
    foreach my $cc (0 .. $#$cid2code) {
      my $v = $cid2code->[$cc][$set];
      if (ref $v && ref $v->[1]) {
        foreach my $sc (@{$v->[1]}) {
          (defined $cc) or next;
          $map{$sc} = $cc;
        }
      }
    }
  }
  foreach my $cc (0 .. $#$cid2code) {
    my $v = $cid2code->[$cc][$set];
    if (!defined $v) {
    } elsif (!ref $v) {
      $map{$v} = $cc if (!exists $map{$v});
    } elsif (ref $v->[0]) {
      foreach my $sc (@{$v->[0]}) {
        (defined $cc) or next;
        $map{$sc} = $cc if (!exists $map{$sc});
      }
    }
  }
  return \%map;
}

1;
END
#-----------------------------------------------------------------------
  my $t = join('', map {
    sprintf("  MAX_CID_%s => %d,\n", $ccname[$_], $max_cid[$_] )
  } (0 .. $#ccname));
  s/\?MAXCIDH\?/$t/;
  $t = join(' ', map { "MAX_CID_$_" } (@ccname));
  s/\?MAXCIDS\?/$t/;
  return set_version($_);
}

sub source_inner_part {
#-----------------------------------------------------------------------
  return <<'END';
use constant { U_ => undef };
*init_rev_map = \&ZRToCid::init_rev_map;
sub get_cid {
  my ($set, $dir, $sc) = @_;
  my $map = $mapsave[$set][$dir];
  if (defined $map) { return $map->{$sc}; }
  $map = $mapsave[$set][$dir] = init_rev_map($set, $dir, \@cid2code);
  return $map->{$sc};
}
sub get_cid_map {
  my ($set, $dir) = @_;
  my $map = $mapsave[$set][$dir];
  if (defined $map) { return $map; }
  $map = $mapsave[$set][$dir] = init_rev_map($set, $dir, \@cid2code);
  return $map;
}
END
#-----------------------------------------------------------------------
}

sub source_aj1_prologue {
#-----------------------------------------------------------------------
  return set_version(<<'END1', source_inner_part(), <<'END2');
package ZRToCid::AJ1;
use strict qw( refs vars subs );
our $VERSION = ?VERSION?;
our $mod_date = ?MODDATE?;
require Exporter;
use ZRToCid;
our @ISA = qw( Exporter );
our @EXPORT = qw( 
  C_ C_N C_90ms_RKSJ C_78 C_UniJIS_UCS2 C_UniJIS_UTF32
  C_UniJIS2004_UTF32 max_cid_aj1 to_aj1
  C_UniJISX0213_UTF32 C_UniJISX02132004_UTF32 C_UniJISPro_UCS2
);
our @EXPORT_OK = qw( get_cid get_cid_map );
our %EXPORT_TAGS = (
  all => [@EXPORT, @EXPORT_OK]
);

our (@cid2code, @mapsave);
sub max_cid_aj1() { return $#cid2code; }
use constant {
  C_                 => 0,
  C_N                => 0,
  C_90ms_RKSJ        => 1,
  C_78               => 2,
  C_UniJIS_UCS2      => 3,
  C_UniJIS_UTF32     => 4,
  C_UniJIS2004_UTF32 => 5,
  C_UniJISX0213_UTF32     => 6,
  C_UniJISX02132004_UTF32 => 7,
  C_UniJISPro_UCS2        => 8,
};
END1
*to_aj1 = \&get_cid;
@cid2code = (
END2
#-----------------------------------------------------------------------
}

sub source_ak1_prologue {
#-----------------------------------------------------------------------
  return set_version(<<'END1', source_inner_part(), <<'END2');
package ZRToCid::AK1;
use strict qw( refs vars subs );
our $VERSION = ?VERSION?;
our $mod_date = ?MODDATE?;
require Exporter;
use ZRToCid;
our @ISA = qw( Exporter );
our @EXPORT = qw( C_UniKS_UCS2 C_UniKS_UTF32 max_cid_ak1 to_ak1 );
our @EXPORT_OK = qw( get_cid get_cid_map );
our %EXPORT_TAGS = (
  all => [@EXPORT, @EXPORT_OK]
);

our (@cid2code, @mapsave);
sub max_cid_ak1() { return $#cid2code; }
use constant {
  C_UniKS_UCS2      => 0,
  C_UniKS_UTF32     => 1,
};
END1
*to_ak1 = \&get_cid;
@cid2code = (
END2
#-----------------------------------------------------------------------
}

sub source_ag1_prologue {
#-----------------------------------------------------------------------
  return set_version(<<'END1', source_inner_part(), <<'END2');
package ZRToCid::AG1;
use strict qw( refs vars subs );
our $VERSION = ?VERSION?;
our $mod_date = ?MODDATE?;
require Exporter;
use ZRToCid;
our @ISA = qw( Exporter );
our @EXPORT = qw( C_UniGB_UCS2 C_UniGB_UTF32 max_cid_ag1 to_ag1 );
our @EXPORT_OK = qw( get_cid get_cid_map );
our %EXPORT_TAGS = (
  all => [@EXPORT, @EXPORT_OK]
);

our (@cid2code, @mapsave);
sub max_cid_ag1() { return $#cid2code; }
use constant {
  C_UniGB_UCS2      => 0,
  C_UniGB_UTF32     => 1,
};
END1
*to_ag1 = \&get_cid;
@cid2code = (
END2
#-----------------------------------------------------------------------
}

sub source_ac1_prologue {
#-----------------------------------------------------------------------
  return set_version(<<'END1', source_inner_part(), <<'END2');
package ZRToCid::AC1;
our $VERSION = ?VERSION?;
our $mod_date = ?MODDATE?;
use strict qw( refs vars subs );
require Exporter;
use ZRToCid;
our @ISA = qw( Exporter );
our @EXPORT = qw( C_UniCNS_UCS2 C_UniCNS_UTF32 max_cid_ac1 to_ac1 );
our @EXPORT_OK = qw( get_cid get_cid_map );
our %EXPORT_TAGS = (
  all => [@EXPORT, @EXPORT_OK]
);

our (@cid2code, @mapsave);
sub max_cid_ac1() { return $#cid2code; }
use constant {
  C_UniCNS_UCS2      => 0,
  C_UniCNS_UTF32     => 1,
};
END1
*to_ac1 = \&get_cid;
@cid2code = (
END2
#-----------------------------------------------------------------------
}

sub source_akr_prologue {
#-----------------------------------------------------------------------
  return set_version(<<'END1', source_inner_part(), <<'END2');
package ZRToCid::AKR;
our $VERSION = ?VERSION?;
our $mod_date = ?MODDATE?;
use strict qw( refs vars subs );
require Exporter;
use ZRToCid;
our @ISA = qw( Exporter );
our @EXPORT = qw( C_UniAKR_UTF16 C_UniAKR_UTF32 max_cid_akr to_akr );
our @EXPORT_OK = qw( get_cid get_cid_map );
our %EXPORT_TAGS = (
  all => [@EXPORT, @EXPORT_OK]
);

our (@cid2code, @mapsave);
sub max_cid_akr() { return $#cid2code; }
use constant {
  C_UniAKR_UTF16     => 0,
  C_UniAKR_UTF32     => 1,
};
END1
*to_akr = \&get_cid;
@cid2code = (
END2
#-----------------------------------------------------------------------
}

sub source_inner_epilogue {
#-----------------------------------------------------------------------
  return <<'END';
);
1;
END
#-----------------------------------------------------------------------
}

sub set_version {
  local $_ = join('', @_); my ($ver);
  $ver = sprintf("%d.%03d_%02d", unpack('c*', $out_version));
  s/\?VERSION\?/$ver/g; s/\?MODDATE\?/"$out_mod_date"/g;
  return $_;
}

main();
# EOF
