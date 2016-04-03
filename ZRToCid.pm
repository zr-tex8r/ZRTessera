package ZRToCid;
use strict qw( refs vars subs );
our $VERSION = 0.002_00;
our $mod_date = "2010/04/10";
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
  DIR_HORIZ DIR_VERT MAX_CID_AJ1 MAX_CID_AK1 MAX_CID_AG1 MAX_CID_AC1
);

use constant {
  DIR_HORIZ => 0,
  DIR_VERT => 1,
};
use constant {
  MAX_CID_AJ1 => 23057,
  MAX_CID_AK1 => 18351,
  MAX_CID_AG1 => 30283,
  MAX_CID_AC1 => 19155,
};

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