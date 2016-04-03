#!perl
# gen-ZRCharWidth.pl
#
use strict;
require 'xequery.pl';
use Data::Dump 'dump';
my @entries = (
  ['msmin', 'MS Mincho:-palt'],
  ['msgoth', 'MS Gothic:-palt'],
  ['mspmin', 'MS PMincho:-palt'],
  ['mspgoth', 'MS PGothic:-palt'],
);
my @querycnks = (<<'END');
\newbox\boxA
\newcount\cntC
\newcount\cntM
\newcount\cntN
\def\writeout#1{\immediate\write-1{!OUT!#1}}
\def\procA#1#2{%
  \font\fontA="#2"\relax
  \def\msgA{#1}\fontA
  \cntM=\XeTeXfirstfontchar\font
  \cntN=\XeTeXlastfontchar\font
  \cntC=\cntM \loop
    \iffontchar\font\cntC
      \setbox\boxA\hbox{\char\cntC}%
      \writeout{\msgA:\the\cntC=\the\wd\boxA}%
    \fi
  \ifnum\cntC<\cntN \advance\cntC1 \repeat
}
END

sub relwidth {
  return substr($_[0], 0, -2) / 10;
}
{
  foreach my $ent (@entries) {
    my ($fid, $fname) = @$ent;
    push(@querycnks, "\\procA{$fid}{$fname}\n");
  }
  push(@querycnks, "\\bye\n");
  my $query = join('', @querycnks);
#print($query);exit;
  my $par = xequery($query, { filter => \&relwidth });
  #---------------------------------------------------------
  my @res = (<<'END');
package ZRCharWidth;
use strict qw( refs vars subs );
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( font_charwidth );
sub font_charwidth {
  return $width{$_[0]}{$_[1]};
}
sub font_charwidth_map {
  return $width{$_[0]};
}
our %width = (
END
  #---------------------------------------------------------
  foreach my $ent (@entries) {
    my ($fid, $fname) = @$ent;
    push(@res, "'$fid' => {\n");
    my $map = $par->{$fid} or die;
    my @ucs = sort { $a <=> $b } (keys %$map);
    foreach my $uc (@ucs) {
      push(@res, sprintf("0x%X=>%s,\n", $uc, $map->{$uc}));
    }
    push(@res, "},\n");
  }
  #---------------------------------------------------------
  push(@res, <<'END');
);
END
  #---------------------------------------------------------
  open(my $ho, '>', "ZRCharWidth.pm") or die;
  print $ho (@res); close($ho);
}

