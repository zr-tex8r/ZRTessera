# ZRJCode.pm
#

#### start package
package ZRShadowMap;
use strict qw( refs vars subs );
our $VERSION = 0.002_00;
our $mod_date = "2010/04/10";
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( form_shadowmap );

#### procedure definitions

use strict;
use Data::Dump 'dump';
use constant { M => 0x100000, F => 0x10 };
sub mkindex {
  my ($dx, $da) = @_;
  @$da = sort { $a <=> $b } (keys %$dx);
  foreach (0 .. $#$da) { $dx->{$da->[$_]} = $_; }
}
my @hd = (0, M); my @mt = (0, 0, 0, M, 0, 0);
  my @pr = (0, M, 0, 0, M, M, 0);
sub form_shadowmap {
  my ($map) = @_; my (%hx, @ha, %vx, @va, %mx, @lk);
  my @ld = (-1, 2, 0, 0xff, 2, 2, 1, 1, -1, -1, 0, 7);
  foreach my $c (sort { $a <=> $b } (keys %$map)) {
    my $v = $map->{$c};
    (defined $c && defined $v && 0 <= $c && $c <= 0xffff) or return;
    $hx{$c >> 8} = $vx{$v} = 1; $mx{$c} = $v;
  }
  mkindex(\%hx, \@ha); mkindex(\%vx, \@va);
  foreach (keys %mx) { $mx{$_} = $vx{$mx{$_}}; }
  my @ci = map { 0x01100100 + (defined($hx{$_}) ? $hx{$_} : -0x100) }
               (0 .. 0xff);
  my @kr = map { $_ * F } (@va); my $p = scalar(@ha);
  foreach my $ch (@ha) {
    $lk[$hx{$ch}] = 0xfe000000 + $p;
    foreach my $cl (0 .. 0xff) {
      (defined(my $v = $mx{$ch << 8 | $cl})) or next;
      $lk[$p++] = $cl << 16 | 0x8000 | $v;
    }
    $lk[$#lk] |= 0x80000000;
  }
  my $t = pack("N*", @hd, @ci, @mt, @lk, @kr, @pr);
  @ld[0, 8, 9] = (length($t) / 4 + 6, scalar(@lk), scalar(@kr));
  return pack("n*", @ld) . $t;
}
1;
# EOF
