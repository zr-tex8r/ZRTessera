# ZRCMapOut.pm
#

#### start package
package ZRCMapOut;
use strict qw( refs vars subs );
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = ();
our @EXPORT_OK = qw(
  cmap_generate cmap_last_error
);
our %EXPORT_TAGS = (
  all => [@EXPORT_OK]
);
our $VERSION = 0.001_00;

#### procedure definitions

##------ 'cmap_last_error'

##<*> cmap_last_error()
# Returns the message of error that occurred last.
our ($last_error);
sub cmap_last_error {
  return $last_error;
}
sub error {
  $last_error = join(': ', @_); return;
}

##------ 'cmap_generate'

##<*> cmap_generate($param)
# Returns the text of CMap file that is generated from the
# parameters stored in $param, which is a ref-to-hash that
# has the following valid keys:
#   collection     target glyph collection, eg 'Adobe-Japan1-6'
#   name           CMap name, eg 'Foo-Bar-H'
#   version        version (as string), eg '1.003'
#   codespace      codespace definition
#   notdef         notdefrange mapping
#   map            cidrange mapping
#   vertical       whether this CMap is a vertical one inherited
#                  from the corresponding horizontal CMap (boolean)
#   wmode          WMode value, usually not needed since it can be
#                  inferred from 'vertical' value
# A codespace definition is given as a ref-to-array, such as:
#   [["\x20", "\x20"], ["\x21\x21", "\x7e\x7e"]]
# A mapping from source codevalue to CID is given either as a
# ref-to-hash where a codevalue is given as number, such as:
#   { 0x2121 => 100, 0x2122 => 101, 0x5555 => 200 }
# or as a ref-to-array where a codevalue is given as string, such as:
#   [["\x21\x21", 100], ["\x20", 50]]
# Note, however, that the ref-to-hash form is available only when all
# codevalues in the codespace specified have the same byte length.
# (For example, ref-to-hash cannot be used for the codespace shown
# above as example, since the codespace has both one- and two-byte
# codevalues.)
sub cmap_generate {
  my ($inpar) = @_;
  my $par = recollect($inpar) or return;
  set_uc_hex(1);
  my ($csp, $len) = compose_codespace($par->{codespace})
    or return;
  set_code_len((defined $len) ? $len : $par->{codelength});
  set_uc_hex(0);
  my $ndf = compose_notdef($par->{notdef}) or return;
  my $map = compose_map($par->{map}) or return;
  my $t = join("\n", prologue($par), iden($csp), iden($ndf),
            iden($map), epilogue($par));
  return $t;
}

use constant { EMPTY => "\t" };
sub iden { return ($_[0] ne EMPTY) ? ($_[0]) : (); }

our ($code_len);
sub set_code_len { $code_len = $_[0]; }

sub recollect {
  my ($inpar) = @_;
  my @keys = qw(name collection version);
  if (!$inpar->{vertical}) { push(@keys, "codespace"); }
  foreach (@keys) {
    ($inpar->{$_} ne '') or return error("missing parameter", $_);
  }
  # clone
  my $par; %$par = %$inpar;
  # collection
  my @coll = split(m/-/, $par->{collection});
  ($#coll == 2 && $coll[2] =~ m/^\d+$/)
    or return error("invalid collection spec", $par->{collection});
  $par->{collarray} = \@coll;
  # wmode, vertical
  ($par->{wmode} =~ m/^\d+$/)
    or $par->{wmode} = ($par->{wmode}) ? 1 : 0;
  if ($par->{vertical}) {
    ($par->{wmode}) or $par->{wmode} = 1;
    if (!$par->{sourcecmap}) {
      my $t = $par->{name};
      if ($t =~ s/-V$/-H/) {
        $par->{sourcecmap} = $t;
      } else {
        return error("name of vertical CMap must end with '-V'");
      }
    }
  }
  return $par;
}

sub compose_codespace {
  my ($list) = @_;
  my ($ent, @list2, @key, %len);
  (defined $list) or return EMPTY;
  foreach $ent (@$list) {
    ($#$ent == 1)
      or return error("codespace spec is broken");
    push(@list2, [ map {
      $len{length($_)} = 1; \$_
    } (@{$ent}[0, 1]) ]);
  }
  @key = keys %len;
  ($#key == 0) or @key = ();
  return (compose_list(\@list2, "codespacerange"), $key[0]);
}

sub compose_notdef {
  my ($map) = @_;
  (defined $map) or return EMPTY;
  my $bto = -1;
  my ($bfrom, $sfrom, $efrom, @dat);
  $map = convert_map($map); push(@$map, ["", -1]);
  foreach my $ent (@$map) {
    my ($from, $to) = @$ent;
    ($to >= 0) or $to = 0;
    if ($to == $bto && successive($bfrom, $efrom, $from)) {
      $efrom = substr($from, -1);
    } else {
      if ($bto >= 0) {
        push(@dat, [ \"$bfrom$sfrom", \"$bfrom$efrom", $bto ]);
      }
      $bfrom = substr($from, 0, -1); $bto = $to;
      $sfrom = $efrom = substr($from, -1);
    }
  }
  return compose_list(\@dat, "notdefrange");
}

sub compose_map {
  my ($map) = @_;
  (defined $map) or return EMPTY;
  my ($bfrom, $sfrom, $efrom, @dat);
  my ($sto, $eto) = (-2, -2);
  $map = convert_map($map); push(@$map, ["", -1]);
  foreach my $ent (@$map) {
    my ($from, $to) = @$ent;
    ($to >= 0) or $to = 0;
    if ($eto + 1 == $to && successive($bfrom, $efrom, $from)) {
      $efrom = substr($from, -1); $eto = $to;
    } else {
      if ($sto >= 0) {
        push(@dat, [ \"$bfrom$sfrom", \"$bfrom$efrom", $sto ]);
      }
      $bfrom = substr($from, 0, -1); $sto = $eto = $to;
      $sfrom = $efrom = substr($from, -1);
    }
  }
  return compose_list(\@dat, "cidrange");
}

sub successive {
  my ($bfrom, $efrom, $from) = @_;
  return ($from ne '' && $bfrom eq substr($from, 0, -1) &&
          ord($efrom) + 1 == ord(substr($from, -1)));
}

sub prologue {
  my ($par) = (@_); my ($usecmap);
  if ($par->{vertical}) {
    $usecmap = "\n/@{[ $par->{sourcecmap} ]} usecmap\n";
  }
  return <<"END";
%!PS-Adobe-3.0 Resource-CMap
%%DocumentNeededResources: ProcSet (CIDInit)
%%IncludeResource: ProcSet (CIDInit)
%%BeginResource: CMap (@{[ $par->{name} ]})
%%Title: (@{[ $par->{name}, @{$par->{collarray}} ]})
%%Version: @{[ $par->{version} ]}
%%EndComments

/CIDInit /ProcSet findresource begin

12 dict begin

begincmap
$usecmap
/CIDSystemInfo 3 dict dup begin
  /Registry (@{[ $par->{collarray}[0] ]}) def
  /Ordering (@{[ $par->{collarray}[1] ]}) def
  /Supplement @{[ $par->{collarray}[2] ]} def
end def

/CMapName /@{[ $par->{name} ]} def

/CMapVersion @{[ $par->{version} ]} def
/CMapType 1 def

/WMode @{[ $par->{wmode} ]} def
END
}

sub epilogue {
  return <<"END";
endcmap
CMapName currentdict /CMap defineresource pop
end
end

%%EndResource
%%EOF
END
}


##------ subprocedures

our ($uc_hex);
sub set_uc_hex { $uc_hex = $_[0]; }

sub compose_list {
  my ($list, $ssym, $esym) = @_;
  my @cnks;
  if (!defined $esym) {
    ($ssym, $esym) = ("begin$ssym", "end$ssym");
  }
  for (my $idx = 0; $idx <= $#$list; $idx += 100) {
    my $t = $idx + 99;
    if ($t > $#$list) { $t = $#$list; }
    $t = [@{$list}[$idx .. $t]];
    push(@cnks, compose_list_sub($t, $ssym, $esym));
  }
  return join("\n", @cnks);
}

sub compose_list_sub {
  my ($list, $ssym, $esym) = @_;
  my @cnks = (undef);
  foreach my $ent (@$list) {
    my @ar = map { psexpr($_) } (@$ent);
    push(@cnks, "  @ar\n");
  }
  $cnks[0] = "@{[scalar(@$list)]} $ssym\n";
  push(@cnks, "$esym\n");
  return join('', @cnks);
}

sub psexpr {
  my ($val) = @_;
  if (ref $val eq 'SCALAR') {
    my $t = unpack('H*', $$val);
    if ($uc_hex) { $t = uc($t); }
    return "<$t>";
  } else {
    return $val;
  }
}

sub convert_map {
  my ($map) = @_; my (@ar);
  if (ref $map eq 'HASH') {
    my $pos = 4 - $code_len;
    foreach my $key (keys %$map) {
      my $from = substr(pack("N", $key), $pos);
      push(@ar, [$from, $map->{$key}]);
    }
  } elsif (ref $map eq 'ARRAY') {
    @ar = @$map;
  } else {
    return error("map is in unknown format");
  }
  @ar = sort { $a->[0] cmp $b->[0] } (@ar);
  return \@ar;
}

##--------------------------------------
1;
# EOF
