# ZRJCode.pm
#

#### start package
package ZRJCode;
use strict qw( refs vars subs );
our $VERSION = 0.002_01;
our $mod_date = "2010/05/06";
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = ();
our @EXPORT_OK = qw(
  in_hex chrw ordw chrk ordk chrjis
  jis euc sjis kuten
  in_jis in_euc in_sjis in_kuten
  in_ucs ucs is_pua_ucs is_pua_jis is_kanji_ucs is_kanji_jis
  avail_jis avail_jis_p defined_jis defined_jis_p
  is_hwjis_ucs avail_jis_h avail_jis_hp
  EJV_JIS EJV_MS EJV_JIS2000 EJV_JIS2004 EJV_PTEX EJV_UPTEX
  MAX_UCS MAX_INTCODE MAX_INTCODE_EXT
);
our %EXPORT_TAGS = (
  all => [@EXPORT_OK]
);
our $VERSION = 0.002_00;

#### procedure definitions

use strict;
use Encode;
#
use constant {
  MAX_UCS => 0x10FFFF,
  MAX_INTCODE => 94*94-1, MAX_INTCODE_EXT => 120*94-1,
};

#---------------------------------------

## internal and jis-friend encodings

use constant {
  ECI_XRDX => 0, ECI_XHB => 1, ECI_XLB => 2,
  ECI_IRDX => 3, ECI_IHB => 4, ECI_ILB => 5,
};
use constant {
  ECS_UTF8 => -2, ECS_UCS => -1,
  ECS_JIS => 0, ECS_EUC => 1, ECS_SJIS => 2, ECS_KUTEN => 3
};

my @csinfo_ = (
  [256, [0x21 .. 0x98], [0x21 .. 0x7e]],  # ECS_JIS
  [256, [0xa1 .. 0xfe], [0xa1 .. 0xfe]],  # ECS_EUC
  [256, [0x81 .. 0x9f, 0xe0 .. 0xfc],     # ECS_SJIS
        [0x40 .. 0x7e, 0x80 .. 0xfc]],
  [100, [1 .. 120], [1 .. 94]],           # ECS_KUTEN
);
foreach (@csinfo_) { init_csi_entry_($_); }

sub from_internal_ {
  my ($ic, $cs) = @_; my ($csi, $hb, $lb);
  (defined $ic && $ic >= 0) or return undef;
  (defined($csi = $csinfo_[$cs])) or return undef;
  $hb = $csi->[ECI_XHB][int($ic / $csi->[ECI_IRDX])];
  $lb = $csi->[ECI_XLB][$ic % $csi->[ECI_IRDX]];
  (defined $hb && defined $lb) or return undef;
  return $hb * $csi->[ECI_XRDX] + $lb;
}

my @pl2hbofs_ = (1, 8, 3, 4, 5, 12 .. 15, 78 .. 94);
my (@pl2hb_, @pl2hb_rev_);
{
  my ($i, $v);
  foreach $i (0 .. $#pl2hbofs_) {
    $v = $pl2hbofs_[$i] - 1;
    $pl2hb_[$i + 94] = $v; $pl2hb_rev_[$v] = $i + 94;
  }
}
sub internal_to_xeuc_ {
  my ($ic) = @_; my ($hb, $ec);
  (defined $ic && $ic >= 0) or return undef;
  if ($ic < 94 * 94) {
    return pack('n', from_internal_($ic, ECS_EUC));
  }
  (defined($hb = $pl2hb_[int($ic / 94)])) or return undef;
  $ec = from_internal_($hb * 94 + $ic % 94, ECS_EUC);
  return pack('cn', 0x8F, $ec);
}

sub to_internal_ {
  my ($xc, $cs) = @_; my ($csi, $hb, $lb);
  (defined $xc && $xc >= 0) or return undef;
  (defined($csi = $csinfo_[$cs])) or return undef;
  $hb = $csi->[ECI_IHB][int($xc / $csi->[ECI_XRDX])];
  $lb = $csi->[ECI_ILB][$xc % $csi->[ECI_XRDX]];
  (defined $hb && defined $lb) or return undef;
  return $hb * $csi->[ECI_IRDX] + $lb;
}

sub init_csi_entry_ {
  my ($ent) = @_;
  $ent->[ECI_IRDX] = scalar(@{$ent->[ECI_XLB]});
  $ent->[ECI_IHB] = rev_arraymap_($ent->[ECI_XHB]);
  $ent->[ECI_ILB] = rev_arraymap_($ent->[ECI_XLB]);
}

sub rev_arraymap_ {
  my ($map) = @_; my ($t, @rmap);
  foreach $t (0 .. $#$map) {
    if (defined $map->[$t]) { $rmap[$map->[$t]] = $t; }
  }
  return \@rmap;
}

#---------------------------------------
## internal vs unicode

use constant {
  EJV_JIS => 0, EJV_MS => 1, EJV_JIS2000 => 2, EJV_JIS2004 => 3,
  EJV_PTEX => 4, EJV_UPTEX => 5
};
my @e_enc_name_ = ( 'shiftjis', 'cp932', 'eucjp');
our (@int_to_uni_, @uni_to_int_);

sub internal_to_unicode_ {
  my ($ic, $jver) = @_; my ($t, $e, $uc);
  (defined $ic) or return undef;
  if (!defined $jver) { $jver = EJV_JIS; }
  if (exists $int_to_uni_[$jver]{$ic})
  { return $int_to_uni_[$jver]{$ic}; }
  eval {
    if ($jver >= EJV_PTEX) {
      $uc = int_to_uni_ex_($ic, $jver);
      if (!defined $uc) {
        (defined($t = from_internal_($ic, ECS_SJIS))) or die;
        $e = $e_enc_name_[0]; $t = pack('n', $t);
        $uc = ord(Encode::decode($e, $t, Encode::FB_CROAK));
      }
    } elsif ($jver >= EJV_JIS2000) {
      $uc = int_to_uni_ex_($ic, $jver);
      if (!defined $uc) {
        (defined($t = internal_to_xeuc_($ic))) or die;
        $e = $e_enc_name_[2];
        $uc = ord(Encode::decode($e, $t, Encode::FB_CROAK));
      }
    } else {
      (defined($t = from_internal_($ic, ECS_SJIS))) or die;
      $e = $e_enc_name_[$jver]; $t = pack('n', $t);
      $uc = ord(Encode::decode($e, $t, Encode::FB_CROAK));
    }
  };
  if ($@) { return undef; }
  $int_to_uni_[$jver]{$ic} = $uc;
  return $uc;
}

sub unicode_to_internal_ {
  my ($uc, $jver) = @_; my ($t, $e, $ic);
  (defined $uc) or return undef;
  (defined $jver) or $jver = EJV_JIS;
  if (exists $uni_to_int_[$jver]{$uc})
  { return $uni_to_int_[$jver]{$uc}; }
  eval {
    (0 <= $uc && $uc <= MAX_UCS) or die;
    if ($jver >= EJV_PTEX) {
      $ic = uni_to_int_ex_($uc, $jver);
      if (!defined $ic) {
        $e = $e_enc_name_[$jver]; $t = chr($uc);
        $t = unpack('n', (Encode::encode($e, $t, Encode::FB_CROAK)));
        $ic = to_internal_($t, ECS_SJIS);
      }
    } elsif ($jver >= EJV_JIS2000) {
      die;
    } else {
      $e = $e_enc_name_[$jver]; $t = chr($uc);
      $t = unpack('n', (Encode::encode($e, $t, Encode::FB_CROAK)));
      $ic = to_internal_($t, ECS_SJIS);
    }
  };
  if ($@) { return undef; }
  $uni_to_int_[$jver]{$uc} = $ic;
  return $ic;
}

#----------------------------------------
## internal vs unicode

my %ptex_int_to_uni_ = (
  32, 0xFF5E,
  33, 0x2225,
  60, 0xFF0D,
  80, 0xFFE0,
  81, 0xFFE1,
 137, 0xFFE2,
);
my %uptex_int_to_uni_ = (
  80, 0xFFE0,
  81, 0xFFE1,
 137, 0xFFE2,
);
my %jis2004_int_to_uni_ = (
   1222 => 0x4FF1,  # 1-14-01
   1409 => 0x525D,  # 1-15-94
   4375 => 0x20B9F, # 1-47-52
   4417 => 0x541E,  # 1-47-94
   7808 => 0x5653,  # 1-84-07
   8831 => 0x59F8,  # 1-94-90
   8832 => 0x5C5B,  # 1-94-91
   8833 => 0x5E77,  # 1-94-92
   8834 => 0x7626,  # 1-94-93
   8835 => 0x7E6B,  # 1-94-94
);
my %ptex_uni_to_int_ = (
0x00A5,   78,
0x2012,   28,
0x2013,   28,
0x2014,   28,
0x2022,    5,
0x203E,   16,
0x20DD,  187,
0x2219,    5,
0x2223,   34,
0x2225,   33,
0x223C,   32,
0x223E,   32,
0x22C5,    5,
0x22EF,   35,
0xFF0D,   60,
0xFF5E,   32,
0xFFE0,   80,
0xFFE1,   81,
0xFFE2,  137,
);
sub int_to_uni_ex_ {
  my ($ic, $jver) = @_;
  if ($jver == EJV_PTEX) {
    return $ptex_int_to_uni_{$ic};
  } elsif ($jver == EJV_UPTEX) {
    return $uptex_int_to_uni_{$ic};
  } elsif ($jver == EJV_JIS2004) {
    return $jis2004_int_to_uni_{$ic};
  }
  return;
}
sub uni_to_int_ex_ {
  my ($uc, $jver) = @_;
  if ($jver == EJV_PTEX || $jver == EJV_UPTEX) {
    return $ptex_uni_to_int_{$uc};
  }
  return 
}


#----------------------------------------
## public routine
use constant { ECS_SYS => ECS_SJIS };

sub in_hex {
  return sprintf("%04X", $_[0]);
}
sub chrw {
  return pack('n', $_[0]);
}
sub ordw {
  return unpack('n', $_[0]);
}
sub chrk {
  return pack('n', from_internal_($_[0], ECS_SYS));
}
sub ordk {
  return to_internal_(unpack('n', $_[0]), ECS_SYS);
}
sub chrjis {
  return "\e[\$B" . pack('n', $_[0]) . "\e[(B";
}

sub jis {
  return to_internal_($_[0], ECS_JIS);
}
sub euc {
  return to_internal_($_[0], ECS_EUC);
}
sub sjis {
  return to_internal_($_[0], ECS_SJIS);
}
sub kuten {
  return to_internal_($_[0], ECS_KUTEN);
}
sub in_jis {
  return from_internal_($_[0], ECS_JIS);
}
sub in_euc {
  return from_internal_($_[0], ECS_EUC);
}
sub in_sjis {
  return from_internal_($_[0], ECS_SJIS);
}
sub in_kuten {
  return from_internal_($_[0], ECS_KUTEN);
}

sub in_ucs {
  return internal_to_unicode_($_[0], $_[1]);
}
sub ucs {
  return unicode_to_internal_($_[0], $_[1]);
}

sub is_pua_ucs {
  return (0xE000 <= $_[0] && $_[0] <= 0xF8FF);
}
sub is_pua_jis {
  return (8837 <= $_[0] && $_[0] <= 10715);
}

sub is_hwjis_ucs {
  return ((0x20 <= $_[0] && $_[0] <= 0x7E) ||
          (0xFF61 <= $_[0] && $_[0] <= 0xFF9F));
}
sub is_kanji_ucs {
  return ((0x2E80 <= $_[0] && $_[0] <= 0x2FEF) ||
          (0x3400 <= $_[0] && $_[0] <= 0x4DBF) ||
          (0x4E00 <= $_[0] && $_[0] <= 0x9FFF) ||
          (0xF900 <= $_[0] && $_[0] <= 0xFAFF) ||
          (0x20000 <= $_[0] && $_[0] <= 0x2FFFF));
}
sub is_kanji_jis {
  return is_kanji_ucs(internal_to_unicode_($_[0], $_[1]));
}

sub avail_jis {
  return !is_pua_ucs($_[0]) && avail_jis_p($_[0], $_[1]);
}
sub avail_jis_p {
  return defined(unicode_to_internal_($_[0], $_[1]));
}
sub avail_jis_h {
  return is_hwjis_ucs($_[0]) || avail_jis($_[0]);
}
sub avail_jis_hp {
  return is_hwjis_ucs($_[0]) || avail_jis_p($_[0]);
}
sub defined_jis {
  return !is_pua_jis($_[0]) && defined_jis_p($_[0], $_[1]);
}
sub defined_jis_p {
  return defined(internal_to_unicode_($_[0], $_[1]));
}

#----------------------------------------
#### all done
1; # success always
# EOF
