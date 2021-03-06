@perl -Sx %0 %*
@goto :eof
#!perl

use File::Temp qw/ :mktemp  /;

sub usage {

print <<EOM;

Usage: getlanguage -f list.txt | getlanguage2stat > stat.txt

Calculates statistics from the getlanguage output. Generates
several files.

  --prefix=<pref> - <pref> is used as a prefix to all output
    file names, list is used by default

EOM

}


$prefix = "list";

while (0 < 1 + $#ARGV) {

    if("--help" eq $ARGV [0]) {

        usage ();
        exit (0);

    } elsif ($ARGV [0] =~ /^--prefix=(.+)/) {

        $prefix = $1;

    } else {

      last;
    }
    shift @ARGV;
}


$proc1 = <<'EOF';

$[ = 1;
$\ = "\n";

while(<>) {

    s/[\r\n]+$//;
    s/^\xEF\xBB\xBF//;

    if(/^(.*)[\t]([^\t]+)$/) {
      printf "%s\t%3.4f\n", $1, (100.0 * $2) ;
    } else {
      print "$_\n";
    }
}

EOF

($fh, $tmp1) = mkstemp ("fa_build_w2t_prob_XXXXXXXX");
print $fh $proc1;
close $fh;



$SIG{PIPE} = sub { die "ERROR: Broken pipe at fa_wtbt2bws" };

#
# WTBT -> BW
#

$[ = 1;
$\ = "\n";

while (<>) {

    s/[\r\n]+$//;
    s/^\xEF\xBB\xBF//;

    @Fld = split("\t", $_, 9999);

    if (7 <= $#Fld) {

      if($Fld[1] =~ /^(?:[^.]+[\/\\])?([^.\/\\]+)[.]([^\/\\]+)[\/\\][^\/\\]+$/) {

        $lang = $1;
        $corp_lang = $1 . "." . $2 ;

        $lang1 = $Fld[2];
        $enc1 = $Fld[3];
        $err1 = $Fld[4];

        $lang2 = $Fld[5];
        $enc2 = $Fld[6];
        $err2 = $Fld[7];

        $map_lang1{"$lang\t$lang1"} = 1 + $map_lang1{"$lang\t$lang1"};
        $map_lang2{"$lang\t$lang2"} = 1 + $map_lang2{"$lang\t$lang2"};

        $map_corp_lang1{"$corp_lang\t$lang1"} = 1 + $map_corp_lang1{"$corp_lang\t$lang1"};
        $map_corp_lang2{"$corp_lang\t$lang2"} = 1 + $map_corp_lang2{"$corp_lang\t$lang2"};

        if("0" eq $err1) {
          $map2_lang1{"$lang\t$lang1"} = 1 + $map2_lang1{"$lang\t$lang1"};
          $map2_corp_lang1{"$corp_lang\t$lang1"} = 1 + $map2_corp_lang1{"$corp_lang\t$lang1"};
        }

        if("0" eq $err2) {
          $map2_lang2{"$lang\t$lang2"} = 1 + $map2_lang2{"$lang\t$lang2"};
          $map2_corp_lang2{"$corp_lang\t$lang2"} = 1 + $map2_corp_lang2{"$corp_lang\t$lang2"};
        }

        if("0" ne $err1) {
          $failed_lang{$lang} = 1 + $failed_lang{$lang};
        }

        if("0" ne $err1) {
          $failed_corp_lang{$corp_lang} = 1 + $failed_corp_lang{$corp_lang};
        }

      } else {

        print STDERR "Bad directory structure: $Fld[1]\n";
      }
    }
}


#
# All the results
#

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.lang.txt" ;
foreach $k (keys %map_lang1) {
  print OUTPUT "$k\t$map_lang1{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.altlang.txt" ;
foreach $k (keys %map_lang2) {
  print OUTPUT "$k\t$map_lang2{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.lang.corp.txt" ;
foreach $k (keys %map_corp_lang1) {
  print OUTPUT "$k\t$map_corp_lang1{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.altlang.corp.txt" ;
foreach $k (keys %map_corp_lang2) {
  print OUTPUT "$k\t$map_corp_lang2{$k}";
}
close OUTPUT ;



#
# Just counts
#

open OUTPUT, "| fa_merge_stat > $prefix.lang.count.txt" ;
foreach $k (keys %map_lang1) {
  print OUTPUT "$k\t$map_lang1{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat > $prefix.rev.lang.count.txt" ;
foreach $k (keys %map_lang1) {
  @Fld = split("\t", $k, 9999);
  print OUTPUT "$Fld[2]\t$Fld[1]\t$map_lang1{$k}";
}
close OUTPUT ;




#
# Reverse results
#

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.rev.lang.txt" ;
foreach $k (keys %map_lang1) {
  @Fld = split("\t", $k, 9999);
  print OUTPUT "$Fld[2]\t$Fld[1]\t$map_lang1{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.rev.altlang.txt" ;
foreach $k (keys %map_lang2) {
  @Fld = split("\t", $k, 9999);
  print OUTPUT "$Fld[2]\t$Fld[1]\t$map_lang2{$k}";
}
close OUTPUT ;


#
# No error results
#

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.noe.lang.txt" ;
foreach $k (keys %map2_lang1) {
  print OUTPUT "$k\t$map2_lang1{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.noe.altlang.txt" ;
foreach $k (keys %map2_lang2) {
  print OUTPUT "$k\t$map2_lang2{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.noe.lang.corp.txt" ;
foreach $k (keys %map2_corp_lang1) {
  print OUTPUT "$k\t$map2_corp_lang1{$k}";
}
close OUTPUT ;

open OUTPUT, "| fa_merge_stat | fa_count2prob | perl $tmp1 > $prefix.noe.altlang.corp.txt" ;
foreach $k (keys %map2_corp_lang2) {
  print OUTPUT "$k\t$map2_corp_lang2{$k}";
}
close OUTPUT ;


#
# Times failed
#

open OUTPUT, "> $prefix.failed.lang.txt" ;
foreach $k (keys %failed_lang) {
  print OUTPUT "$k\t$failed_lang{$k}";
}
close OUTPUT ;

open OUTPUT, "> $prefix.failed.lang.corp.txt" ;
foreach $k (keys %failed_corp_lang) {
  print OUTPUT "$k\t$failed_corp_lang{$k}";
}
close OUTPUT ;


#
# delete temporary files
#

END {
    if ($tmp1 && -e $tmp1) {
        unlink ($tmp1);
    }
}
