package ZRWidthCid;
use strict qw( refs vars subs );
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( 
  width_aj1 width_ak1 width_ag1 width_ac1
);
our @EXPORT_OK = qw(
  CC_AJ1 CC_AK1 CC_AG1 CC_AC1 width_cid
);
our (@width_range, @width_map_save);

use constant {
  CC_AJ1 => 0, CC_AK1 => 1, CC_AG1 => 2, CC_AC1 => 3
};
sub width_aj1 { return width_cid(CC_AJ1, $_[0]); }
sub width_ak1 { return width_cid(CC_AK1, $_[0]); }
sub width_ag1 { return width_cid(CC_AG1, $_[0]); }
sub width_ac1 { return width_cid(CC_AC1, $_[0]); }

sub width_cid {
  my ($ccol, $cc) = @_;
  my $map = $width_map_save[$ccol];
  if (defined $map) { return $map->{$cc}; }
  $map = $width_map_save[$ccol] = create_map($width_range[$ccol]);
  return $map->{$cc};
}

sub create_map {
  my ($list) = @_; my (%map);
  foreach my $ent (@$list) {
    my ($val, $scc, $ecc) = @$ent;
    foreach my $cc ($scc .. $ecc) { $map{$cc} = $val; }
  }
  return \%map;
}

@width_range = (
  [
    [2,231,632],
    [1,633,8717],
    [2,8718,8719],
    [1,8720,9353],
    [4,9738,9757],
    [3,9758,9778],
    [1,9779,12062],
    [2,12063,12087],
    [1,12088,15448],
    [1,15453,15454],
    [1,15462,15463],
    [1,15527,15528],
    [1,15572,15574],
    [1,15600,15600],
    [1,15719,15722],
    [1,15976,20316],
    [1,20427,23057],
  ],
  [
    [1,96,96],
    [2,97,97],
    [1,98,8093],
    [2,8094,8190],
    [1,8191,18351],
  ],
  [
    [1,96,813],
    [2,814,939],
    [1,940,7711],
    [2,7716,7716],
    [1,7717,22352],
    [2,22355,22357],
    [1,22358,29063],
  ],
  [
    [1,96,13647],
    [2,13648,13742],
    [1,13743,17600],
    [1,17602,17602],
    [2,17603,17603],
    [1,17604,19087],
  ],
);
1;
# EOF
