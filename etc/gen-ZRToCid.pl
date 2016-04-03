#!perl
use strict;
my $TEXMF = "C:/usr/local/share/texmf";
my $out_version = v0.2.0;
my $out_mod_date = "2010/04/10";

use constant {
  AJ1 => 0, AK1 => 1, AG1 => 2, AC1 => 3
};
my @data_file = (
  "$TEXMF/fonts/cmap/adobemapping/aj16/cid2code.txt",
  "$TEXMF/fonts/cmap/adobemapping/ak12/cid2code.txt",
  "$TEXMF/fonts/cmap/adobemapping/ag15/cid2code.txt",
  "$TEXMF/fonts/cmap/adobemapping/ac16/cid2code.txt",
);
#
use constant { UNDEF_SYM => 'U_' };
my @ccname = qw( AJ1 AK1 AG1 AC1 );
my @column = (
  [ # AJ1
     1, # C_N
    11, # C_90ms_RKSJ
    13, # C_78
    17, # C_UniJIS_UCS2
    21, # C_UniJIS_UTF32
    24, # C_UniJIS2004_UTF32
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
);
my @source_prologue = (
  \&source_aj1_prologue,
  \&source_ak1_prologue,
  \&source_ag1_prologue,
  \&source_ac1_prologue,
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
  my ($idx) = @_; my (@cnks, $cnt);
  open(my $hi, '<', $data_file[$idx]) or die;
  while (my $txt = <$hi>) {
    if ($txt =~ m/^\d/) {
      chomp($txt); my @fs = split(m/\t/, $txt);
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
);
our @EXPORT_OK = qw( get_cid get_cid_map );

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
