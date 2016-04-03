use strict;
my $tempbase = '__tempzr';
my $query = <<'END';
\documentclass[a4paper]{article}
\usepackage{xltxtra}
\newfontfamily\fontA[RawFeature=-liga]{?FONTA?}
\newfontfamily\fontB[RawFeature=-liga]{?FONTB?}
\begin{document}
\newcount\uc
\newdimen\dimA\newdimen\dimB
\def\procA#1#2{%
\uc=#1 \loop
  \setbox0\hbox{\fontA\iffontchar\font\uc \char\uc \fi}\dimA=\wd0
  \setbox0\hbox{\fontB\iffontchar\font\uc \char\uc \fi}\dimB=\wd0
  \ifdim\dimA=10pt\ifdim\dimB=10pt\relax
  \immediate\write-1{!OUT!\the\uc}%
  %{\fontA\char\uc}
  \fi\fi
  \advance\uc1
\ifnum\uc<#2\relax\repeat}
\procA{"0}{"D7FF}
\procA{"F900}{"FFFF}
\end{document}
END
my @uniblock;
{
  local ($_);
  while (<DATA>) {
    m/^(\w+)\s+(\w+)\s+(\w+)/ or die;
    push(@uniblock, [$1, hex($2), hex($3)]);
  }
}
my @exclude = qw(
  latn1 grek cyrl
  sym04 sym05 sym06 sym07 sym08 sym09 sym10 sym11 sym12 sym13
   sym14 sym15 sym16 sym17 sym18 sym19 sym20 sym21 sym22 brai
   sym23 sym24 sym25 sym26
  sym27 cjk01 cjk02 cjk03 cjk04 hira kana bopo hang2 cjk05
   bopo1 cjk06 kana1 cjk07 cjk08 haniA
  hani
  hani1
  cjk09 sym30 cjk10 cjk11 cjk12
);
my %exclude;
{
  foreach (@exclude) { $exclude{$_} = 1; }
}

{
  local ($_);
  my ($fonta, $fontb) = @ARGV;
  (defined $fontb) or $fontb = $fonta;
  $_ = $query; s/\?FONTA\?/$fonta/; s/\?FONTB\?/$fontb/;
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
  my @list = @uniblock; my @bns;
  L1:foreach my $uc (@ucs) {
    my $ent = $list[0];
    while ($list[0][2] < $uc) {
      shift(@list); (@list) or last L1;
    }
    if ($list[0][1] <= $uc) {
      my $bn = $list[0][0]; shift(@list);
      if (!$exclude{$bn}) { push(@bns, $bn); }
    }
  }
  print "@bns\n";
}
END {
  unlink("$tempbase.tex", "$tempbase.log", "$tempbase.aux");
}

=nop

Adobe ja: (none)
MS ja: latnB
IPA: latnB
Adobe ko :  latn latnA sym01 hang
MS ko: latnA sym01 hang1 hang spc06
Adobe sc: latnA latnB latn2 sym01 latn3
MS sc: sym01
Adobe tc: latnA latnB latn2 sym01 sym02 latn3
MS tc: sym01 sym02

=cut

__DATA__
latn   0000  007F Basic Latin
latn1  0080  00FF Latin-1 Supplement
latnA  0100  017F Latin Extended-A
latnB  0180  024F Latin Extended-B
latn2  0250  02AF IPA Extensions
sym01  02B0  02FF Spacing Modifier Letters
sym02  0300  036F Combining Diacritical Marks
grek   0370  03FF Greek and Coptic
cyrl   0400  04FF Cyrillic
cyrl1  0500  052F Cyrillic Supplement
armn   0530  058F Armenian
hebr   0590  05FF Hebrew
arab   0600  06FF Arabic
syrc   0700  074F Syriac
arab1  0750  077F Arabic Supplement
thaa   0780  07BF Thaana
nkoo   07C0  07FF NKo
samr   0800  08FF Samaritan
deva   0900  097F Devanagari
beng   0980  09FF Bengali
guru   0A00  0A7F Gurmukhi
gujr   0A80  0AFF Gujarati
orya   0B00  0B7F Oriya
taml   0B80  0BFF Tamil
telu   0C00  0C7F Telugu
knda   0C80  0CFF Kannada
mlym   0D00  0D7F Malayalam
sinh   0D80  0DFF Sinhala
thai   0E00  0E7F Thai
laoo   0E80  0EFF Lao
tibt   0F00  0FFF Tibetan
mymr   1000  109F Myanmar
geor   10A0  10FF Georgian
hang1  1100  11FF Hangul Jamo
ethi   1200  137F Ethiopic
ethi1  1380  139F Ethiopic Supplement
cher   13A0  13FF Cherokee
cans   1400  167F Unified Canadian Aboriginal Syllabics
ogam   1680  169F Ogham
runr   16A0  16FF Runic
tglg   1700  171F Tagalog
hano   1720  173F Hanunoo
buhd   1740  175F Buhid
tagb   1760  177F Tagbanwa
khmr   1780  17FF Khmer
mong   1800  187F Mongolian
cans1  1880  18FF Unified Canadian Aboriginal Syllabics Extended
limb   1900  194F Limbu
tale   1950  197F Tai Le
talu   1980  19DF New Tai Lue
khmr1  19E0  19FF Khmer Symbols
bugi   1A00  1A1F Buginese
lana   1A20  1AFF Tai Tham
bali   1B00  1B7F Balinese
sund   1B80  1BFF Sundanese
lepc   1C00  1C4F Lepcha
olck   1C50  1CCF Ol Chiki
sym38  1CD0  1CFF Vedic Extensions
latn4  1D00  1D7F Phonetic Extensions
latn5  1D80  1DBF Phonetic Extensions Supplement
sym03  1DC0  1DFF Combining Diacritical Marks Supplement
latn3  1E00  1EFF Latin Extended Additional
grek1  1F00  1FFF Greek Extended
sym04  2000  206F General Punctuation
sym05  2070  209F Superscripts and Subscripts
sym06  20A0  20CF Currency Symbols
sym07  20D0  20FF Combining Diacritical Marks for Symbols
sym08  2100  214F Letterlike Symbols
sym09  2150  218F Number Forms
sym10  2190  21FF Arrows
sym11  2200  22FF Mathematical Operators
sym12  2300  23FF Miscellaneous Technical
sym13  2400  243F Control Pictures
sym14  2440  245F Optical Character Recognition
sym15  2460  24FF Enclosed Alphanumerics
sym16  2500  257F Box Drawing
sym17  2580  259F Block Elements
sym18  25A0  25FF Geometric Shapes
sym19  2600  26FF Miscellaneous Symbols
sym20  2700  27BF Dingbats
sym21  27C0  27EF Miscellaneous Mathematical Symbols-A
sym22  27F0  27FF Supplemental Arrows-A
brai   2800  28FF Braille Patterns
sym23  2900  297F Supplemental Arrows-B
sym24  2980  29FF Miscellaneous Mathematical Symbols-B
sym25  2A00  2AFF Supplemental Mathematical Operators
sym26  2B00  2BFF Miscellaneous Symbols and Arrows
glag   2C00  2C5F Glagolitic
latnC  2C60  2C7F Latin Extended-C
copt   2C80  2CFF Coptic
geor1  2D00  2D2F Georgian Supplement
tfng   2D30  2D7F Tifinagh
ethi2  2D80  2DDF Ethiopic Extended
cyrlA  2DE0  2DFF Cyrillic Extended-A
sym27  2E00  2E7F Supplemental Punctuation
cjk01  2E80  2EFF CJK Radicals Supplement
cjk02  2F00  2FEF Kangxi Radicals
cjk03  2FF0  2FFF Ideographic Description Characters
cjk04  3000  303F CJK Symbols and Punctuation
hira   3040  309F Hiragana
kana   30A0  30FF Katakana
bopo   3100  312F Bopomofo
hang2  3130  318F Hangul Compatibility Jamo
cjk05  3190  319F Kanbun
bopo1  31A0  31BF Bopomofo Extended
cjk06  31C0  31EF CJK Strokes
kana1  31F0  31FF Katakana Phonetic Extensions
cjk07  3200  32FF Enclosed CJK Letters and Months
cjk08  3300  33FF CJK Compatibility
haniA  3400  4DBF CJK Unified Ideographs Extension A
sym28  4DC0  4DFF Yijing Hexagram Symbols
hani   4E00  9FFF CJK Unified Ideographs
yiii   A000  A48F Yi Syllables
yiii1  A490  A4CF Yi Radicals
lisu   A4D0  A4FF Lisu
vaii   A500  A63F Vai
cyrlB  A640  A69F Cyrillic Extended-B
bamu   A6A0  A6FF Bamum
sym29  A700  A71F Modifier Tone Letters
latnD  A720  A7FF Latin Extended-D
sylo   A800  A82F Syloti Nagri
sym39  A830  A83F Common Indic Number Forms
phag   A840  AB7F Phags-pa
saur   A880  A8DF Saurashtra
deva1  A8E0  A8FF Devanagari Extended
kali   A900  A92F Kayah Li
rjng   A930  A95F Rejang
hangA  A960  A97F Hangul Jamo Extended-A
java   A980  A9FF Javanese
cham   AA00  AA5F Cham
mymrA  AA60  AA7F Myanmar Extended-A
tavt   AA80  ABBF Tai Viet
mtei   ABC0  ABFF Meetei Mayek
hang   AC00  D7AF Hangul Syllables
hangB  D7B0  D7FF Hangul Jamo Extended-B
spc01  D800  DB7F High Surrogates
spc02  DB80  DBFF High Private Use Surrogates
spc03  DC00  DFFF Low Surrogates
spc04  E000  F8FF Private Use Area
hani1  F900  FAFF CJK Compatibility Ideographs
latn6  FB00  FB4F Alphabetic Presentation Forms
arab2  FB50  FDFF Arabic Presentation Forms-A
spc05  FE00  FE0F Variation Selectors
cjk09  FE10  FE1F Vertical Forms
sym30  FE20  FE2F Combining Half Marks
cjk10  FE30  FE4F CJK Compatibility Forms
cjk11  FE50  FE6F Small Form Variants
arab3  FE70  FEFF Arabic Presentation Forms-B
cjk12  FF00  FFEF Halfwidth and Fullwidth Forms
spc06  FFF0  FFFF Specials                               
linb  10000 1007F Linear B Syllabary
linb1 10080 100FF Linear B Ideograms
sym31 10100 1013F Aegean Numbers
grek2 10140 1018F Ancient Greek Numbers
sym40 10190 101CF Ancient Symbols
sym41 101D0 1027F Phaistos Disc
lyci  10280 1029F Lycian
cari  102A0 102FF Carian
ital  10300 1032F Old Italic
goth  10330 1037F Gothic
ugar  10380 1039F Ugaritic
xpeo  103A0 103FF Old Persian
dsrt  10400 1044F Deseret
shaw  10450 1047F Shavian
osma  10480 107FF Osmanya
cprt  10800 1083F Cypriot Syllabary
armi  10840 108FF Imperial Aramaic
phnx  10900 1091F Phoenician
lydi  10920 109FF Lydian
khar  10A00 10A5F Kharoshthi
sarb  10A60 10AFF Old South Arabian
avst  10B00 10B3F Avestan
prti  10B40 10B5F Inscriptional Parthian
phli  10B60 10BFF Inscriptional Pahlavi
orkh  10C00 10E5F Old Turkic
sym42 10E60 1107F Rumi Numeral Symbols
kthi  11080 11FFF Kaithi
xsux  12000 123FF Cuneiform
xsux1 12400 12FFF Cuneiform Numbers and Punctuation
egyp  13000 1CFFF Egyptian Hieroglyphs
sym32 1D000 1D0FF Byzantine Musical Symbols
sym33 1D100 1D1FF Musical Symbols
sym34 1D200 1D2FF Ancient Greek Musical Notation
sym35 1D300 1D35F Tai Xuan Jing Symbols
sym36 1D360 1D3FF Counting Rod Numerals
sym37 1D400 1EFFF Mathematical Alphanumeric Symbols
sym43 1F000 1F02F Mahjong Tiles
sym44 1F030 1F0FF Domino Tiles
sym45 1F100 1F1FF Enclosed Alphanumeric Supplement
cjk13 1F200 1FFFF Enclosed Ideographic Supplement
haniB 20000 2A6FF CJK Unified Ideographs Extension B
haniC 2A700 2F7FF CJK Unified Ideographs Extension C
hani2 2F800 2FFFF CJK Compatibility Ideographs Supplement
