
use strict;
our @order = (
  'n-h', 'n-v', 'ex-h', 'ex-v', 'rb-h', 'rb-v',
);
our @jis_code = (
  0x2135, 0x2136, 0x2133, 0x2134, 0x213C,
  0x2421 .. 0x247B, # (H) a-sml .. n, vu, ka-sml, ke-sml, ka+svm .. ko+svm
  0x2521 .. 0x257E, # (K) a-sml .. n, vu, ka-sml, ke-sml, ka+svm .. ko+svm,
                    #     se+svm, tu+svm, to+svm
  0x266E .. 0x267E, # (K) ku-sml, si-sml, su-sml, to-sml, nu-sml, ha-sml ..
                    #     ho-sml, pu-sml, mu-sml, ra-sml .. ro-sml
  0x2772 .. 0x2775, #
  # 5 / 83+3+5 / 83+3+5+3 / 17 / 4
);
sub DK { return (undef) x $_[0]; }
our @jis_code_v = (
  0x213C,
  0x2421, 0x2423, 0x2425, 0x2427, 0x2429,
  0x2443, 0x2463, 0x2465, 0x2467, 0x246E,
  0x2475, 0x2476,
  0x2521, 0x2523, 0x2525, 0x2527, 0x2529,
  0x2543, 0x2563, 0x2565, 0x2567, 0x256E,
  0x2575, 0x2576,
  0x266E .. 0x267E
  # 1 / 10+2 / 10+2 / 17
);
our %aj1_code = (
  'n-h' => [
    653..654, 651..652, 660,
    842..924, 7958..7960, 16209..16213,
    925..1010, 16214..16221, 16236..16252, 8313..8316,
  ],
  'ex-h' => [
    12273..12274, 12362..12364,
    12275..12284, 12286..12291, 12293..12294, 12296..12360,
    12361, 12285, 12292, 16352..16356,
    12365..12374, 12376..12381, 12383..12384, 12386..12450,
    12451, 12375, 12382, 16357..16364, 16365..16381, 12452..12455,
  ],
  'ex-v' => [
    12456..12457, 12545..12547,
    12458..12467, 12469..12474, 12476..12477, 12479..12543,
    12544, 12468, 12475, 16382..16386,
    12548..12557, 12559..12564, 12566..12567, 12569..12633,
    12634, 12558, 12565, 16387..16411, 12635 .. 12638,
  ],
  'rb-h' => [
     12651..12652, 12649..12650, 12867,
     12671..12681, 12683..12688, 12690..12755,
     12756, 12682, 12689, 16414..16418,
     12769..12779, 12781..12786, 12788..12853,
     12854, 12780, 12787, 16419..16443, 16444..16447,
  ],
);
our %aj1_code_v = (
  'n-v' => [
    7891,
    7918..7927, 8264, 8265,
    7928..7939, 16333..16349,
  ],
  'rb-v' => [
    12868,
    12757..12761, 12764..12768, 12762, 12763,
    12855..12859, 12862..12866, 12860, 12861,
    16450..16466,
  ],
);
our %map;
{
  foreach my $ord (0 .. $#order) {
    my $sym = $order[$ord];
    my $vert = $aj1_code_v{$sym};
    my $symh = $sym; if (defined $vert) { $symh =~ s/-v/-h/; }
    my $base = $aj1_code{$symh} or die;
    foreach (0 .. $#jis_code) {
      $map{$jis_code[$_]}[$ord] = $base->[$_];
    }
    if (defined $vert) {
      foreach (0 .. $#jis_code_v) {
        $map{$jis_code_v[$_]}[$ord] = $vert->[$_];
      }
    }
  }
}
{
#-----------------------------------------------------------
  my @cnks = <<'END';
package ZRKanaCid;
use strict qw( refs vars subs );
our $VERSION = 0.002_00;
our $mod_date = "2010/04/10";
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( to_cid_kana KANA_NORM KANA_EXP KANA_RUBY );
our %cid_kana;
use constant { KANA_NORM => 0, KANA_EXP => 1, KANA_RUBY => 2 };
sub to_cid_kana {
  my ($set, $dir, $jc) = @_;
  return $cid_kana{$jc}[$set * 2 + (($dir) ? 1 : 0)];
}
%cid_kana = (
END
#-----------------------------------------------------------
  my @jcs = sort { $a <=> $b } (keys %map);
  foreach my $jc (@jcs) {
    my $t = join(',', @{$map{$jc}});
    push(@cnks, sprintf("0x%04X=>[%s],\n", $jc, $t));
  }
#-----------------------------------------------------------
  push(@cnks, <<'END');
);
1;
# EOF
END
#-----------------------------------------------------------
  open(my $ho, '>', "ZRKanaCid.pm") or die;
  print $ho (@cnks);
  close($ho);
}

