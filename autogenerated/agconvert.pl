#!/usr/bin/env perl

use strict;
use warnings;

#
#  agonvert.pl
#  Autor: Daniel Haase, 2016
#  daniel.haase@kit.edu
#  encoding: utf-8

use File::Copy;
use File::Slurp;
use File::Path;  #mkpath($path);
use Cwd;
use Encode;
use Term::ANSIColor;

our $enc = "iso-8859-1";

my $helptext = "Usage: agconvert.pl <input fileprefix> <output file>\n\n";

our $doverbose = 1;
our $consolecolors = 1;

our $mainlogfile = "conversion.log";
our $starttime;

our $CLIENTINFO = "1";
our $CLIENTERROR = "2";
our $CLIENTWARN = "3";
our $DEBUGINFO = "4";
our $VERBOSEINFO = "5";
our $CLIENTONLY = "6";
our $FATALERROR = "7";

our $GRAYBASHCOLOR = "\037[0;31m";
our $REDBASHCOLOR = "\033[0;31m";
our $NOBASHCOLOR = "\033[0m";


# ----------------------------- Funktionen -----------------------------------------------------------------------

# Separate Ausgabe: Farbcodiert fuer die Konsole falls gewuenscht und nur-Text fuer logfile
# Parameter color = string, txt = string (ohne Zeilenumbruch)
sub printMessage {
  my ($color, $txt) = @_;

  # gruene verbose-Meldungen nur in Logdatei, nicht auf Konsole ausser wenn aktiviert
  if (($color ne "green") or ($doverbose eq 1)) {
    if ($consolecolors eq 1) {
      print color($color), "$txt\n", color("reset");
    } else {
      print "$txt\n";
    }
  }
  print LOGFILE "$txt\n";
}

# Parameter lvl = loglevel, eine der obigen Konstanten, msg = textstring (die Meldung)
sub logMessage {
  my ($lvl, $msg) = @_;
  
  # Konvertierung findet auf Server statt, nicht auf Client, also wird alles Serverrelevante sofort ausgegeben
  if ($lvl eq $CLIENTINFO) {
    printMessage("black", "INFO:    $msg");
  } else {
    if ($lvl eq $CLIENTERROR) {
      printMessage("red", "ERROR:   $msg");
    } else {
      if ($lvl eq $CLIENTWARN) {
        printMessage("red", "WARNING: $msg");
      } else {
        if ($lvl eq $DEBUGINFO) {
          # release oder nicht macht fuer Serverseite keinen Sinn, also zaehlt doverbose
          printMessage("green", "DEBUG:   $msg");
        } else {
          if ($lvl eq $VERBOSEINFO) {
            printMessage("green", "VERBOSE: $msg");
          } else {
            if ($lvl eq $CLIENTONLY) {
              # Auf Serverseite keine Ausgabe
            } else {
              if ($lvl eq $FATALERROR) {
                printMessage("red", "FATAL ERROR: $msg");
                close(LOGFILE);
                die("Program aborted");
              } else {
                printMessage("red", "ERROR: Wrong error type $lvl, message: $msg");
              }
            }
          }
        }
      }
    }
  }
}

sub logTimestamp {
  my ($txt) = @_;
  
  my $time2 = time;
  my $diff = $time2 - $starttime;
  logMessage($CLIENTINFO, "$txt: $diff seconds.");
}


sub injectEscapes {
  my $str = $_[0];
  $str =~ s/\\/\\\\/gs ; # muss vor den anderen Ersetzungen kommen!
  $str =~ s/\"/\\\"/gs ;
  $str =~ s/\'/\\\'/gs ;
  $str =~ s/\r/\\r/gs ;
  $str =~ s/\n/\\n/gs ;
  return $str;
}

sub readfile {
	my $file = $_[0];
	my $text = "";
	if (open(F, $file)) {
	  logMessage($VERBOSEINFO, "Reading file $file");
	} else {
	  logMessage($FATALERROR, "Could not open file $file");
	}
	my $n = 0;
	my $r = "";
	while(defined($r = <F>)) {
	  $text .= $r;
	  $n++;
	}
	close(F);
	logMessage($VERBOSEINFO, "Read $n lines resp. " . length($text) . " characters from file $file (encoding: $enc)");
	return decode($enc, $text);
}


sub writefile {
	my $file = $_[0];
	my $text = $_[1];
  	my $path;
	if ($file =~ /(.*)\/[^\/]*?$/ ) {
	  $path = $1;
	} else {
	  $path = ".";
	}
	if ($path ne ".") {
  	  logMessage($VERBOSEINFO, "Creating path $path");
	  mkpath($path);
	}
	if (open(F, "> $file")) {
	  logMessage($VERBOSEINFO, "Writing to file $file");
	} else {
	  logMessage($FATALERROR, "Cannot create/overwrite file $file in path $path");
	}
	my $code = encode($enc, $text); 
	
	print F $code;
	close(F);
	
	logMessage($VERBOSEINFO, "Written " . length($text) . " characters to file $file (encoding: $enc)");
}

# ----------------------------- Der Parser -----------------------------------------------------------------------


# \begin{MAufgabe}{Kuerzen}{kr, MaTeX}
# K\"urzen Sie soweit m\"oglich: $\frac{42}{105}$.\\ 
# \ifLsg\MLoesung
# \quad $\frac{42}{105}=\frac{(21)\cdot(2)}{(21)\cdot(5)}=\frac{2}{5}$.\else\relax\fi
#  \end{MAufgabe}



sub parse {
  my $text = $_[0];

  if ($text =~ s/\\begin{MAufgabe}{(.+?)}{(.*?)}(.+)\\end{MAufgabe}/\\begin{MExercise}$3\\end{MExercise}\n/s ) {
    logMessage($VERBOSEINFO, "Converting exercise \"" . $1 . "\" (authors: " . $2 . ")");
  } else {
    logMessage($CLIENTERROR, "Could not convert MAufgabe to MExercise");
  }
  
  if ($text =~ s/\\ifLsg\\MLoesung(.+?)\\else\\relax\\fi/\\begin{MHint}{L\\"osung}$1\\end{MHint}/s ) {
    logMessage($VERBOSEINFO, "Converting solution");
  } else {
    logMessage($CLIENTERROR, "Could not convert solution");
  }
  
  if ($text =~ s/K\\"urzen Sie soweit m\\"oglich: \$(.+?)\$./K\"urzen Sie soweit m\"oglich: \\MEquationItem{\$\\displaystyle $1\$}{???}\\: ./s ) {
    logMessage($VERBOSEINFO, "Generating exercise input element");
  } else {
    logMessage($CLIENTERROR, "Could not generate input element");
  }
  
  return $text;
}


# ----------------------------- Start Hauptprogramm --------------------------------------------------------------

# my $IncludeTags = ""; # Sammelt die Makros fuer predefinierte Tagmakros, diese werden an mintmod.tex angehaengt

# Logfile als erstes einrichten, auf der Ebene des Aufrufs
open(LOGFILE, "> $mainlogfile") or die("ERROR: Cannot open log file, aborting!");


#Zeit speichern und Startzeit anzeigen
$starttime = time;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
logMessage($CLIENTINFO, "Starting conversion: " . ($year+1900 ) . "-" . ($mon+1) . "-$mday at $hour:$min:$sec");


my $i = 1;

if ($#ARGV eq 1) {
  my $sourceprefix = $ARGV[0];
  my $targetfile = $ARGV[1];

  logMessage($CLIENTINFO, "Collection files having prefix $sourceprefix");
  
  my $text = "";
  my $sourcefile = "$sourceprefix$i.tex";
  logMessage($VERBOSEINFO, "Checking source file $sourcefile");
  while(-e $sourcefile) {
    my $rt = `file -i $sourcefile`;
    if ($rt =~ m/charset\=us\-ascii/s ) {
      logMessage($VERBOSEINFO, "Source file $sourcefile (encoding: ASCII, ok)");
    } else {
      if ($rt =~ m/charset\=iso\-8859\-1/s ) {
        logMessage($VERBOSEINFO, "Source file $sourcefile (encoding: latin1, ok)");
      } else {
        logMessage($FATALERROR, "Source file $sourcefile not found or wrong encoding (should be latin1)");
      }
    }
  
    my $atext = readfile($sourcefile);
    $text .= parse($atext);
    $i++;
    $sourcefile = "$sourceprefix$i.tex";
  }
  writefile($targetfile, $text);
} else {
  print $helptext;
  logMessage($FATALERROR, "Invalid number of arguments");
}

$i--;
logTimestamp("agconvert.pl finished successfully, $i files have been collected");
close(LOGFILE);

exit;
