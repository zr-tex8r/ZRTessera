use strict;
my $tempbase = '__tempzr';
my $query = <<'END';
\documentclass[a4paper]{article}
\usepackage{xltxtra}
\newfontfamily\fontA[RawFeature=-liga]{?FONTA?}
\begin{document}
\newcount\uc
\newdimen\dimA\newdimen\dimB
\def\procA#1#2{%
\fontA \uc=#1 \loop
  \iffontchar\font\uc
  \immediate\write-1{!OUT!\the\uc}%
  \fi
  \advance\uc1
\ifnum\uc<#2\relax\repeat}
\procA{"10000}{"2FFFF}
\end{document}
END
use ZRToCid::AJ1;
use ZRToCid::AK1;
use ZRToCid::AG1;
use ZRToCid::AC1;

sub main {
  my (@ucs);
  @ucs = grep { defined to_aj1(C_UniJIS2004_UTF32, 0, $_) }
           (0x20000 .. 0x2FFFF);
  print(lister(\@ucs));
  @ucs = grep { defined to_ak1(C_UniKS_UTF32, 0, $_) }
           (0x20000 .. 0x2FFFF);
  print(lister(\@ucs));
  @ucs = grep { defined to_ag1(C_UniGB_UTF32, 0, $_) }
           (0x20000 .. 0x2FFFF);
  print(lister(\@ucs));
  @ucs = grep { defined to_ac1(C_UniCNS_UTF32, 0, $_) }
           (0x20000 .. 0x2FFFF);
  print(lister(\@ucs));
  
}
sub main1 {
  local ($_);
  my ($fonta) = @ARGV;
  $_ = $query; s/\?FONTA\?/$fonta/;
  open(OUT, '>', "$tempbase.tex") or die;
  print OUT ($_); close(OUT);
  system("xelatex $tempbase");
  my @ucs;
  open(IN, '<', "$tempbase.log") or die;
  while (<IN>) {
    m/^!OUT!(\d+)/ or next;
    push(@ucs, $1);
  }
  close(IN);
  #
  @ucs = sort { $a <=> $b } (@ucs);
  open(OUT, '>', "output.txt") or die;
  print OUT (lister(\@ucs));
  close(OUT);
}
sub lister {
  my ($ucs) = @_;
  my @cnks = ("  [\n");
  foreach (my $n = 0; $n <= $#$ucs; $n += 5) {
    my $m = $n + 4; ($m <= $#$ucs) or $m = $#$ucs;
    my @k = map { sprintf("0x%05X", $_) } (@{$ucs}[$n .. $m]);
    push(@cnks, "    " . join(", ", @k) . ",\n");
  }
  push(@cnks, "  ],\n");
  return join('', @cnks);
}

END {
  unlink("$tempbase.tex", "$tempbase.log", "$tempbase.aux");
}
main();
