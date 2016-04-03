use strict;
my $tempbase = "__gen_widthcid";
my $xetex = "xetex --interaction=batchmode";

my @fonts = (
  ['Kozuka Mincho Pro-VI', 'Kozuka Gothic Pro-VI', 4],
  ['Adobe Myungjo Std', 'Adobe Myungjo Std', 2, \&adjust_ak1],
  ['Adobe Song Std', 'Adobe Heiti Std', 2],
  ['Adobe Ming Std', 'Adobe Ming Std', 2, \&adjust_ac1],
);

sub adjust_ak1 {
  my ($map) = @_;
  foreach (1 .. 95) { delete $map->{$_}; }
}
sub adjust_ac1 {
  my ($map) = @_;
  foreach (66) { delete $map->{$_}; }
}

use Data::Dump 'dump';
sub main {
  my @cnks; push(@cnks, source_prologue());
  foreach my $ent (@fonts) {
    my $res = compact(get_width(@$ent));
    push(@cnks, "  [\n");
    foreach my $ent2 (@$res) {
      my ($val, $scc, $ecc) = @$ent2;
      push(@cnks, "    [$val,$scc,$ecc],\n");
    }
    push(@cnks, "  ],\n");
  }
  push(@cnks, source_epilogue());
  open(my $ho, '>', "ZRWidthCid.pm") or die;
  print $ho (@cnks);
  close($ho);
  unlink("$tempbase.tex", "$tempbase.log");
}

sub get_width {
  my ($fonta, $fontb, $maxs, $proc) = @_;
  my $txt = <<'END';
% specwid.tex
\def\outtext#1{\immediate\write-1{!OUT!#1}}
\font\fontA="?FONTA?:-palt"\relax
\font\fontB="?FONTB?:-palt"\relax
\newbox\boxA
\newdimen\dimX \newdimen\dimY
\newcount\cntA \newcount\cntB
\newcount\cntI \newcount\cntM \newcount\cntR
\newif\ifnear

\def\near#1#2{\dimY=#1\relax \advance\dimY-\dimX\relax
\ifdim\dimY<0pt \dimY=-\dimY\fi\relax
\ifdim\dimY<0.01pt \cntR=#2\relax\fi}
\cntM=\XeTeXcountglyphs\fontA
\def\wdspec#1{%
  \setbox\boxA\hbox{#1\XeTeXglyph\cntI}%
  \dimX=\wd\boxA \cntR=0\relax
  \near{10pt}{1}\near{5pt}{2}%
  \near{3.33pt}{3}\near{2.50pt}{4}}
\cntI=0 \loop
  \wdspec\fontA \cntA\cntR
  \wdspec\fontB \cntB\cntR
  \ifnum\cntA=0 \else \ifnum\cntA=\cntB
    \outtext{\the\cntI:\the\cntA}%
  \fi\fi
\advance\cntI1 \ifnum\cntI<\cntM \repeat
\bye
END
  $txt =~ s/\?FONTA\?/$fonta/g;
  $txt =~ s/\?FONTB\?/$fontb/g;
  open(my $ho, '>', "$tempbase.tex") or die;
  print $ho ($txt); close($ho);
  system("$xetex $tempbase");
  my (%map);
  open(my $hi, '<', "$tempbase.log") or die;
  while (my $lin = <$hi>) {
    if ($lin =~ m/^!OUT!(\d+):(\d+)/) {
      ($2 <= $maxs) or next;
      $map{$1} = $2;
    } elsif ($lin =~ m/^! /) { die; }
  }
  delete $map{0};
  if (defined $proc) { $proc->(\%map); }
  return \%map;
}

sub compact {
  my ($map) = @_;
  my @key = sort { $a <=> $b } (keys %$map);
  push(@key, $key[-1] + 2); # dummy entry
  my ($scc, $ecc, $pval) = (-2, -2, 0); my @list;
  foreach my $cc (@key) {
    my $val = $map->{$cc};
    if ($pval == $val && $ecc + 1 == $cc) {
      $ecc = $cc;
    } else {
      push(@list, [$pval, $scc, $ecc]);
      ($scc, $ecc, $pval) = ($cc, $cc, $val);
    }
  }
  shift(@list);
  return \@list;
}

sub source_prologue {
#-----------------------------------------------------------
  return <<'END';
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
END
#-----------------------------------------------------------
}

sub source_epilogue {
#-----------------------------------------------------------
  return <<'END';
);
1;
# EOF
END
#-----------------------------------------------------------
}

main();
