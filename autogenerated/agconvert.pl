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

our $stdencoding = "iso-8859-1";

my $helptext = "Usage: agconvert.pl <theme> <input fileprefix> <output file>\n\n";

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
	
	if (-e $file) {
          my $rt = `file -i $file`;
          if ($rt =~ m/charset\=us\-ascii/s ) {
          } else {
            if ($rt =~ m/charset\=$stdencoding/s ) {
            } else {
              logMessage($CLIENTWARN, "File $file has wrong encoding (should be $stdencoding or ASCII)");
            }
          }
        } else {
          logMessage($FATALERROR, "File $file does not exist");
        }
	
	my $text = "";
	if (open(F, $file)) {
	  logMessage($VERBOSEINFO, "Reading file $file");
	} else {
	  logMessage($FATALERROR, "Could not open file $file for reading");
	}
	my $n = 0;
	my $r = "";
	while(defined($r = <F>)) {
	  $text .= $r;
	  $n++;
	}
	close(F);
	logMessage($VERBOSEINFO, "Read $n lines resp. " . length($text) . " characters from file $file (encoding: $stdencoding)");
	return decode($stdencoding, $text);
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
	my $code = encode($stdencoding, $text); 
	
	print F $code;
	close(F);
	
	logMessage($VERBOSEINFO, "Written " . length($text) . " characters to file $file (encoding: $stdencoding)");
}

# ----------------------------- Die Parser -----------------------------------------------------------------------

sub parse_general {
  my $text = $_[0];

  if ($text =~ s/(.+)\\begin{MAufgabe}/\\begin{MAufgabe}/sg ) {
    logMessage($VERBOSEINFO, "Removed generated content outside MAufgabe environment");
  }
  
  if ($text =~ s/\\begin{MAufgabe}{(.+?)}{(.*?)}(.+)\\end{MAufgabe}/\\begin{MExercise}$3\\end{MExercise}\n/s ) {
    logMessage($VERBOSEINFO, "Converting exercise \"" . $1 . "\" (authors: " . $2 . ")");
  } else {
    logMessage($CLIENTERROR, "Could not convert MAufgabe to MExercise");
  }
  
  if ($text =~ s/\\,/ /gs ) {
    logMessage($VERBOSEINFO, "\\, replaced by normal space");
  }
  
  if ($text =~ s/\\MDS/\\displaystyle/gs ) {
    logMessage($VERBOSEINFO, "\\MDS replaced by displaystyle");
  }

  return $text;
}

sub parse_fractions {
  my $text = $_[0];

  logMessage($VERBOSEINFO, "Parser for exercise theme 'fractions' selected");
  

  my $inputfield = "";
  
  if ($text =~ s/\\ifLsg\\MLoesung(.+?)\\else\\relax\\fi/\\begin{MHint}{L\\"osung}$1\\end{MHint}/s ) {
    my $sol = $1;
    if ($sol =~ m/(.*)\\frac{(.+?)}{(.+?)}(.*?)/s ) {
      my $term = "($2)/($3)";
      $term =~ s/\ //gs ; 
      $term =~ s/(\d+)([abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]+)/$1\*$2/gs ;
      logMessage($VERBOSEINFO, "Converting solution text, solution check term is $term");
      
      my @vars = ();
      while ($term =~ m/([abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ])/g ) {
        my $letter = $1;
        my $found = 0;
        for (my $i = 0; $i <= $#vars; $i++) {
          if ($vars[$i] eq $letter) {
            $found = 1;
          }
        }
        if ($found eq 0) {
          push @vars, $letter;
          logMessage($VERBOSEINFO, "...$letter added as a variable");
        }
      }
      
      my $varstring = "";
      for (my $i = 0; $i <= $#vars; $i++) {
        if ($i > 0) {
          $varstring .= ",";
        }
        $varstring .= $vars[$i];
      }
      my $size = 5 + length($term) * 2;
      $inputfield = "\\MLSimplifyQuestion{$size}{$term}{5}{$varstring}{5}{528}{AUTOGENERATED}"; # Besondere Stuetzstellen und hoechstens ein / erlaubt
    } else {
      logMessage($CLIENTWARN, "Could convert solution, but could not find solution term");
    }
  } else {
    logMessage($CLIENTERROR, "Could not convert solution");
  }

  if ($text =~ s/\\quad \$(.+?)\$\./\\[$1\\:\.\\]/s ) {
    logMessage($VERBOSEINFO, "\\quad \$...\$ replaced my math equation");
  } else {
    logMessage($CLIENTWARN, "Probably unkown solution style structure");
  }
  
  
  if ($inputfield eq "") {
    $inputfield = "?";
  }
  if ($text =~ s/K\\"urzen Sie soweit m\\"oglich: \$(.+?)\$./K\"urzen Sie soweit m\"oglich: \\MEquationItem{\$\\displaystyle $1\$}{$inputfield}\\: ./s ) {
    logMessage($VERBOSEINFO, "Generating exercise input element");
  } else {
    logMessage($CLIENTERROR, "Could not generate input element");
  }
  
  $text =~ s/\((\d+)\)/$1/sg ;
  
  return $text;
}

sub parse_abseq {
  my $text = $_[0];

  logMessage($VERBOSEINFO, "Parser for exercise theme 'absolute value equations' selected");

  if ($text =~ s/\\ifLsg\\MLoesung(.+?)\\else\\relax\\fi/\\begin{MHint}{L\\"osung}$1\\end{MHint}/s ) {
    logMessage($VERBOSEINFO, "MLoesung found and replaced by MHint");
    
    if ($text =~ s/\\includegraphics\[(.+?)\]{(.+?)}/\\MUGraphicsSolo{$2}{$1}{width:700px}\n/s ) {
      logMessage($CLIENTINFO, "Image found: $2, should be converted to transparent and copied manually!");
    } else {
      logMessage($CLIENTWARN, "No image found in solution");
    }
    

    if ($text =~ s/\$\$\n(.+?)\$\$/\$$1\$/s ) {
      logMessage($VERBOSEINFO, "Introductory paragraph equation smallified");
    }
    
    if ($text =~ s/\\begin{align\*}(.+?)\= (.+?)\\\\[ \n]*\\Leftrightarrow(.+?)\= (.+?)\\end{align\*}/\$\$\n$1\\;=\\;$2\\;\\;\\Leftrightarrow\\;\\;$3\\;=\\;$4\$\$/sg ) {
      logMessage($VERBOSEINFO, "Align environment replaced");
    }
    
    if ($text =~ s/\\frac{/\\Mtfrac{/sg ) {
      logMessage($VERBOSEINFO, "Fractions displayed in small variant");
    }

    if ($text =~ s/\\begin{cases}(.+?)\\\\(.+?)\\end{cases}/($1\\;\\text{und}\\;$2)\\;/sg ) {
      logMessage($VERBOSEINFO, "cases-environments displaying conjunctions replaced");
    }

    
  } else {
    logMessage($CLIENTERROR, "Could not convert solution");
  }

  
  return $text;
}

sub parse_curve {
  my $text = $_[0];

  logMessage($VERBOSEINFO, "Parser for exercise theme 'curve analysis' selected");

  if ($text =~ s/\\ifLsg\\Loesung(.+?)\\else\\relax\\fi/\\begin{MHint}{L\\"osung}$1\\end{MHint}/s ) {
    logMessage($VERBOSEINFO, "MLoesung found and replaced by MHint");
    
    if ($text =~ s/\\includegraphics\[(.+?)\]{(.+?)}/\\MUGraphicsSolo{$2}{$1}{width:700px}\n/s ) {
      logMessage($CLIENTINFO, "Image found: $2, should be converted to transparent and copied manually!");
    } else {
      logMessage($CLIENTWARN, "No image found in solution");
    }
    

    if ($text =~ s/\$\$\n(.+?)\$\$/\$$1\$/s ) {
      logMessage($VERBOSEINFO, "Introductory paragraph equation smallified");
    }
    
    if ($text =~ s/\\begin{align\*}(.+?)\= (.+?)\\\\[ \n]*\\Leftrightarrow(.+?)\= (.+?)\\end{align\*}/\$\$\n$1\\;=\\;$2\\;\\;\\Leftrightarrow\\;\\;$3\\;=\\;$4\$\$/sg ) {
      logMessage($VERBOSEINFO, "Align environment replaced");
    }
    
    if ($text =~ s/\\frac{/\\Mtfrac{/sg ) {
      logMessage($VERBOSEINFO, "Fractions displayd in small variant");
    }

    if ($text =~ s/\\begin{cases}(.+?)\\\\(.+?)\\end{cases}/($1\\;\\text{und}\\;$2)\\;/sg ) {
      logMessage($VERBOSEINFO, "cases-environments displaying conjunctions replaced");
    }

    
  } else {
    logMessage($CLIENTERROR, "Could not convert solution");
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

if ($#ARGV eq 2) {
  my $extype = $ARGV[0]; # Uebernommen aus den Themennummern der MATeX-Generatoren
  my $sourceprefix = $ARGV[1];
  my $targetfile = $ARGV[2];

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
    
    $atext = parse_general($atext);
    
    if ($extype eq 10) { $text .= parse_fractions($atext); }
    if ($extype eq 11) { $text .= parse_curve($atext); }
    if ($extype eq 12) { $text .= parse_abseq($atext); }
    
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
