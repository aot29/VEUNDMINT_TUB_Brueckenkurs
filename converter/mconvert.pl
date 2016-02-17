#!/usr/bin/env perl

use strict;
use warnings;

#
#  mconvert.pl
#  Autor: Daniel Haase, 2014
#  daniel.haase@kit.edu
#
use File::Copy;
use File::Slurp;
use File::Path;  #mkpath($path);
use Storable 'dclone';
use POSIX qw(strftime);
use Net::Domain qw (hostname hostfqdn hostdomain);
use MIME::Base64 qw(encode_base64);
use Cwd;
use Switch;
use JSON::XS;
use Term::ANSIColor;
use GraphViz;
use Encode;

use converter::File::Data;

my $helptext = "Usage: mconvert.pl <configuration.pl> [<parameter>=<value> ...]\n\n";

# use lib "/home/daniel/BWSYNC/PreTU9Konverter/converter";
# use courseconfig;

our $mainlogfile = "conversion.log";

# --------------------------------- Parameter zur Erstellung des Modulpakets ----------------------------------

our $macrofilename = "mintmod";
our $macrofile = "$macrofilename.tex"; # Relativ zum converter/tex Verzeichnis

# Mandatory option parameter in config file
our @mandatory = ("signature_main", "signature_version", "signature_localization",
   "reply_mail", "data_server", "exercise_server", "feedback_service", "data_server_description", "data_server_user",
   "footer_middle", "footer_right", "mainlogo", "do_feedback", "do_export");

our %config = ();       
our $mconfigfile = "";       # Konfigurationsdatei (mit Pfad relativ vom Aufruf aus)
our $basis = "";             # Das Verzeichnis, in dem converter liegt (wird momentan auf aktuelles Verzeichnis gesetzt)
our $rfilename = "";         # Filename of main tex file including path relative to execution directory
our $zip = "";               # Filename of zip file (if neccessary)

our @IncludeStorage = ();
our @DirectHTML = ();

# stellt das Verhalten des Menues im Header ein
# 0 bedeutet, dass Info die erste Seite eines Moduls ist
# 1 Info wird nach Aufgaben eingegliedert und aus der Vorwaerts-RÃ¼ckwÃ¤rtskonfig ausgeklammert
our $contentlevel = 4; # Level der subsubsections
our $XIDObj = -1;

our @LabelStorage; # Format jedes Eintrags: [ $lab, $sub, $sec, $ssec, $sssec, $anchor, $pl ]

our $PageIDCounter = 1;

# -------------------------------------------------------------------------------------------------------------

my @tominify = ("mintscripts.js", "servicescripts.js", "intersite.js", "convinfo.js", "userdata.js", "mparser.js", "dlog.js", "exercises.js");

# -------------------------------------------------------------------------------------------------------------

our $starttime; # Timestamp beim Start des Programms

my $breakoff = 0;
my $i;
my $ndir = ""; # wird am Programmstart gefuellt

my $copyrightcollection = "";

my $globalexstring = "";

our $entryfile = ""; # Die erste und nur einmal pro Session aktivierte Datei, startet in der Regel $startfile

# Redirects passend zu den Buttons
our $startfile = ""; # Wird vor Aufruf der Funktion createSCORM gesetzt durch StartTag, entryfile ebenso
our $chapterfile = "";
our $configfile = "";
our $datafile = "";
our $searchfile = "";
our $favofile = "";
our $locationfile = "";
our $stestfile = "";


# ----------------------------- Variablen fuer die Konvertierung -------------------------------------------------

# Diese Einstellungen haben keine Auswirkungen auf die produzierten Module, daher nicht in Parameterdatei
our $xmlfile = "converted.xml";
our $xmlerrormsg = "ttm_errors.txt";
our $UNKNOWN_UXID = "(unknown)";

our $doconctitles = 1; # =1 -> Titel der Vaterseiten werden mit denen der Unterseiten auf den Unterseiten kombiniert [war bei alten Onlinemodulen der Fall macht aber eigentlich keinen Sinn]

# Diese sind mittlerweile in intersite.js fest verdrahtet!
our $confsite = "config.html";
our $datasite = "cdata.html";
our $searchsite = "search.html";
our $chaptersite = "chapters.html";
our $startsite = "index.html";
our $favorsite = "favor.html";
our $stestsite = "stest.html";

our $locationsite = ""; # Wird aus Dokument geholt
our $locationlong = ""; # Wird aus Dokument geholt
our $locationshort = "";# Wird aus Dokument geholt
our $locationicon = "";# Wird aus Dokument geholt

our $paramsplitlevel = 3; # Maximales Level ab dem die Seiten getrennte HTML-Dateien sind

our $templatempl = ""; # wird von split::loadtemplates gefuellt

# our @feedbacktitles = ("Beschreibung/Aufgabenstellung ist unverständlich","Der Inhalt bzw. die Frage ist zu schwer","War genau richtig","Das ist mir zu leicht","Fehler in Modulelement melden");

our @sitepoints = ();
our @expoints = ();
our @testpoints = ();
our @sections = ();
our @uxids = ();
our @siteuxids = ();
our @colexports = (); # Wird vom postprocessing in split.pm gefuellt

our @converrors = (); # Array aus Strings

our $mainsiteline = 0;

our $randcharstr = "0123456789,.;abcxysqrt()/*+-";

# Globale Meldungsstufen (client-basiert in dlog.js)
# 1: CLIENTINFO   Wird als Feedback an Server geschickt, stellt eine Informationsmeldung dar
# 2: CLIENTERROR  Wird als Feedback an Server geschickt, stellt eine Fehlermeldung dar die behandelt werden muss, wird auch gesendet wenn Benutzer die USAGE abgeschaltet hat
# 3: CLIENTWARN   Wird als Feedback an Server geschickt, stellt eine interne Fehlermeldung dar die aber nicht gravierend ist
# 4: DEBUGINFO    Wird nur auf Browserkonsole ausgegeben, und nur falls es keine Releaseversion ist
# 5: VERBOSEINFO  Wird nur auf Browserkonsole ausgegeben, und nur falls es keine Releaseversion ist und verbose-flag aktiv ist
# 6: CLIENTONLY   Wird nur auf Browserkonsole ausgegeben, auch in Releases, und ohne Prefix
# 7: FATALERROR   Schwerwiegender Fehler, log-Funktion gibt ihn als die-Meldung aus
# Message wird nur in nicht-release-Versionen auf Clientkonsole ausgegeben

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
  if (($color ne "green") or ($config{doverbose} eq 1)) {
    if ($config{"consolecolors"} eq 1) {
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
  $str =~ s/\"/\\\"/gs ;
  $str =~ s/\r/\\r/gs ;
  $str =~ s/\n/\\n/gs ;
  return $str;
}

sub randomChar {
  my $r = int(rand(length($randcharstr)));
  return substr($randcharstr,$r,1);
}

# Parameter: String und Einheit modulo length
sub permuteString {
  my $str = $_[0];
  my $u = $_[1];
  my $n = length($str);
  my $t = "";
  
  my $i;
  for ($i = 0; $i < $n; $i++) {
    $t .= substr($str,($u*$i) % $n,1);
  }
 
  return $t;
}


# Parameter: Ziellaenge und zu borkifizierender String
sub borkString {
  my $lan = $_[0];
  my $str = $_[1];
  
  my $t = "";
  
  my $i;
  for ($i = 0; $i < $lan; $i++) {
    my $c;
    if ($i < length($str)) { $c = substr($str,$i,1); } else { $c = randomChar(); }
    $t .= $c;
  }
  
  my $u = (((5*$lan) - (3*length($str))) % $lan);
  while (gcd($u,$lan) ne 1) { $u = (($u + 1) % $lan);}
  
  my $t2 = permuteString($t, $u);
  return $t2;
}

sub gcd($$) {
  my ($u, $v) = @_;
  while ($v) {
    ($u, $v) = ($v, $u % $v);
  }
  return abs($u);
}

# Minimiert und obfuskiert alle JS-Dateien im aktuellen Verzeichnis (rekursiv!)
sub minimizeJS {
  my $fdi = 0;
  logMessage($CLIENTINFO, "Minimiere JS:");
  my $borknt = $#tominify + 1;
  logMessage($CLIENTINFO, "  $borknt js-Dateien vorgesehen");
  my $borkka;
  my $borkfilename = "";
  for ($borkka = 0; $borkka < $borknt; $borkka++) {
    $borkfilename = $tominify[$borkka];

    
    my $rt = `grep console.log $borkfilename`;
    if ($rt ne "") {
        logMessage($CLIENTINFO, "  JavaScript-Datei $borkfilename enthaelt console.log-Befehle, die durch logMessage zu ersetzen sind!");
    }
    
    my $borkcall = "file -i $borkfilename";
    $rt = `$borkcall`;
    my $domini = 0;
    logMessage($VERBOSEINFO, "  -> " . $borkfilename);
    if ($rt =~ m/charset\=us\-ascii/s ) {
      logMessage($VERBOSEINFO, " (ist ASCII-codiert)");
      $domini = 1;
    } else {
      $rt =~ m/charset\=(.+)\n/s ;
      logMessage($CLIENTINFO, " => Charset " . $1 . " ungeeignet, nur ASCII erlaubt, wird nicht minimiert!");
    }
    
    if ($domini eq 1) { 
      $borkcall = "java -jar $basis/converter/yuicompressor-2.4.8.jar $borkfilename -o $borkfilename";
      logMessage($CLIENTINFO, "  " . $borkcall);
      system($borkcall);
      $fdi++;
    }
  }
  
  logMessage($CLIENTINFO, "  $fdi Dateien minimiert");
}

# Borkifiziert alle HTML-Dateien im aktuellen Verzeichnis (rekursiv!)
sub borkifyHTML {

  my $fdi = 0;
  logMessage($VERBOSEINFO, "Borkifiziere HTML:");
  my $borkfilecount = 0;
  my $borkcall = "find -P . -name \\*.html";
  my $borktexlist = `$borkcall`; # Finde alle tex-Files, auch in den Unterverzeichnissen
  my @borktexs = split("\n",$borktexlist);
  my $borknt = $#borktexs + 1;
  logMessage($VERBOSEINFO,"  $borknt html-Dateien gefunden");
  my $borkka;
  my $borkfilename = "";
  for ($borkka = 0; $borkka < $borknt; $borkka++) {
    my $borkhtml = "";
    my $borktexzeile = "";
    $borkfilename = $borktexs[$borkka];
    $borkfilename =~ m/(.+)\/(.+?).html/i;
    my $borkdirname = $1;
    my $borktex_open = open(MINTS, "< $borkfilename") or die "  ERROR: Fehler beim Oeffnen von $borktexs[$borkka]\n";
    while(defined($borktexzeile = <MINTS>)) {
      $borkhtml .= $borktexzeile;
    }
    close(MINTS);
    $fdi++;
    
    
    # Borkifizierung
    my $lan = 32;
    my @st = ();
    my $GSLS = "__CQJ = CreateQuestionObj; function GSLS(c) \{\n  var str = \"\";\n";
    while ($borkhtml =~ s/\n*CreateQuestionObj\((\".*?\"),(\d+?),\"(.*?)\"/__CQJ\($1,$2,GSLS\($2\)/s ) {
      my $s = $3;
      push @st , [$2,$s,length($s)];
      if ($lan <= (2*length($s))) { $lan = 2*length($s) + 1; }
    }
    my $i;
    for ($i = 0; $i <= $#st; $i++) {
      my $b = borkString($lan, $st[$i][1]);
      $GSLS .= "if(c==" . $st[$i][0] . "){str=debork(\"$b\"," . $st[$i][2]. ");}";
    }
    
    $GSLS .= "return str;\}\n";
    $borkhtml =~ s/__CQJ/\n$GSLS\n__CQJ/s ;
    
    # Datei speichern
    $borktex_open = open(MINTS, "> $borktexs[$borkka]") or die "ERROR: Fehler beim Schreiben von $borktexs[$borkka]\n";
    print MINTS $borkhtml;
    close(MINTS);
  }
  
  logMessage($VERBOSEINFO, "  $fdi Dateien borkifiziert");

}


# Prueft, ob die zum Konvertieren notwendigen Systembestandteile vorhanden sind
sub checkSystem {
  # Pruefe ob dia installiert ist KANN AUSKOMMENTIERT WERDEN WENN DIA NICHT BENUTZT WERDEN SOLL
  my $reply = `dia --version 2>&1`;
  if ($reply =~ m/0\.97\.2/i ) {
    # dia erfolgreich getestet
  } else {
    logMessage($CLIENTWARN, "Program dia (version 0.97.2) not found, dia-compilation will not work");
  }

  # Pruefe ob perl installiert ist
  $reply = `perl -v  2>&1`;
  if ($reply =~ m/This is perl 5, version (.*?), subversion/i ) {
    if ($1 ge 10) {
      # Alles ok
  }   else
    {
      die("FATAL: perl version 5.10 is required, but found perl 5" . $1);
    }
  } else {
    die("FATAL: perl (at least version 5.10) is required");
  }

  # Pruefe ob ein JDK installiert ist
  $reply = `javac -version 2>&1`;
  if ($reply =~ m/javac (.+)/i ) {
    logMessage($CLIENTINFO, "JDK found, using javac from version $1");
  } else {
    die("FATAL: JDK not found");
  }
  
  # Pruefe ob php installiert ist
  $reply = `php --help 2>&1`;
  if ($reply =~ m/HTML/i ) {
    # php erfolgreich getestet
  } else {
    die("PHP (Version 5 inklusive PHP-curl) ist offenbar nicht installiert!\n");
  }
}


# Parameter: filename, redirect-url, scormclear
sub createRedirect {
  my $filename = $_[0];
  my $rurl = $_[1];
  my $scormclear = $_[2];

  my $indexhtmlscorm = <<ENDE;
<!DOCTYPE HTML>
<html lang="de-DE">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="refresh" content="1;url=$rurl">
        <script type="text/javascript">

        if (typeof(localStorage) !== "undefined") {
            localStorage.setItem("LOCALSCORM", "CLEARED");
        } else {
          localStoragePresent = false;
          var stor = window.localStorage;
          if (typeof(stor) !== "undefined") {
            logMessage(CLIENTERROR,"window.localStorage as stor found!");
            window.localStorage.setItem("LOCALSCORM", "CLEARED");
          }
        }
        window.location.href = "$rurl";
        </script>
        <title>Weiterleitung auf Hauptseite der Onlinemodule</title>
    </head>
    <body>
        Klicken Sie <a class="MINTERLINK" href="$rurl">hier</a>, falls Sie nicht automatisch weitergeleitet werden.
    </body>
</html>
ENDE
  
  my $indexhtml = <<ENDE;
<!DOCTYPE HTML>
<html lang="de-DE">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="refresh" content="1;url=$rurl">
        <script type="text/javascript">
        window.location.href = "$rurl";
        </script>
        <title>Weiterleitung auf Hauptseite der Onlinemodule</title>
    </head>
    <body>
        Klicken Sie <a class="MINTERLINK" href="$rurl">hier</a>, falls Sie nicht automatisch weitergeleitet werden.
    </body>
</html>
ENDE

  my $tempfile = open(MINTS, ">$ndir/$filename");
  if ($scormclear == 0) {
    print MINTS $indexhtml;
  } else {
    print MINTS $indexhtmlscorm;
  }
  close(MINTS);
  logMessage($CLIENTINFO, "Redirect auf $rurl in $filename erstellt");
}

sub createSCORM {
  # Stelle Dateireferenzen fuer Manifestdatei zusammen, iteriere dazu jede einzelne Datei im Baum
  logMessage($VERBOSEINFO, "Sammle Dateireferenzen fuer SCORM-Manifest, Startdatei ist $entryfile");
  my $mfiles = `find . -type f -exec echo \"      <file href=\\\"\"{}\"\\\" />\"  \\;`;

  my $mani2004rest = <<ENDE;
  xmlns = "http://www.imsglobal.org/xsd/imscp_v1p1"
                  xmlns:adlcp = "http://www.adlnet.org/xsd/adlcp_v1p3"
                  xmlns:adlseq = "http://www.adlnet.org/xsd/adlseq_v1p3"
                  xmlns:adlnav = "http://www.adlnet.org/xsd/adlnav_v1p3"
                  xmlns:imsss = "http://www.imsglobal.org/xsd/imsss"
                  xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
                  xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
                  xsi:schemaLocation = "http://www.imsglobal.org/xsd/imscp_v1p1 imscp_v1p1.xsd
                                       http://www.adlnet.org/xsd/adlcp_v1p3 adlcp_v1p3.xsd
                                       http://www.adlnet.org/xsd/adlseq_v1p3 adlseq_v1p3.xsd
                                       http://www.adlnet.org/xsd/adlnav_v1p3 adlnav_v1p3.xsd
                                       http://www.imsglobal.org/xsd/imsss imsss_v1p0.xsd
                                       http://ltsc.ieee.org/xsd/LOM lom.xsd" >
ENDE
  
  my $manifest_id = "Onlinemodule";
  my $manifest_version = "1.0";
  my $manifest_title = $config{description};
  my $manifest_comment = "Manifest template fuer VE&MINT-Onlinemodule (www.ve-und-mint.de) nach Spezifikation SCORM 2004 4th Edition bzw. 1.2, diese Datei wurde automatisch generiert.";

  
  my $manifest = <<ENDE;
<?xml version="1.0" standalone="no"?>
<!-- 
$manifest_comment
-->
<manifest identifier="$manifest_id" version="$manifest_version"

    xmlns="http://www.imsproject.org/xsd/imscp_rootv1p1p2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:adlcp="http://www.adlnet.org/xsd/adlcp_rootv1p2"
    xsi:schemaLocation="http://www.imsproject.org/xsd/imscp_rootv1p1p2imscp_rootv1p1p2.xsd http://www.imsglobal.org/xsd/imsmd_rootv1p2p1imsmd_rootv1p2p1.xsdhttp://www.adlnet.org/xsd/adlcp_rootv1p2 adlcp_rootv1p2.xsd"
    
  >

  <metadata>
    <schema>ADL SCORM</schema>
    <schemaversion>2004 4th Edition</schemaversion>
    <lom:lom>
      <lom:general>
        <lom:description>
          <lom:string language="en-US">Description</lom:string>
          <lom:string language="de-DE">Beschreibung</lom:string>
        </lom:description>
      </lom:general>
    </lom:lom>
  </metadata>
  <organizations default="B0">
    <organization identifier="B0" adlseq:objectivesGlobalToSystem="false">
      <title>$manifest_title</title>
      <item identifier="i1" identifierref="r1" isvisible="true">
        <title>$manifest_title</title>

 <imsss:sequencing>
<!-- other sequencing rules go here -->
<imsss:objectives>
<imsss:primaryObjective objectiveID="obj-primary" satisfiedByMeasure="false">
<imsss:mapInfo targetObjectiveID="obj-global-1" />
</imsss:primaryObjective>
<imsss:objective objectiveID="obj-local-1 " satisfiedByMeasure="false">
<imsss:mapInfo targetObjectiveID="obj-global-1" />
</imsss:objective>
</imsss:objectives>
</imsss:sequencing>

 
 
 
        </item>
    </organization>
  </organizations>
  <resources>
    <resource identifier="r1" type="webcontent" adlcp:scormType="sco" href="$entryfile"> 
    
$mfiles
    
    </resource>
  </resources>
</manifest>
ENDE


#        <imsss:primaryObjective objectiveID = "PRIMARYOBJ" satisfiedByMeasure="true">
#          <imsss:minNormalizedMeasure> 0.6 </imsss:minNormalizedMeasure>
#        </imsss:primaryObjective>


  logMessage($VERBOSEINFO, "Erstelle SCORM-Manifestdatei mit title=$manifest_title, version=$manifest_version und id=$manifest_id");
  
    # Erstelle Manifestdatei fuer SCORM
  my $scorm_open = open(MINTS, "> ./imsmanifest.xml") or die "Fehler beim Erstellen der Manifestdatei.\n";
  print MINTS "$manifest";
  close(MINTS); 
  
  logMessage($CLIENTINFO, "HTML-Baum wird als SCORM-Lernmodul Version 2004v4 eingerichtet");
}

# Checks if given parameter key is present and has a nonempty string as value
sub checkParameter {
  my $p = $_[0];
  if (exists $config{parameter}{$p}) {
    if ($config{parameter}{$p} eq "") {
      die("FATAL: Mandatory option parameter $p is an empty string");
    }
  } else {
    die("FATAL: Mandatory option parameter $p is missing");
  }
}

# Checks if options are present and consistent, quits with a fatal error otherwise
sub checkOptions {
  open(F,$config{source}) or die("FATAL: Cannot open source directory " . $config{source});
  close(F);

  if ($config{docollections} eq 1) {
    if (($config{nosols} eq 1) or ($config{qautoexport} eq 1) or ($config{cleanup} eq 1)) {
      die("FATAL: Option docollections is inconsistent with nosols, qautoexport and cleanup, deactivate one of them");
    }
  }

  if ($config{dorelease} eq 1) {
    if (($config{cleanup} eq 0) or ($config{docollections} eq 1) or ($config{doverbose} eq 1)) {
      die("FATAL: Option dorelease is inconsistent with cleanup=0, docollections=1 and doverbose=1, deactivate dorelease");
    }
  }

  if ($config{scormlogin} eq 1) {
    if ($config{doscorm} eq 0) {
      die("FATAL: Option scormlogin is inconsistent with doscorm=0, activate doscorm");
    }
  }

  $zip = ""; # Pfad+Name der zipdatei
  if ($config{dozip} eq 1) {
    if ($config{output} =~ m/(.+)\.zip/i) {
      $zip = $config{output};
      $config{output} = $1 . "DIRECTORY";
    } else {
      die("FATAL: zip-filename " . $config{output} . " not of type name.zip");
    }
  }
  
  # Check mandatory option parameters
  logMessage($CLIENTINFO, "Checking " . ($#mandatory+1) . " parameters ... ");
  my $a;
  for ($a = 0; $a <= $#mandatory; $a++) {
    checkParameter($mandatory[$a]);
  }
}

# sub createButtonFiles()
# Erzeugt png-Dateien fuer Buttonvariationen
# Parameter
#       $text           Originaldatei png (in converter/buttons_org)
#       $sat            Prozentzahl, um die Saettigung geaendert wird
#       $mod            Prozentzahl, um die Farbton moduliert wird
sub createButtonFiles {
   my ($file, $sat, $mod) = @_;

   # Normaler Button aber moduliert
   my $f = $file;
   $f =~ s/converter\/buttons_org/converter\/files\/images/ ;
   $f =~ s/.png/1.png/ ;
   system("convert -modulate 100,$sat,$mod $file $f"); 

   # Gedrueckter Button (gamma-Korrektur auf 5 gesetzt)
   $f = $file;
   $f =~ s/converter\/buttons_org/converter\/files\/images/ ;
   $f =~ s/.png/2.png/ ;
   system("convert -modulate 100,$sat,$mod -gamma 2 $file $f"); 
   
   # Gegrauter Button (Farbsaettigung entfernt, Modulation daher egal)
   $f = $file;
   $f =~ s/converter\/buttons_org/converter\/files\/images/ ;
   $f =~ s/.png/3.png/ ;
   system("convert -colorspace Gray $file $f"); 

}


# ----------------------------------- Konverterfunktionen -------------------------------------------------------------

sub generate_scriptheaders {
   my $itags = "";
   logMessage($VERBOSEINFO, "Using scriptheaders: ");
   my $i;
   for ($i = 0; $i <= $#{$config{scriptheaders}}; $i++) {
     my $cs = $config{scriptheaders}[$i];
     $itags = $itags . "<script src=\"$cs\" type=\"text/javascript\"></script>\n";
     logMessage($VERBOSEINFO, "  $cs"); 
   }
   return $itags;
}


our $templateheader = <<ENDE;
<script>
var isTest = false;
var testFinished = true;
var FVAR = new Array();
FVAR.push("CounterDummy");
var MVAR = new Array();
var SOLUTION_TRUE = 1; var SOLUTION_FALSE = 2; var SOLUTION_NEUTRAL = 3;
var QCOLOR_TRUE = "#44FF33"; var QCOLOR_FALSE = "#F0A4A4"; var QCOLOR_NEUTRAL = "#E0E0E0";
var objScormApi = null;
var doScorm = 0;
var viewmodel;
var activeinputfieldid = "";
var activetooltip = null;
var activefieldid = "";
var sendcounter = 0;
var intersiteactive = false;
var intersiteobj = createIntersiteObj();
var intersitelinks = false;
var localStoragePresent = false;
var SITE_ID = "(unknown)";
var SITE_UXID = "(unknown)";
var SITE_PULL = 0;
var animationSpeed = 250;

// <JSCRIPTPRELOADTAG>

function loadHandler() {
  globalloadHandler("");
}

function unloadHandler() {
  globalunloadHandler();
}

</script>
ENDE

# Die Kommentarzeichen gehoeren zu den preloadtags !

# Wird von split.pm an die Headerzeilen angehaengt sofern $doscorm==1 ist
our $scoheader = <<ENDE;
<script>
objScormApi = null;
doScorm = 1;
</script>
ENDE

our $scoheader_old = <<ENDE;
<script>
objScormApi = GetSCORMApi();
var lName = "";
var lID = "";
if (objScormApi != null){
  objScormApi.Initialize("");
  lName = objScormApi.GetValue("cmi.learner_name");
  lID = objScormApi.GetValue("cmi.learner_id");
}
</script>
ENDE

our $templatefooter = <<ENDE;
<script>
viewmodel = {
  // <JSCRIPTVIEWMODEL>
  
  ifobs: ko.observable("")
}

ko.bindingHandlers.evalmathjax = {
    update: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
      var value = valueAccessor(), allBindings = allBindingsAccessor();
      var latex = ko.unwrap(value);
      
      var i;
      latex = applyMVARLatex(latex);

      if (element.childNodes[0]) {
        // var sy = getScrollY();
	var mathelement = MathJax.Hub.getAllJax(element)[0];
	MathJax.Hub.Queue(["Text",mathelement,latex]);
	// setScrollY(sy);
      } else {
	// while(element.childNodes[0]) { element.removeChild( element.childNodes[0] ); }
      
	var s = document.createElement('script');
	s.type = "math/tex; mode=display";
	try {
	  s.appendChild(document.createTextNode(latex));
	  element.appendChild(s);
	} catch (e) {
	  s.text = latex;
	  element.appendChild(s);
	}
	MathJax.Hub.Queue(["Typeset",MathJax.Hub,element]);
      }
  }
 };

ko.applyBindings(viewmodel);


\$(document).ready(function () {
  globalreadyHandler("");   
});

  // <JSCRIPTPOSTMODEL>

</script>

</body>
</html>
ENDE


# Aufrufreihenfolge: JSCRIPTPOSTMODUL, globalreadyHandler, globalloadHandler


# -------------------------------------- subs --------------------------------------------------------------------------------

# --------------------------------------------- Objektdefinitionen ---------------------------------------------------------------------------------------------------------------------

{
package Page;

# sub new()
# Konstruktor der Klasse
# Parameter
#
sub new {
	my ($package) = @_;
	
	# Initialisierung der Objekteigenschaften
	my $self = {
		SUBPAGES  => [],
		LEVEL     => 0,
		ISCHAPTER => 0,
		PARENT    => 0,
		ROOT      => 0,
		NEXT      => 0,
		PREV      => 0,
		XNEXT     => -1,
		XPREV     => -1,
		XCONTENT  => 0,
                HELPSITE  => 0,
                TESTSITE  => 0,
		NR 	  => "1",
		POS       => "0",
		ICON      => "STD",   
		TOCSYMB   => "?",
		TITLE     => "",
		TEXT      => "",
		LINK      => "",
		SAVEPAGE  => 0,
		MENUITEM  => 1,
		DISPLAY   => 0,
		EXPORTS   => [],
		DOCNAME   => "",
		UXID      => $main::UNKNOWN_UXID,
		MODULID   => ""
	};
	$self->{ID} = $main::PageIDCounter;
	$main::PageIDCounter++;
	#Initialisierung der root-Eigenschaft
	$self->{ROOT} = $self;
	#Variablentyp auf die Klasse stellen
	bless $self, $package;
	return $self;
}

# sub split()
# Zerteilung von Text, Erstellung der Objektstruktur
# Parameter
#	$text		Text, der in Teile getrennt werden soll
#	$splitlevel	Ebene bei der mit der Trennung aufgehoert wird
#	$level		Ebene der aktuellen Seite
#	$lastobj	zuletzt erstelltes Objekt
sub split {
	my ($self, $text, $splitlevel, $level, $lastobj) = @_;
	my (@subsections, $p, $nextlevel, $i, $subsec);
	
	if ($lastobj) {
		#das zuletzt erstellte Objekt erhaelt Link auf das aktuelle Objekt
		$lastobj->{NEXT} = $self;
	}
	#nun ist das aktuelle Objekt das zuletzt erstellte
	$lastobj = $self;
	#Level abspeichern
	$self->{LEVEL} = $level;
	
	if ( $level>=$splitlevel) {
		#keine weitere Unterteilung
		$self->{TEXT} = $text;
		$self->{DISPLAY} = 1;
		if ($level>$splitlevel) {
		$self->{TITLE}="Test";
		}	
	} else {
		#Teilung in Unterabschnitte
		#Level erhoehen
		$nextlevel = $level +1;
		#Trennug des Textes anhand von <h.>
		@subsections = split(/<h$nextlevel>/,$text);
		
		#Der Text vor dem ersten <h.> steht an Stelle 0 des Arrays
		#dieser Text gehoert zum aktuellen Objekt
		$text = $subsections[0];
		#eigentlich Vorkurs-spezifisch, dass der folgende Text als leer angesehen wird
		$text =~ s/\s*(<div class=\"p\"><!----><\/div>)?\s*$//;
		#Text abspeichern
		$self->{TEXT} = $text;
		
		#ueber die Unterabschnitte iterieren und neue Objekte erstellen
		for ($subsec = 1;$subsec<=$#subsections;$subsec++)
		{
			#neues Objekt
			$p = Page->new();
			$p->{DISPLAY} = 1;
			
			#Text aus Array holen
			$text = $subsections[$subsec];
			#eigentlich Vorkurs-spezifisch, dass der folgende Text am Ende des Abschnitts
			#geloescht wird
			$text =~ s/\s*(<div class=\"p\"><!----><\/div>)?\s*$//;
			#nach </h.> suchen und den Text zwischen den h-Tags als Titel abspeichern
			$text =~ /^(.*?)<\/h$nextlevel>/s;
			$p->{TITLE} = $1;
			#Position der Seite innerhalb des Arrays
			$p->{POS} = $subsec;
			#Link auf das letzte Objekt speichern
			$p->{PREV} = $lastobj;
			
			#Unsinn! wird das noch genutzt?
			$p->{ISCHAPTER} = ($1 eq "chAp");
			
			#Titel am Anfang des Textes entfernen
			$text = substr($subsections[$subsec],length($&));
			
			#Diese Unterseite an das aktuelle Objekt anhaengen
			$self->addpage($p);
			#Link initialisieren
			$p->{LINK} = $p->secpath();
			
			#for ($i=1;$i<$nextlevel;$i++) {print ". . ";}
			#print $p->{TITLE} . "\n";
			
			#Rekursion aufrufen
			$lastobj = $p->split($text, $splitlevel, $nextlevel, $lastobj);
		}
	}
	#das zuletzt erstellte Objekt fuer die Rekursion zurueckliefern
	return $lastobj;
}


# 
# sub link()
# liefert den Dateipfad, wo diese Seite gespeichert wird
# Parameter
# 	keine
sub link {
	my ($self) = @_;
	my (@subpages);
	#Array der Unterseiten
	@subpages = @{$self->{SUBPAGES}};
	if (! $self->{DISPLAY} && $#subpages >=0) {
		#Falls die aktuelle Seite nicht angezeigt wird und sie Unterseiten hat,
		#dann wird der Link auf die erste Unterseite geliefert
		return $subpages[0]->link();
	} else {
		#Ansonsten der in der LINK-Eigenschaft abgespeicherte Link
		return $self->{LINK};
	}
}


# 
# sub linkpath()
# liefert zum link passende Anzahl von "../"
# Parameter
# 	keine
sub linkpath {
	my ($self) = @_;
	my ($link, @subdirs, $i, $text);
	#hole eigenen Link
	$link = $self->link();
	$text = "";
	#zaehlen wie oft /abc/ zu finden ist
	#aufeinanderfolgende // zaehlen nicht
	@subdirs = ($link =~ /[^\/]+?\//g);
	#fuer jeden dieser Unterordner ein "../" anhaengen
	for ( $i=0; $i <=$#subdirs; $i++ ) {
		$text .= "../";
	}
	#relativen Pfad-Prefix zurueckliefern
	return $text;
}


# 
# sub addpage()
# erweitert das Array SUBPAGES um das abgegebene Objekt und setzt die
# Eigenschaften PARENT und ROOT
# Parameter
# 	$page	Objekt, das angehaengt werden soll
sub addpage {
	my ($self, $page) = @_ ;
	#Objekt an das sUBPAGES-Array anhaengen
	push @{$self->{SUBPAGES}}, $page;
	#Eigenschaften setzen
	$page->{PARENT} = $self;
	$page->{ROOT} = $self->{ROOT};
}


# 
# sub secpath()
# liefert eine eindeutige Position des Objekts innerhalb der Objektstruktur
# Parameter
# 	keine
sub secpath {
	my ($self) = @_;
	my ($path, $p);
	#uebergeordnetes Objekt abfragen
	$p = $self->{PARENT};
	if ($p->{LEVEL} != 0) {
		#Falls das uebergeordnete Objekt nicht das root-Objekt ist,
		#wird zunaechst der Pfad dieses Objekts abgefragt
		$path = $p->secpath() . ".";
	}
	#danach wird die eigene Position angehaengt
		$path .= $self->{POS};
}


# 
# sub titlepath()
# liefert Titel des Kapitels und der aktuellen Seite
# Parameter
# 	keine
sub titlepath {
	my ($self) = @_;
	my ($path, $p, $root);
	
	#abhaengig vom Level des aktuellen Objekts
	if ($self->{LEVEL} > 1) {
		#nicht root und nicht auf erster Ebene
		#hole uebergeordnetes Objekt auf erster Ebene
		$p = $self->{PARENT};
		until ($p->{LEVEL}<=1) {
			$p = $p->{PARENT};
		}
		#root Objekt ist dem nochmals uebergeordnet
		$root = $p->{PARENT};
		
		#hole titlepath vom root-Objekt und haenge Titel des Kapitels und
		#der aktuellen Seite an
		$path = $root->titlepath() . 
			"<h1>" . $p->{TITLE} . "</h1>\n" . 
			"<h2>" . $self->{TITLE} . "</h2>\n";
	} elsif ($self->{LEVEL} == 1) {
		#auf erster Ebene
		#uebergeordnetes Objekt ist root
		$root = $self->{PARENT};
		#hole titlepath von root und haenge eigenen Titel an
		$path = $root->titlepath() . 
			"<h1>" . $self->{TITLE} . "</h1>\n";
	} else {
		#root Objekt
		#falls root einen Titel hat, wird dieser in h1-tags gesetzt
		#ansonsten ist der Text leer
		$path = ($self->{TITLE} ? "<h1>" . $self->{TITLE} . "</h1>\n" : "" );
	}
	
	return $path;
}

#
# sub titlestring()
# liefert Title der HTML-Seite
# Parameter
#       keine
sub titlestring {
        my ($self) = @_;
        my ($path);
	my (@subpages);
	if (length($self->secpath())<9){
		@subpages = @{$self->{PARENT}->{SUBPAGES}};
	} else {
		@subpages = @{$self->{PARENT}->{PARENT}->{SUBPAGES}};
	}
	# Verkettete Titel nur, falls self in Kette von Unterabschnitten und nicht erstes Element darin ist
	if (($#subpages >0 && substr($self->secpath(),-1,1)!=1) and ($main::doconctitles eq 1)) {
		$path=$subpages[0]->{TITLE} ." - " . $self->{TITLE};
	} else {
		$path=$self->{TITLE};
	}
#        $path = substr($self->secpath(),0,5) . " " . $self->{TITLE}; 
        return $path;
}



# 
# sub navprev()
# liefert das in der Struktur folgende Objekt, das ausgegeben wird
# Parameter
# 	keine
sub navprev {
	my ($self) = @_;
	my ($p);
	
	#hole vorheriges Objekt
	$p = $self->{PREV};
	#iteriere dies, solange bis das root-Objekt oder eine Seite, die ausgegeben wird,
	#erreicht wird
	until ($p->{LEVEL} == 0 || $p->{DISPLAY}) {
		$p = $p->{PREV};
	}
	#liefere einen Verweis auf das Objekt
	if ($p->{LEVEL} != 0) {
		return $p;
	} else {
		return 0;
	}
}


# 
# sub navnext()
# liefert das in der Struktur vorhergehende Objekt, das ausgegeben wird
# Parameter
# 
sub navnext {
	my ($self) = @_;
	my ($p);
	
	#hole naechstes Objekt
	$p = $self->{NEXT};
	#iteriere dies, solange bis das Ende der Objekt-Struktur oder eine Seite,
	#die ausgegeben wird, erreicht wird
	until (! $p || $p->{DISPLAY}) {
		$p = $p->{NEXT};
	}
	
	#liefere einen Verweis auf das Objekt
	if ($p) {
		return $p;
	} else {
		return 0;
	}
}


# 
# sub subpagelist()
# liefert eine Liste der untergeordneten Seiten
# Parameter
# 	keine
sub subpagelist {
	my ($self) = @_;
	my (@subpages, $text, $i);
	
	#hole Unterseiten
	@subpages = @{$self->{SUBPAGES}};
	
	#falls es Unterseiten gibt, wird eine Liste ausgegeben
	if ($#subpages >= 0) {
		#ueber Unterseiten iterieren und Eintrag erstellen, falls die Eigenschaft
		#MENUITEM gesetzt ist
		for ($i = 0; $i<=$#subpages; $i++) {
			if ($subpages[$i]->{MENUITEM}) {
				$text .= "<li class='chplist'><a class=\"MINTERLINK\" href='" . $subpages[$i]->link() . ".{EXT}'>";
				$text .= $subpages[$i]->{TITLE} . "</a></li>\n";
			}
		}
		#Anfang und Ende der Liste
		if ($text != "") {
			$text = "<ul class='chplist'>\n$text</ul>\n";
		}
	} else {
		$text = "";
	}
	
	return ($text);
}

# 
# sub idprint()
# gibt den Teilbaum ueber print aus
sub idprint {
  my ($self) = @_;
  my $i;
  my $j;
  for ($j=0; $j <= $self->{LEVEL}; $j++) {
    print "  ";
  }

  my @pages = @{$self->{SUBPAGES}};
  my $k = ($#pages)+1;

  my $nid = -1;
  my $pid = -1;
  my $xnid = -1;
  my $xpid = -1;
  my $bid = -1;
  my $pa = -1;

  if ($self->{NEXT}) { $nid = $self->{NEXT}->{ID}; }
  if ($self->{XPREV}) { $xpid = $self->{XPREV}->{ID}; }
  if ($self->{XNEXT}) { $xnid = $self->{XNEXT}->{ID}; }
  if ($self->{PREV}) { $pid = $self->{PREV}->{ID}; }
  if ($self->{PARENT}) { $pa = $self->{PARENT}->{ID}; }


  print "(id=$self->{ID},xco=$self->{XCONTENT},lev=$self->{LEVEL},title=$self->{TITLE},on=$self->{DISPLAY},parent=$pa,prev=$pid,next=$nid,xprev=$xpid,xnext=$xnid)\n";

  for ( $i=0; $i < $k; $i++ ) {
    $pages[$i]->idprint();
  }

}

}



# Die Klasse ModulPage wird von der Klasse Page abgeleitet.
# Die meisten Funktionen werden gar nicht ueberschrieben.
# Die split-Funktion ruft zunaechst die split-Funktion der Page-Klasse auf,
# setzt danach aber den Typ der gesamten Objektstruktur auf ModulPage.
# Danach werden fuer die Seiten, die im Modulformat vorliegen, die einzelnen Modulseiten
# erstellt, welche in der Struktur als Unterseiten auftreten.
# Dabei wird automatisch die Seiten Info und Visualisierungen erstellt.
# Die Funktion menu behandelt lediglich die Modul-Hauptseiten getrennt, da diese als
# "markiert" gelten, wenn eine der Modul-Unterseiten aktuell ausgewÃ¤hlt ist.
# Die Funktion navigation behandelt ebenfalls die Modulseiten getrennt. Statt der normalen
# Navigation wird die Modul-Navigation erzeugt.
# navprev wird ueberschrieben, damit der "Modul zurueck" Link funktioniert. Obwohl bei der
# vorherigen Modulseite DISPLAY=0 ist, wird auf diese Seite verwiesen, da dann automatisch
# auf die erste Unterseite verlinkt wird.

# Die Parameter stimmen mit denen im Page-Objekt ueberein und werden hier nicht
# nochmal kommentiert
{
	package ModulPage;
	use base 'Page';

	# sub new()
	# Konstruktor
	sub new {
		my ($package) = @_;
		my $self = Page->new();
		# ISMODUL gibt an, ob dies ein Modul ist
		# diese Eigenschaft wird durch die split Funktion gesetzt
		$self->{ISMODUL} = 0;
		# MODULPART gibt an, welcher Teil des Moduls in den Objekt
		# gespeichert ist
		$self->{MODULPART} = "";
		bless $self;
		return $self;
	}

	# sub split()
	# Arbeitet zunaechst wie in der Page-Klasse. In einem zweiten Durchgang wird
	# der Typ aller Objekte auf ModulPage gesetzt und die zusaetzliche Trennung
	# der Modulseiten durchgefuehrt
	sub split {
		my ($self, @args) = @_;
		my (@subpages, $p, $i, $content);
		my ($lastpage);

		if ($self->{TEXT} eq "") {
			# wenn es keinen Text gibt, erst mal den normalen split aufrufen
			my $lastobj = $self->SUPER::split(@args);
			# alle Unterobjekte als Modul markieren
			setmoduletype($self);

		} else {
			# der Aufruf setmoduletype($self); landet hier
			# diese Seite erfuellt die Bedingungen fuer einen Modul
			# -> Unterteilung in Modul-seiten


			# ueberpruefen ob es einen Start-Bereich gibt
			my $searchstring = "<!-- (.*?) \/\/-->((.|\n)*?)<!-- end(.*?) \/\/-->";
			#my $searchstring = "<!-- start \/\/-->((.|\n)*?)<!-- endstart \/\/-->";
			my $text = $self->{TEXT};

			if ($text =~ /$searchstring/) {
				$self->{ISMODUL} = 1;
				$self->{DISPLAY} = 0;
				$self->{TEXT} = "";


                                # Labels in den ersten folgenden xcontent verschieben
                                my $sslabels = "";
                                if ($self->{LEVEL} eq 3) {
                                  if ($text =~ /(.*)<!-- xcontent;-;0;-;/s ) {
                                    my $pretext = $1;
                                    while ($pretext =~ s/<!-- mmlabel;;(.*?)\/\/-->//s ) { $sslabels = $sslabels . "<!-- mmlabel;;$1\/\/-->"; }
                                    while ($pretext =~ s/<a(.*?)>(.*?)<\/a>//si ) { $sslabels = $sslabels . "<a$1>$2<\/a>"; }
                                    $text =~ s/(.*)<!-- xcontent;-;0;-;/$pretext<!-- xcontent;-;0;-;/s ;
                                  }
                                }


                                my $i = 0;
                                my $pos = 1;
                                my $lastpage;

                                # Die xcontent-Abschnitte werden iteriert und in die Navigationsschleife eingehÃ¤ngt
                     	        my ($mp1, $mp2, $mp3);
                                while ($text =~ /<!-- xcontent;-;$i;-;(.*);-;(.*);-;(.*) \/\/-->/) {
                            	    $mp1 = $1; $mp2 = $2; $mp3 = $3;
				    my $markera = "<!-- xcontent;-;$i;-;$1;-;$2;-;$3 \/\/-->";
				    my $markerb = "<!-- endxcontent;;$i \/\/-->";
				    my $tpa = index($text,$markera);
				    my $tpb = index($text,$markerb);

				    if (($tpa ne -1) and ($tpb ne -1)) {

				    my $tpcontent = substr($text,$tpa+length($markera),($tpb - $tpa) - length($markera));

                                    my $p;

                                    $p = ModulPage->new();
                                    # Subpage hinzufuegen
                                    $self->addpage($p);

                                    $p->{ISMODUL} = 1;                        # als Modulseite markieren
                                    $p->{DISPLAY} = 1;
                                    
                                    if ($i eq 0) {
                                      $p->{MODULID} = "start";
                                      $p->{DOCNAME} = "modstart";
                                      $p->{PREV} = 0;
				      if ($p->{PARENT}->{PARENT}->{XNEXT} eq -1) {
					$p->{PARENT}->{PARENT}->{XNEXT} = $p;
				      }
				      if ($p->{PARENT}->{PARENT}->{PARENT}->{XNEXT} eq -1) {
					$p->{PARENT}->{PARENT}->{PARENT}->{XNEXT} = $p->{PARENT}->{PARENT};
				      }
                                    } else {
                                      $p->{MODULID} = "xcontent";
                                      $p->{DOCNAME} = "xcontent$i";
                                      $p->{PREV} = $lastpage;
                                      $lastpage->{NEXT} = $p;
                                    }

                                    $p->{LINK} = $self->{LINK} . "/" . $p->{DOCNAME};   # Link setzen
                                    $p->{MENUITEM} = 0;                       # nicht im Menu darstellen
                                    $p->{POS} = $pos;
                                    $p->{NR} = ""; #$self->{NR} . "." . ($i+1);
                                    $p->{LEVEL} = 4;
                                    $p->{TITLE} = $1;
                                    if ($2 ne "") {
                                      $p->{CAPTION} = $2;
                                    } else {
                                      $p->{CAPTION} = $1;
                                    }
                                    $p->{ICON} = $3;
				    $p->{XCONTENT} = 1;

				    $p->{TOCSYMB} = "I";
                                    if ($tpcontent =~ m/<!-- declaretestsymb \/\/-->/s ) {
                                        $p->{TOCSYMB} = "Test";
                                    }
                                    
                                    if ($tpcontent =~ m/<!-- declareexcsymb \/\/-->/s ) {
                                        $p->{TOCSYMB} = "T";
                                    }
                                    
                                    $p->{TOCSYMB} = "<div class=\"xsymb\"><tt>" . $p->{TOCSYMB} . "</tt></div>";
                                    
                                   
				    # Erzeuge Dokumentweite XVerlinkung der xcontents
				    $p->{XPREV} = $XIDObj;
				    if ($XIDObj != -1) {
				      $XIDObj->{XNEXT} = $p;
				    }
				    $p->{XNEXT} = -1;
				    $XIDObj = $p;

				    # sectioncounter extrahieren
                                    # Struktur des sectioninfo-Tags: <!-- sectioninfo;;section;;subsection;;subsubsection;;nr_ausgeben;;testseite; //-->

				    if ($tpcontent =~ m/<!-- sectioninfo;;(\w+?);;(\w+?);;(\w+?);;([01]);;([01]); \/\/-->/ ) {
				      my $sec = $1;
				      my $ssec = $2;
				      my $sssec = $3;
                                      my $printnr = $4;
                                      my $testpage = $5;
                                      
                                      if (($testpage ne 0) and ($testpage ne 1)) {
										logMessage($CLIENTERROR, "Zaehlerueberlauf testpage=$testpage");
                                      }
                                      
                                      $p->{TESTSITE} = $5;
                                      
                                      if ($i eq 0) {
                                        $p->{PARENT}->{NR} = "$sec.$ssec";
                                        $p->{PARENT}->{PARENT}->{NR} = "$sec";
                                      }

				      main::logMessage($VERBOSEINFO, "xcontent \"$p->{TITLE}\" hat Nummern $sec.$ssec.$sssec");

				      # <title> der HTML-Seite erweitern
				      $p->{TITLE} = $config{moduleprefix} . " Abschnitt $sec.$ssec.$sssec " . $p->{TITLE};
				      # Fehler im ttm korrigieren: subsubsection-Titel werden ohne Nummernprefix ausgegeben
				      # {XONTENTPREFIX} wird in split.pm (sub printpages) durch die captions der vorgaenger ersetzt, diese
                                      # sind zum jetzigen Zeitpunkt noch nicht gesetzt
                                      my $pref = "";
                                      if ($printnr == 1) { $pref = "$sec.$ssec.$sssec "; }
				      if ($tpcontent =~ s/<h4>(.*?)<\/h4><!-- sectioninfo;;$sec;;$ssec;;$sssec;;$printnr;;$testpage; \/\/-->/<h4>{XCONTENTPREFIX}<\/h4><br \/><h4>$pref$1<\/h4>/ ) {
				      } else {
						main::logMessage($CLIENTERROR, "Konnte in xcontent \"$p->{TITLE}\" nicht replacen");
				      }
				      
				    } else {
				      main::logMessage($CLIENTERROR, "Konnte Sectionnumbers nicht extrahieren in xcontent: $p->{TITLE}");
				    }

                                    # MSubsubsections im MXContent mit Nummern versehen
                                    $tpcontent =~ s/<h4>(.+?)<\/h4><!-- sectioninfo;;(\w+?);;(\w+?);;(\w+?);;1;;([01]); \/\/-->/<h4>$2.$3.$4 $1<\/h4>/g ;


                                    main::logMessage($VERBOSEINFO, "xcontent $i: $1 ($2), id = $p->{MODULID}, Laenge ist " . ($tpb-$tpa) . ", sslabels = $sslabels");

                                    $p->{TEXT} = $sslabels . "\n" . $tpcontent;
                                    $sslabels = "";

                                    $p->{NEXT} = 0;

                                    $pos = $pos + 1;
                                    $lastpage = $p;

				    } else {
                                      main::logMessage($CLIENTERROR, "Found xcontent $i but could not process it: \$1=$mp1, \$2=$mp2, \$3=$mp3");
                                      if ($tpa ne -1) {
                                        main::logMessage($CLIENTERROR, " (eof problem, ttm stopped processing here)");
                                      } else {
                                        main::logMessage($CLIENTERROR, "  File content:\n$text\n");
                                      }
				    }

                                    $i = $i + 1;

                                }

                                # Die scontent-Abschnitte werden iteriert aber nicht in die Navigationsschleife eingehaengt
                                $i = 0;
                                while ($text =~ /<!-- scontent;-;$i;-;(.*);-;(.*);-;(.*) \/\/-->/) {
                            	    $mp1 = $1; $mp2 = $2; $mp3 = $3;
				    my $markera = "<!-- scontent;-;$i;-;$1;-;$2;-;$3 \/\/-->";
				    my $markerb = "<!-- endscontent;;$i \/\/-->";
				    my $tpa = index($text,$markera);
				    my $tpb = index($text,$markerb);

				    if (($tpa ne -1) and ($tpb ne -1)) {

				    my $tpcontent = substr($text,$tpa+length($markera),($tpb - $tpa) - length($markera));
                                    my $p;

                                    $p = ModulPage->new();
                                    # Subpage hinzufuegen
                                    $self->addpage($p);

                                    $p->{ISMODUL} = 1;                        # als Modulseite markieren
                                    $p->{DISPLAY} = 1;
                                    
                                    $p->{MODULID} = "scontent";
                                    $p->{DOCNAME} = "scontent$i";
                                    $p->{LINK} = $self->{LINK} . "/" . $p->{DOCNAME};   # Link setzen

                                    $p->{MENUITEM} = 0;                       # nicht im Menu darstellen
                                    $p->{POS} = $pos;
                                    $p->{NR} = ""; #$self->{NR} . "." . ($i+1);
                                    $p->{LEVEL} = 4;
                                    $p->{TITLE} = $1;
				    $p->{TITLE} = $config{moduleprefix} . " " . $p->{TITLE};
                                    if ($2 ne "") {
                                      $p->{CAPTION} = $2;
                                    } else {
                                      $p->{CAPTION} = $1;
                                    }
                                    $p->{ICON} = $3;
				    $p->{XCONTENT} = 2;

                                    $p->{TOCSYMB} = "I";
                                    if ($tpcontent =~ m/<!-- declaretestsymb \/\/-->/s ) {
                                        $p->{TOCSYMB} = "Test";
                                    }
                                    
                                    if ($tpcontent =~ m/<!-- declareexcsymb \/\/-->/s ) {
                                        $p->{TOCSYMB} = "T";
                                    }
                                    
                                    $p->{TOCSYMB} = "<div class=\"xsymb\"><tt>" . $p->{TOCSYMB} . "</tt></div>";
                                    
                                    $p->{TEXT} = $tpcontent;

                                    $p->{PREV} = 0;
                                    $p->{NEXT} = 0;


                                    main::logMessage($VERBOSEINFO, "scontent $i: $1 ($2), id = $p->{MODULID}, Laenge ist " . ($tpb-$tpa));

                                    $pos = $pos + 1;

				    } else {
                                      main::logMessage($CLIENTERROR, "Found scontent $i but could not process it: \$1=$mp1, \$2=$mp2, \$3=$mp3");
                                      if ($tpa ne -1) {
                                        main::logMessage($CLIENTERROR, "  (eof problem, ttm stopped processing here)");
                                      } else {
                                        main::logMessage($CLIENTERROR, "  File content:\n$text\n");
                                      }
				    }

                                    $i = $i + 1;

                                }

                  }

            }

	}

	#
	# sub setmoduletype()
	# Iteriert ueber die Objektstruktur und setzt den Typ aller Objekte auf
	# ModulPage. Danach wird nochmals split aufgerufen um die Zerlegung in
	# Modulabschnitte zu erzwingen
	# Parameter
	#	keine
	sub setmoduletype {
		my ($self) = @_;
		my ($i, @subpages);
		bless $self, "ModulPage";
		$self->{ISMODUL} = 0;

		@subpages = @{$self->{SUBPAGES}};
		if ($#subpages < 0) {
			$self->split();
		} else {
			for ( $i=0; $i <= $#subpages; $i++ ) {
				main::logMessage($VERBOSEINFO, "Modultyp der Seite " . $subpages[$i]->secpath() . " auf Modul setzen");
				setmoduletype($subpages[$i]);
			}
		}
		return 1;
	}

	# sub link()
	# Verhalten wie Page-Klasse
	sub link {
		my ($self, @args) = @_;
		return $self->SUPER::link(@args);
	}
	sub linkk {
		my ($self, @args) = @_;
		return $self->SUPER::link(@args);
	}
	# sub linkpath()
	# Verhalten wie Page-Klasse
	sub linkpath {
		my ($self, @args) = @_;
		return $self->SUPER::linkpath(@args);
	}

	# sub addpage()
	# Verhalten wie Page-Klasse
	sub addpage {
		my ($self, @args) = @_;
		return $self->SUPER::addpage(@args);
	}

	# sub secpath()
	# Verhalten wie Page-Klasse
	sub secpath {
		my ($self, @args) = @_;
		return $self->SUPER::secpath(@args);
	}

	# sub titlepath()
	# Verhalten wie Page-Klasse
	sub titlepath {
		my ($self, @args) = @_;
		return $self->SUPER::titlepath(@args);
	}

	# sub navprev()
	# liefert bei Modulseiten den Link auf die vorherige Modulseite,
	#	die Startseite hat keinen Vorgaenger
	# bei anderen Seiten wird auch die Modulhauptseite (die ja nicht ausgegeben wird)
	# als Vorgaenger akzeptiert. So landet man durch die link-Funktion auf die Startseite, da
	# dies die erste Unterseite ist, die ausgegeben wird.
	sub navprev {
		my ($self) = @_;
		my ($p);

		
                if ($self->{PREV} == 0) {
		  return 0;
                }
		$p = $self->{PREV};

		# Hier wird die Schleife auch abgebrochen, wenn Display aus ist und es sich um ein Modul mit Unterseiten handelt
		until ($p->{LEVEL} == 0 || $p->{DISPLAY} || ($p->{ISMODUL} && $#{$p->{SUBPAGES}} >=0 )) {
			$p = $p->{PREV};
		}
		if ($p->{LEVEL} != 0 && $self->{MODULID} ne "start") {
			return $p;
		} else {
			return 0;
		}
	}

	# sub navnext()
	# Verhalten wie Page-Klasse
	sub navnext {
		my ($self, @args) = @_;
		return $self->SUPER::navnext(@args);
	}

	# sub subpagelist()
	# Verhalten wie Page-Klasse
	sub subpagelist {
		my ($self, @args) = @_;
		return $self->SUPER::subpagelist(@args);
	}

}



# ---------------------------------------------- Bearbeitungsfunktionen -------------------------------------------------------------

# sub loadfile()
# liefert den Inhalt der Datei als String (mit Ausgabe auf Konsole)
# Parameter
# 	$file	Dateiname
sub loadfile {
	my($file, $text, $zeile, $rw);
	$file = $_[0];
	$text = "";
	$rw = open(LDFILE,$file) or die "\nFehler beim Oeffnen der Datei \"$file\": $!\n";
	while(defined($zeile = <LDFILE>)) { $text .= $zeile; }
	$text;
}


# 
# sub writefile()
# schreibt Inhalt in eine Datei (mit Ausgabe auf Konsole)
# Parameter
# 	$file	Dateiname
#	$output	Inhalt
sub writefile {
	my($file, $output, $rw);
	$file = $_[0];
	$output = $_[1];
	$file =~ /(.*)\/[^\/]*?$/;
	mkpath($1);
	$rw = open(OUTPUT, "> $file") or die "Fehler beim Erstellen von '$file': $!\n";
	print OUTPUT $output;
	close(OUTPUT);
}

# sub noregex()
# Kapselt alle Sonderzeichen in einem Matching-Pattern
# Parameter
#   $s          Der Matching-String
# Rueckgabe: Der String wobei allen Sonderzeichen ein backslash vorangestellt wurde
# Ausnahme: "*" um Dateisuche zu ermoeglichen

sub noregex {
  my $s;
  $s = $_[0];
  foreach my $sz ("+","-","?",".","_","#","(",")","[","]") {
    my $sz2;
    $sz2 = "\\" . $sz;
    $s =~ s/$sz2/$sz2/g;
  }
  return $s;
}

# sub postprocess()
# Verarbeitet postprocessing-tags im html
# Parameter
#   $orgpage       Das Seitenobjekt ($p->{TEXT} kann sich von $text unterscheiden weil letzteres schon bearbeitet worden ist)
#   $text          Der HTML-Output mit den tags
#   $outputfile    Die Ausgabedatei ohne Endung
sub postprocess {
  my($orgpage, $text, $outputfile);
  $orgpage = $_[0];
  $text = $_[1];
  $outputfile = $_[2];
  my $outputfolder = "";
  if ( $outputfile =~ m/(.+)\/(.+)/ ) {
    $outputfolder = $1;
  } else {
    $outputfolder = $outputfile;
  }

  # UXIDs eintragen
  if ($text =~ m/<!-- mdeclaresiteuxidpost;;(.+?);; \/\/-->/s ) {
    $orgpage->{UXID} = $1;
    logMessage($VERBOSEINFO, $orgpage->{TITLE} . " -> " . $orgpage->{UXID} . " (siteuxidpost)");
  } else {
    logMessage($CLIENTWARN, "Site hat keine uxid: " . $orgpage->{TITLE});
    $orgpage->{UXID} = $UNKNOWN_UXID;
  }
  
  
  # Pull-Seiten aktivieren, JS-Variablen anpassen (geschieht bei Zerlegung in xcontents, aber HELPSITE-Sectionstart ist keiner?)
  if ($text =~ m/<!-- pullsite \/\/-->/s ) {
    $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_PULL = 1;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
    logMessage($CLIENTINFO, "User-Pull on Site: " . $orgpage->{TITLE});
  } else {
    $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_PULL = 0;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
  }
  
  # br-Tags entfernen, die nebeneinander gestellte tabulars zerreissen
  # Das ist unsauber, weil nicht klar ist, warum ttm diese Tags prinzipiell zwischen Tabellen setzt
  # Erkennungsmerkmal ist die Tagkombination <!--hbox--><br clear="all" /> und danach direkt ein table-Tag
  $text =~ s/<!--hbox--><br clear=\"all\" \/> *<table/<!--hbox--> <table/g;    # Sternchen vor <table> ein Tippfehler?

  
  # In start-stop-align-Bloecken die td-Tags anpassen

    # $text =~ s/[\n\r]*//g ;

    my $pref = "xxx"; # Prefix wird vor modifizierte td's gesetzt um sie zu markieren
    my $rpr = "CRLF";
    while ($text =~ /$rpr/i ) { $rpr = $rpr . "y" };
    # print "Using CRLF-Prefix: $rpr\n";
    $text =~ s/\n/$rpr A/g;
    $text =~ s/\r/$rpr B/g;

    while ($text =~ /<!-- startalign;;(.+?);;(.+?); \/\/-->/ ) {
      my $i = $1;
      my $al = $2;
      logMessage($VERBOSEINFO, "Align-environment $i with align=\"$al\":");

      while ($text =~ /<!-- startalign;;$i;;$al; \/\/-->(.*?)<td(.*?)>(.*)<!-- stopalign;;$i; \/\/-->/  ) {
	my $x1 = $1;
	my $x2 = $2;
	my $xrep = $x2;
	my $x3 = $3;
      
	if ($xrep =~ s/align=[\"'](.*?)[\"']/align=\"$al\"/ ) {
	  # direct align replace happened
	} else {
	  # concatenate alignment
	  $xrep = $xrep . " align=\"$al\"";
	}
	
	if ($text =~ s/<!-- startalign;;$i;;$al; \/\/-->$x1<td$x2>$x3<!-- stopalign;;$i; \/\/-->/<!-- startalign;;$i;;$al; \/\/-->$x1<$pref td$xrep>$x3<!-- stopalign;;$i; \/\/-->/ ) {
	  # print "  TD corrected, attributes $x2 changed to $xrep\n";
	} else {
	  $text =~ s/<!-- startalign;;$i;;$al; \/\/-->//g ;
	  $text =~ s/<!-- stopalign;;$i; \/\/-->//g ;
	}
      }

      $text =~ s/<!-- startalign;;$i;;$al; \/\/-->//g ;
      $text =~ s/<!-- stopalign;;$i; \/\/-->//g ;

      # Prefixe entfernen
      $text =~ s/<$pref td/<td/g;


    }
    $text =~ s/$rpr A/\n/g;
    $text =~ s/$rpr B/\r/g;

  # Registrierte Dateien ermitteln und an die richtige Stelle kopieren
  logMessage($VERBOSEINFO, "Copying local files, outputfolder=$outputfolder, outputfile=$outputfile");
  my $nf = 0;
  while ($text =~ /<!-- registerfile;;(.+?);;(.+?);;(.+?); \/\/-->/) {
    $nf++;
    my $fileid = $3;
    my $includedir = $2;
    my $fname = $1;
    my $fnameorg = $fname;

    logMessage($VERBOSEINFO, "Processing includedir=$includedir and fname=$fname, id = $fileid");

    # Ist die Dateierweiterung mit angegeben?
    my $dobase64 = 0;
    my $fext = "";
    if ($fname =~ m/\.(.+)/ ) {
      $fext = "." . $1;
      $fname =~ s/$fext//;
      logMessage($VERBOSEINFO, "File extension is $fext");
      if ($fext eq ".png") { $dobase64 = 1; } else { $dobase64 = 0; logMessage($VERBOSEINFO, "   kein .png sondern " . $fext);}
      if ($fext eq ".PNG") { logMessage($CLIENTERROR, "png-Datei mit Dateierweiterung PNG (Grossbuchstaben) gefunden, wird nicht erkannt!"); }
      
    } else {
      logMessage($VERBOSEINFO, "No file extension given, guessing graphics extensions");
      # Simuliere DeclareGraphicsExtension{png,jpg,gif}
      my $filerump = "tex/" . $includedir . "/" . $fname;
      my $filelist = `ls -l $filerump.*`;
      logMessage($VERBOSEINFO, "  filelist=$filelist");
      my $filerump2 = noregex($filerump);

      if ($filelist =~ m/$filerump2\.(png)/i) {
        $fext = ".$1";
        $dobase64 = 1;
      } else {
        if ($filelist =~ m/$filerump2\.(jpg)/i) {
        $fext = ".$1";
        logMessage($VERBOSEINFO, "  ...found a jpg");
      } else {
        if ($filelist =~ m/$filerump2\.(gif)/i) {
          $fext = ".$1";
          logMessage($VERBOSEINFO, "  ...found a gif");
        } else {
          logMessage($CLIENTERROR, "Could not find suitable graphics extension for $fname, rump is $filerump, rump2 is $filerump2, filelist is\n$filelist\n");
          $fext = "*";
          # Register-Tag aus Quelltext entfernen
          $text =~ s/<!-- registerfile;;$fnameorg;;$includedir;;$fileid; \/\/-->// ;
        }
      }
    }

    }
    
    $dobase64 = 0; # Fuer Probephase
    
    if ($fext ne "*") {
      $fname = $fname . $fext;
      my $fnamename;
      my $fnamepath;
   
      ($fnamepath,$fnamename) = $fname =~ m|^(.*[/\\])([^/\\]+?)$|;
      $fnamepath = $fnamepath . ".";
      $text =~ s/<!-- mfileref;;$fileid; \/\/-->/$fname/g;
      $text =~ s/<!-- mfilenameref;;$fileid; \/\/-->/$fnamename/g;
      $text =~ s/<!-- mfilepathref;;$fileid; \/\/-->/$fnamepath/g;

      logMessage($VERBOSEINFO, "fileid $fileid wird expandiert zu $fname, liegt in Ordner $outputfolder");

      # Register-Tag aus Quelltext entfernen
      my $fnameorg2 = noregex($fnameorg);
      $text =~ s/<!-- registerfile;;$fnameorg2;;$includedir;;$fileid; \/\/-->// ;
      # oberste Verzeichnisebene aus $fname entfernen, denn die include-Verzeichnisse fuer die Module werden im HTML-Baum nicht reproduziert
      if ($includedir ne ".") { $fname =~ s/$includedir\///; }
      my $fi = "tex/" . $includedir . "/" . $fname;
      
      if ($dobase64 eq 1) {
        my $sc = -s $fi;
        logMessage($VERBOSEINFO, "   generating base64-Inlinestring for $fi of size $sc");
        open PNGFILE, '<', $fi;
        binmode PNGFILE;
        my $buf;
        my $c64 = "";
        if (read( PNGFILE, $buf, $sc )) {
          $c64 = encode_base64($buf);
        } else {
          logMessage($CLIENTWARN, "   file not readable");
        }
        close PNGFILE;
      }
      
      my $fi2 = $outputfolder . "/" . $fname;
      logMessage($VERBOSEINFO, "     Copying $fi to $fi2");
      $fi2 =~ /(.*)\/[^\/]*?$/;
      mkpath($1);
      my $call = "cp -rf $fi $1/.";
      system($call);
    }
  }
  if ($nf>0) { logMessage($VERBOSEINFO, "$nf local files copied"); }

  # MathML korrigieren: mtext, normalstyles und boldstyles um den Zeichensatz ergaenzen, damit es keine Serifen hat
  $text =~ s/fontstyle=\"normal\"/fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\"/ig;
  $text =~ s/fontweight=\"bold\"/fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\" fontweight=\"bold\"/ig;

  # Diese Zeilen verwenden fuer HTML, in dem die "m:"-Ersetzung in printpages vorgenommen wurde
  # $text =~ s/<m:mtext>/<m:mtext fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\">/ig;
  # MathML korrigieren: mtext/mstyle-Schachtelung umkehren, sonst wird es von den meisten Browsern nicht akzeptiert
  # $text =~ s/<m:mtext(.*)>(.*)<m:mstyle(.*)>(.+)<\/m:mstyle(.*)>\n*(.*)<\/m:mtext(.*)>/<m:mstyle$3><m:mtext$1>$4<\/m:mtext$7><\/m:mstyle$5>/gi;

  # Diese Zeile verwenden fuer HTML, in dem die "m:"-Ersetzung in printpages NICHT vorgenommen wurde
  $text =~ s/<mtext>/<mtext fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\">/ig;
  $text =~ s/<mtext(.*?)>(.*?)<mstyle(.*?)>(.+?)<\/mstyle(.*?)>\n*(.*?)<\/mtext(.*?)>/<mstyle$3><mtext$1>$4<\/mtext$7><\/mstyle$5>/gi;

  # Falls es eine Pruefungsseite ist, Kennvariablen fuer die Aufgabenpunkte erzeugen
  if ($orgpage->{TESTSITE} eq 1) {
    $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/isTest = true;\nvar nMaxPoints = 0;\nvar nPoints = 0;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
  }

  # Preload-Abschnitte in den Onload-Event verschieben
  while ($text =~ m/<!-- onloadstart \/\/-->(.*?)<!-- onloadstop \/\/-->/s ) {
    $text =~ s/<!-- onloadstart \/\/-->(.*?)<!-- onloadstop \/\/-->//s;
    my $prel = $1;
    $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/$prel\n\/\/ <JSCRIPTPRELOADTAG>/s ;
  }
  
  # Viewmodel-Eintraege in die Viewmodel-Deklaration verschieben
  while ($text =~ m/<!-- viewmodelstart \/\/-->(.*?)<!-- viewmodelstop \/\/-->/s ) {
    $text =~ s/<!-- viewmodelstart \/\/-->(.*?)<!-- viewmodelstop \/\/-->//s;
    my $prel = $1;
    $text =~ s/\/\/ <JSCRIPTVIEWMODEL>/$prel\n\/\/ <JSCRIPTVIEWMODEL>/s ;
  }

  # postmodel-Eintraege hinter die Viewmodel-Deklaration verschieben
  while ($text =~ m/<!-- postmodelstart \/\/-->(.*?)<!-- postmodelstop \/\/-->/s ) {
    $text =~ s/<!-- postmodelstart \/\/-->(.*?)<!-- postmodelstop \/\/-->//s;
    my $prel = $1;
    $text =~ s/\/\/ <JSCRIPTPOSTMODEL>/$prel\n\/\/ <JSCRIPTPOSTMODEL>/s ;
  }

  # mfeedbackbutton ersetzen
  my $j = 0;
  while ($text =~ m/<!-- mfeedbackbutton;(.+?);(.*?);(.*?); \/\/-->/s ) {
    my $type = $1;
    my $testsite = $2;
    my $exid = $3;
    my $ibt = "\n<br />";

    my $bid = "FEEDBACK$j\_$exid";
    my $tip = "Feedback zu " . $type . " " . $exid . ":<br /><b>Meldung abschicken</b>";
    $ibt .= "<button type=\"button\" style=\"background-color: #E0C0C0; border: 2px\" ttip=\"1\" tiptitle=\"$tip\" name=\"Name_FEEDBACK$j\_$exid\" id=\"$bid\" type=\"button\" onclick=\"internal_feedback(\'$exid\',\'$bid\',\'$type $exid\');\">";
    $ibt .= "Meldung abschicken";
    $ibt .= "</button><br />\n";
    
    # Feedbackbuttons nur, (ehemals falls keine Testumgebung und) falls nicht global abgeschaltet
    if ($config{parameter}{do_feedback} eq "1") {
      $text =~ s/<!-- mfeedbackbutton;$type;$testsite;$exid; \/\/-->/$ibt/s ;
    } else {
      $text =~ s/<!-- mfeedbackbutton;$type;$testsite;$exid; \/\/-->//s ;
    }
  }

  # DirectHTML-Statements einsetzen
  while ($text =~ m/<!-- directhtml;;(.*?); \/\/-->/s ) {
    my $pos = $1;
    my $rep = $DirectHTML[$pos];
    $text =~ s/<!-- directhtml;;$pos; \/\/-->/$rep/s ;
  }
  
  # qexports erfassen
  # Beachte: qpos = Eindeutiger Exportindex pro tex-Datei (wird im PreParsing erstellt, unabhängig von section oder xcontent)
  # pos = Eindeutiger Exportindex pro page bzw. html-Datei (wird im Postprocessing erstellt), Dateiname des exports ist pagename plus pos plus extension
  while ($text =~ m/<!-- qexportstart;(.*?); \/\/-->(.*?)<!-- qexportend;(.*?); \/\/-->/s ) {
    my $pos = 0;
    my $qpos = $1;
    my $expt = $2;
    if ($qpos == $3) {
      my $rep = "";
      if ($config{parameter}{do_export} eq "1") {
        my $exprefix = "\% Export Nr. $qpos aus " . $orgpage->{TITLE} . "\n";
        $exprefix .= "\% Dieser Quellcode steht unter CCL BY-SA, entnommen aus dem VE\&MINT-Kurs " . $config{parameter}{signature_CID} . ",\n";
        $exprefix .= "\% Inhalte und Quellcode des Kurses dürfen gemäß den Bestimmungen der Creative Common Lincense frei weiterverwendet werden.\n";
        $exprefix .= "\% Für den Einsatz dieses Codes wird das Makropaket $macrofile benötigt.\n";
        $pos = 0 + @{$orgpage->{EXPORTS}};
        push @{$orgpage->{EXPORTS}}, ["export$pos.tex","$exprefix$expt",$qpos];
        $rep = "<br />";
        $rep .= "<button style=\"background-color: #FFFFFF; border: 0px\" ttip=\"1\" tiptitle=\"Quellcode dieser Aufgabe im LaTeX-Format\" name=\"Name_EXPORTT$pos\" id=\"EXPORTT$pos\" type=\"button\" onclick=\"export_button($pos,1);\">";
        $rep .= "<img alt=\"Exportbutton$pos\" style=\"width:36px\" src=\"" . $orgpage->linkpath() . "../images/exportlatex.png\">";
        $rep .= "</button>";
        $rep .= "<button style=\"background-color: #FFFFFF; border: 0px\" ttip=\"1\" tiptitle=\"Quellcode dieser Aufgabe im Word-Format\" name=\"Name_EXPORTD$pos\" id=\"EXPORTD$pos\" type=\"button\" onclick=\"export_button($pos,2);\">";
        $rep .= "<img alt=\"Exportbutton$pos\" style=\"width:36px\" src=\"" . $orgpage->linkpath() . "../images/exportdoc.png\">";
        $rep .= "</button><br />";
      }
      
      $text =~ s/<!-- qexportstart;$qpos; \/\/-->(.*?)<!-- qexportend;$qpos; \/\/-->/$rep/s ;
    } else {
      logMessage($CLIENTERROR, "Inkongruentes qexportpaar gefunden: $qpos (im Seitenarray an Position $pos$)");
    }
  }
 
  # exercisecollections erfassen
  if ($config{docollections} eq 1) {
    my $collc = 0; my $colla = 0;
    while ($text =~ m/<!-- mexercisecollectionstart;;(.+?);;(.+?);; \/\/-->(.*?)<!-- mexercisecollectionstop \/\/-->/s ) {
      my $ecid1 = $1;
      my $ecopt = $2;
      my $ectext = $3;
      my $mark = generatecollectionmark($ecid1, $ecopt);
      $text =~ s/<!-- mexercisecollectionstart;;$ecid1;;$ecopt;; \/\/-->(.*?)<!-- mexercisecollectionstop \/\/-->/$mark/s ;
      
      my $arraystring = "[";
      my $ast = 0;
      
      # Aus der collection die Aufgaben extrahieren
      while ($ectext =~ m/<!-- mexercisetextstart;;(.+?);; \/\/-->(.*?)<!-- mexercisetextstop \/\/-->/s ) {
        logMessage($VERBOSEINFO, "    Aufgabe extrahiert");
        my $exid = $1;
        my $extext = $2;
        $ectext =~ s/<!-- mexercisetextstart;;$exid;; \/\/-->(.*?)<!-- mexercisetextstop \/\/-->//s ;
         
        if ($ast eq 1) { $arraystring .= ","; } else { $ast = 1; }
        my $ctext = encode_base64($extext);
        $ctext =~ s/\n/\\n/gs;

        my $l;
        
        $arraystring .= "{\"id\": \"$ecid1" . "_" . "$exid\", \"content\": \"$ctext\"}";
     
        $colla++;
      }
      
      $arraystring .= "]";
      
      $collc++;
      push @colexports, ["$ecid1", "$ecopt" , $arraystring];
    }
    if ($collc > 0) { logMessage($VERBOSEINFO, "$collc collections mit insgesamt $colla Aufgaben exportiert"); }
  }

  return $text;
}

# ENDE sub postprocess

# Parameter: $id, die eindeutige Collection-ID, $opt:   Die Optionen fuer die Collection
sub generatecollectionmark {
  my $id = $_[0];
  my $opt = $_[1];
 
  my $s = "<!-- collectionplaceholder: $id, $opt //-->";
  return $s;
}


# sub getstyleimporttags()
# Erzeugt die tags zur Einbindung der Stylesheets
# Parameter: $lp:   Der Linkpath
sub getstyleimporttags {
   my ($lp) = @_;
  
   my $itags = "";


    my $i;
    my $css = "";
    for ($i = 0; $i <= $#{$config{stylesheets}}; $i++) {
      my $cs = $config{stylesheets}[$i];
      $itags = $itags . "<link rel=\"stylesheet\" type=\"text\/css\" href=\"$lp$cs\"\/>\n";
      $css .= $cs . " "; 
    }
    
    logMessage($VERBOSEINFO, "Using these stylesheets: $css");

    return $itags;
}


#------------------------------------------------ START NEUES DESIGN ---------------------------------------------------------------------------------------


# sub getheader()
# Erzeugt das head-div fuer die html-Seiten
sub getheader {
  # Inhalt wird von js-Funktionen dynamisch gefuellt
  return "<div class=\"headmiddle\">&nbsp;</div>\n"; # ohne echten div-Inhalt werden icons nicht erzeugt
}

# sub getfooter()
# Erzeugt das footer-div fuer die html-Seiten
sub getfooter {
  # Inhalt von footer_left wird von js-Funktionen dynamisch gefuellt
  my $footer = "<div id=\"footerleft\"></div>" .
               "<div id=\"footerright\">" . $config{parameter}{footer_right} . "</div>" .
               "<div id=\"footermiddle\">" . $config{parameter}{footer_middle} . "</div>\n";
  return $footer;
}


# Uebersetzt die alten (VEMA) Iconnamen in die neuen Dateiprefixe, im alten Design geschieht diese Uebersetzung im default.css
# Parameter: Der Iconstring
sub translateoldicons {
  my ($icon) = @_;
  
  if ($icon eq "beweis") { $icon = "book"; }
  if ($icon eq "anwdg") { $icon = "exclam"; }
  if ($icon eq "home") { $icon = "hfol"; }
  if ($icon eq "genetisch") { $icon = "booki"; }
  if ($icon eq "info") { $icon = "ibox"; }
  if ($icon eq "aufgb") { $icon = "check"; }
  if ($icon eq "weiterfhrg") { $icon = "bookast"; }

  return $icon;
}


# Erzeugt das navigations-div fuer die html-Seiten
# Parameter: icon (Klassenname) und Anker (HTML-String der a-Tag enthalten sollte)
sub createTocButton {
  my ($icon, $anchor) = @_;
  
  return "<div class=\"$icon\">" . $anchor . "</div>\n";
}

# Erzeugt das navigations-div fuer die html-Seiten
# Parameter: Das Seitenobjekt
sub getnavi {
  my ($site) = @_;

  my $p;
  my $navi = "";
  $navi .= "<!--ZOOMSTOP-->\n";

  # Link auf die vorherige Seite
  $p = $site->navprev();
  my $ac = $config{strings}{button_previous};
  my $icon = "nprev";
  if (($site->{XCONTENT} == 1) and (!($p))) {
    if ($site->{XPREV} != -1) {
      $p = $site->{XPREV};
      $icon = "xnprev";
    }
  }
  my $anchor;
  if (($p) and ($site->{LEVEL} == $contentlevel)) {
    $anchor = "<a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $p->link() . ".{EXT}\">$ac</a>";
  } else {
    $icon = $icon . "g";
    $anchor = $ac;
  }
  $navi .= "<div class=\"$icon\">" . $anchor . "</div>\n";

  # Link auf die naechste Seite
  $p = $site->navnext();
  $ac = $config{strings}{button_next};
  $icon = "nnext";
  if (($site->{XCONTENT} == 1) and (!($p))) {
    if ($site->{XNEXT} != -1) {
      $p = $site->{XNEXT};
      $icon = "xnnext";
    }
  }
  if (($site->{LEVEL} == ($contentlevel-2)) and ($site->{XNEXT} ne -1)) {
    # Von Modulhauptseite kommt man mit "Weiter" auf die erste contentseite
    $p = $site->{XNEXT};
    $icon = "xnnext";
  }
  if (($site->{LEVEL} == ($contentlevel-3)) and ($site->{XNEXT} ne -1)) {
    # Von FB-Hauptseite kommt man mit "Weiter" auf die erste Modulhauptseite
    $p = $site->{XNEXT};
    $icon = "xnnext";
  }

  if (($p) and (($site->{LEVEL}==$contentlevel) or ($site->{LEVEL}==($contentlevel-2)) or ($site->{LEVEL}==($contentlevel-3)))) {
    $anchor = "<a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $p->link() . ".{EXT}\">$ac</a>";
  } else {
    $icon = $icon . "g";
    $anchor = $ac;
  }
  $navi .= createTocButton($icon, $anchor);

  # Links auf die subsubsections im gleichen Teilbaum
  $navi .= "<ul>\n";

    if ($site->{LEVEL}!=$contentlevel) {
      if ($site->{XCONTENT}==3) {
        # Link auf Aufgabenstellung bei Loesungsseiten
	$navi .= "  <li class=\"inormalbutton_book\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $site->{BACK}->link() . ".{EXT}\">" . "Zum Modul" . "</a></li>\n";
      } else {
        # Link auf Modulstart setzen bei hoeheren Ebenen
	my $pp = $site;
	if ($pp->{LEVEL}!=$contentlevel) {
	  my @sp = @{$pp->{SUBPAGES}};
	  $pp = $sp[0];
	}
	if ($pp->{HELPSITE} eq 0) {
	  $navi .= "  <li class=\"inormalbutton_book\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $pp->link() . ".{EXT}\">" . $config{strings}{module_starttext} . "</a></li>\n";
	} else {
	  $navi .= "  <li class=\"inormalbutton_book\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $pp->link() . ".{EXT}\">" . "Mehr Informationen" . "</a></li>\n";
	}
      }
    }

    my $parent;
    if ($parent = $site->{PARENT}) {
      my @pages = @{$parent->{SUBPAGES}};
      for ( $i=0; $i <= $#pages; $i++ ) {
	my $p = $pages[$i];
	my $attr ="normal";
	if ($p->secpath() eq $site->secpath()) { $attr = "selected"; }
	my $icon = $p->{ICON};
	if ($icon eq "STD") { $icon = "book"; }
	$icon = translateoldicons($icon);
	my $cap = $p->{CAPTION};
	if ($icon ne "NONE") {
	  $icon = "button_" . $icon;
	  if (($p->{DISPLAY}) and ($site->{LEVEL}==$contentlevel)) {
	    # Knopf fuer Seite normal darstellen
	    $navi .= "  <li class=\"" . "i$attr$icon" . "\"><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p->link() . ".{EXT}\">" . $cap . "</a></li>\n";
	  } else {
	    if ($site->{LEVEL}!=$contentlevel) {
	      # Keine Navigationsbuttons wenn auf oberer Ebene
	    } else
	    {
	      # Knopf fuer gesperrte Seite ausgrauen und nicht verlinken
	      $navi .= "  <li class=\"" . "igrey$icon" . "\">" . $cap . "</li>\n";
	    }
	  }
	}
      }
    }

  $navi .="</ul>\n";

  $navi .="<!--ZOOMRESTART-->\n";		

  return $navi;
}


# Liefert das anklickbare Logo fuer die Hauptseite als HTML-String
# Parameter: Das Seitenobjekt
sub getlogolink {
  my ($p) = @_;
  
  my $r = "";
  
  if ($config{parameter}{mainlogo} eq "") {
    if ($mainsiteline eq 1) { $r = "<a class=\"MINTERLINK\" href=\"" . $p->linkpath() . "../index.html\">Hauptseite</a>"; }
  } else {
    $r = "<img style=\"\" src=\"" . $p->linkpath() . "../images/" . $config{parameter}{mainlogo} . "\"><br /><br />";
    if ($mainsiteline eq 1) {  $r .= "<a class=\"MINTERLINK\" href=\"" . $p->linkpath() . "../index.html\">Hauptseite</a>"; }
  }

  return $r;
}

# Liefert das Eingabecheckfeld als HTML-String
# Parameter: Das Seitenobjekt
sub getinputfield {
  my ($p) = @_;

  my $s = "<div id=\"NINPUTFIELD\" data-bind=\"evalmathjax: ifobs\"></div><br />";
  $s .= "<textarea name=\"NUSERMESSAGE\" id=\"UFIDM\" rows=\"4\" style=\"background-color:\#CFDFDF; width:200px; overflow:auto; resize:none\"></textarea><br /><br />";
  return "<br />";
}

# Erzeugt das toccaption-div fuer die html-Seiten im Menu-Style
# Parameter: Das Seitenobjekt
sub gettoccaption_menustyle {
  my ($p) = @_;
  my $c = "";

  logMessage($VERBOSEINFO, "gettoccaption_menustyle called on page " . $p->{TITLE});

  # Nummer des gerade aktuellen Fachbereichs ermitteln
  my $pp = $p;
  my $fsubi = -1;  
  while ($pp->{LEVEL}!=($contentlevel-3)) {
    if ($pp->{LEVEL}==$contentlevel-2) { $fsubi = $pp->{ID}; }
    $pp = $pp->{PARENT};
  }

  my $attr = "";
  my $root = $p->{ROOT};
  my @pages1 = @{$root->{SUBPAGES}};
  my $n1 = $#pages1 + 1;

  # $c .= "<div class=\"toccaption\">" .  getlogolink($p) . "</div>\n"; # Alte Version mit Logo
  $c .= "<div class=\"toccaption\"></div>\n"; # Neue Version ohne Logo

 
  
    # Duenner TU9-Layout mit einzelnen Aufklappunterpunkten
    $c .= "<tocnavsymb><ul>";
    $c .= "<li><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . "../$chaptersite\" target=\"_new\"><div class=\"tocmintitle\">Kursinhalt</div></a>";
    $c .= "<div><ul>\n";
   
    my $i1 = 0; # eigentlich for-schleife, aber hier nur Kursinhalt
    my $p1 = $pages1[$i1];
    if ($p1->{ID} == $p->{ID}) { $attr = " class=\"selected\""; } else { $attr = " class=\"notselected\""; }
    $attr = "";
    my $ff = $i1 + 1;

    # Fachbereiche ohne Nummern anzeigen
    my $ti = $p1->{TITLE};
    $ti =~ s/([12345] )(.*)/$2/ ;
    # $c .= "<li$attr><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p1->link() . ".{EXT}\">" . $ti . "</a>\n"; 

    my @pages2 = @{$p1->{SUBPAGES}};
    my $i2;
    my $n2 = $#pages2 + 1;
    if ($n2 > 0) {
      # $c .= "  <div><ul>\n";
      for ( $i2=0; $i2 < $n2; $i2++ ) {
        my $p2 = $pages2[$i2];
        # $ti = $p2->{TITLE};
        # $ti =~ s/([0123456789]+?)[\.]([0123456789]+)(.*)/$2\.$3/ ;
        $ti = $i2;
        my $selected = 0;
        # pruefen ob Knoten oder oberknoten der aktuell auszugeben Seite ($site) das $p2 ist
        my $test = $p;
        while ($test->{PARENT} != 0) {
          if ($p2->{ID} == $test->{ID}) { $selected = 1; }
          $test = $test->{PARENT};
        }
        # Stil der tocminbuttons wird in intersite.js gesetzt
        $c .= "  <li><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p2->link() . ".{EXT}\"><div class =\"tocminbutton\">" . "Kapitel " . ($ti + 1) . "</div></a>\n";
        if ($fsubi ne -1) {
          # Untereintraege immer einfuegen im neuen Stil
          # if ($fsubi == $p2->{ID}) {
          my @pages3 = @{$p2->{SUBPAGES}};
          my $i3;
          my $n3 = $#pages3 + 1;
          # print "TOC:     lvl3 hat $n3 Eintraege\n";
          if ($n3 > 0) {
            $c .= "    <div><ul>\n";
            for ( $i3 = 0; $i3 < $n3; $i3++ ) {
              my $p3 = $pages3[$i3];
              if ($selected == 1) {
                my $tsec = $p3->{NR}.$p3->{TITLE};
                $tsec =~ s/([0123456789]+?)[\.]([0123456789]+)(.*)/<div class=\"xsymb\">$1\.$2<\/div>&nbsp;/ ;
                
                
                
                my @pages4 = @{$p3->{SUBPAGES}};
                my $a;
                for ($a = 0; $a <= $#pages4; $a++) {
                  my $p4 = $pages4[$a];
                  $tsec .= "<a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p4->link() . ".{EXT}\">" . $p4->{TOCSYMB} . "</a>\n";
                }
                
                
                $c .= "    <li><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p3->link() . ".{EXT}\">" . $tsec . "</a></li>\n";
              }
            }
            $c .= "    </ul></div>\n"; # level3-ul
          }
        } # if subsection notwendig
        $c .= "  </li>\n";
      }
    }
    $c .= "\n";
    $c .= "</ul></div>";
    $c .= "</li>";
    $c .= "</ul></tocnavsymb>"; # level1-ul
    
  $c .= "<br /><br />";
  
  # Symbole komplett in Kopfleiste und von intersite.js erzeugt

  return $c;
}

# Erzeugt das content-div fuer die html-Seiten
# Parameter: Das Seitenobjekt
sub getcontent {
  my ($p) = @_;
  my $content = "";
  $content .= "<hr />\n{CONTENT}";
  $content .= "<hr />\n"; # </div> entfernt !
  my $contentx = $p->{TEXT};
  $content =~ s/{CONTENT}/$contentx/;
  
  return $content;	
}


sub storelabels {
	my ($p) = @_;
  
	my (@subpages, $i, $divcontent, $lab, $sub, $sec, $ssec, $sssec, $type, $pl, $linkpath, $link);
	@subpages = @{$p->{SUBPAGES}};

	if ($p->{DISPLAY}) {
		$linkpath = "../" . $p->linkpath();
		$link = "mpl/" . $p->link();
		$divcontent = $p->{TEXT};


		# Labels aus dem Content in die globale Labelliste eintragen
		# Aus mintmod: <!-- mmlabel;;LABELBEZEICHNER;;SUBJECTAREA;;SECTION;;SUBSECTION;;OBJEKTTYP;;ANCHORTAG; //-->
		while ($divcontent =~ s/<!-- mmlabel;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?); \/\/-->// ) {
                    $lab = $1;
                    $sub = $2;
                    $sec = $3;
                    $ssec = $4;
                    $sssec = $5;
                    $type = $6;

                    # Falls das Label in einer Matheumgebung gesetzt wurde, stehen die Attribute (bis auf den String $1) in einem <mn>-Tag
                    $sub =~ s/<mn>//g ;
                    $sec =~ s/<mn>//g ;
                    $ssec =~ s/<mn>//g ;
                    $sssec =~ s/<mn>//g ;
                    $type =~ s/<mn>//g ;
                    $sub =~ s/<\/mn>//g ;
                    $sec =~ s/<\/mn>//g ;
                    $ssec =~ s/<\/mn>//g ;
                    $sssec =~ s/<\/mn>//g ;
                    $type =~ s/<\/mn>//g ;

                    $pl = $link . ".html" . "\#" . $lab; # Absoluter link auf das Label
                    push @LabelStorage, [ $lab, $sub, $sec, $ssec, $sssec, $type, $pl];
                    logMessage($VERBOSEINFO, "Added label $lab in FB $sub with number $sec.$ssec.$sssec and type $type, pagelink = $pl");
		}

		$p->{TEXT} = $divcontent;
	}


	logMessage($VERBOSEINFO, "There are $#subpages subpages");
	for ( $i=0; $i <= $#subpages; $i++ ) {
		storelabels($subpages[$i]);
	}

	return;
}


# =====================
# = Objekte schreiben =
# =====================
# 
# sub printpages()
# Erzeugt rekursiv die Seiten fuer die einzelnen Objekte
# Parameter
# 	$outputfolder	Ordner, in dem alle Dateien geschrieben werden
sub printpages {
	my ($p, $outputfolder) = @_;
	my ($title, $text, $output, $link, $textmpl, @subpages, $i);
	
	logMessage($VERBOSEINFO, "printpages started for " . $p->{TITLE});

	if ($p->{LEVEL} == ($contentlevel-2)) {
	  logMessage($VERBOSEINFO, "Verarbeite Modul " . $p->{TITLE} . ", LEVEL = " . $p->{LEVEL});
	}

	if ($p->{LEVEL} == ($contentlevel-3)) {
	  logMessage($VERBOSEINFO, "Verarbeite Modul " . $p->{TITLE} . ", LEVEL = " . $p->{LEVEL} . " (Fachbereich)");
	}

	#hole Unterseiten
	@subpages = @{$p->{SUBPAGES}};
	
	#falls die Seite ausgegeben werden soll
	if ($p->{DISPLAY}) {

		logMessage($VERBOSEINFO, "  DISPLAY im Modul aktiv, erzeuge Ausgabe");

		my $linkpath = "../" . $p->linkpath();
		my $link = "mpl/" . $p->link();
		

		my $divhead = updatelinks(getheader(),$linkpath);
		my $divfooter = updatelinks(getfooter(),$linkpath);
		# Kein update erforderlich da $p verwendet wird:
		my $divnavi = getnavi($p); 
		#my $divtoccaption = gettoccaption($p);
		my $divtoccaption = gettoccaption_menustyle($p);
		my $divcontent = getcontent($p);

		# Makro {XSECTIONPREFIX} expandieren
		my $secprefix = "";
		my $q = $p->{PARENT};
		while ($q) {
		  if (($q->{LEVEL} > 0) and ($q->{TITLE} ne "")) {
		    my $ti = $q->{TITLE};
		    $ti =~ s/(.*?) (.*)/$2/g; # Modulnummerprefix aus dem Titel entfernen
		    if ($secprefix ne "") {
		      $secprefix = $ti . "  - " . $secprefix;
		    } else {
		      $secprefix = $ti;
		    }
		  }
		  $q = $q->{PARENT};
		}

		$divcontent =~ s/{XCONTENTPREFIX}/$secprefix/ ;


		# Zeilenumbrueche hinter h4 (MSubsubsectionx) verhindern
		$divcontent =~ s/<\/h4>([ \n]*)<div class=\"p\"><!----><\/div>/<\/h4>\n/g ;

		# Doppelte Zeilenumbrueche zusammenfassen
		$divcontent =~ s/<div class=\"p\"><!----><\/div>([ \n]*)<div class=\"p\"><!----><\/div>/<div class=\"p\"><!----><\/div>/g ;

		# Potentielle Zeilenumbrueche expandieren
		$divcontent =~ s/<div class=\"p\"><!----><\/div>/<br clear=\"all\"\/><br clear=\"all\"\/>/g ;

		# Reference-Tags aus mintmod expandieren
		my $sec = "";
		my $ssec = "";
		my $refindex = "";
		my $objtype = 0;
		my $fb = -1;
		while ($divcontent =~ /<!-- mmref;;(.+?);;(.+?); \/\/-->/ ) {
		  # Expandiere MRef
		  logMessage($VERBOSEINFO, "Expandiere Link $1");
		  my $lab = $1; # Labelstring
		  my $prefi = $2; # 0 -> Nur Nummer, 1 -> Mit Wortprefix (z.B. "Abbildung 3")
		  my $href = "";
		  my $objtype = 0;
		  my $found = 0;
		  for ($i=0; $i <= $#LabelStorage; $i++ ) {
		    if ($LabelStorage[$i][0] eq $lab) {
		      $found = 1;
		      $href = $linkpath . $LabelStorage[$i][6];
		      $sec = $LabelStorage[$i][2];
		      $ssec = $LabelStorage[$i][3];
		      $refindex = $LabelStorage[$i][4];
		      $objtype = $LabelStorage[$i][5];
		      $fb = $LabelStorage[$i][1];
		    }
		  }

		  if ($found eq 0) {
		    logMessage($CLIENTWARN, "Label $lab wurde nicht in interner Labelliste gefunden");
		    $objtype = 0;  
		  }

      # Abhaengig vom Fachbereich und des Typs die Darstellungsart waehlen
      # Aus mintmod.tex:
      # \def\MTypeSection{1}
      # \def\MTypeSubsection{2}
      # \def\MTypeSubsubsection{3}
      # \def\MTypeInfo{4}
      # \def\MTypeExercise{5}
      # \def\MTypeExample{6}
      # \def\MTypeExperiment{7}
      # \def\MTypeGraphics{8}
      # \def\MTypeTable{9}
      # \def\MTypeEquation{10}
      # \def\MTypeTheorem{11}
      # \def\MTypeVideo{12}

      # Zusatzinformation nur fuer MCRef
      my $ptext = "";
      my $reftext = "";
      
      switch ($objtype) {
        case "1" {
          # sections sind Modulnummern, sie werden nur als Zahl dargstellt. Der Index und die subsection spielen keine Rolle.
          $reftext = "$sec";
          $ptext = "Modul";
        }

        case "2" {
          # subsections sind Unterabschnitte in Modulen, sie werden nur als zweifache Zahl dargstellt. Der Index spielt keine Rolle.
          $reftext = "$sec.$ssec";
          $ptext = "Abschnitt";
        }

        case 3 {
          # subsections sind Unterunterabschnitte in Modulen, sie werden als dreifache Zahl dargstellt, der Index ist die subsub-Nummer
          $reftext = "$sec.$ssec.$refindex";
          $ptext = "Unterabschnitt";
        }

        case 4 {
          # Eine Infobox, wird in den Fachbereichen Mathe/Info dreistellig referenziert, sonst hat sie garkeine Nummer
          $ptext = "Infobox";
          if (($fb eq 1) or ($fb eq 2)) {
            $reftext = "$sec.$ssec.$refindex";
          } else {
            $reftext = "";
            logMessage($CLIENTWARN, "Verweis $lab auf eine Infobox im Fachbereich $fb ohne Infonummern");
          }
        }

        case 5 {
          # Eine Aufgabe, wird in allen Fachbereichen dreistellig referenziert
            $ptext = "Aufgabe";
            $reftext = "$sec.$ssec.$refindex";
        }

        case 6 {
          # Eine Beispielbox, wird in Mathe/Info/Chemie/Physik dreistellig referenziert
          $ptext = "Beispiel";
          $reftext = "$sec.$ssec.$refindex";
        }

        case 7 {
          # Eine Experimentbox, wird in Mathe/Info/Chemie/Physik dreistellig referenziert
          $ptext = "Experiment";
          $reftext = "$sec.$ssec.$refindex";
        }

        case 8 {
          # Eine Grafik, wird in allen Fachbereichen einstellig referenziert, in Chemie dreistellig
          $ptext = "Abbildung";
          if ((($fb eq 1) or ($fb eq 2) or ($fb eq 4)) and ($prefi == 0)) {
            $reftext = "$refindex";
          } else {
            $reftext = "$sec.$ssec.$refindex";
          }
        }

        case 9 {
          # Eine Tabelle, wird in allen Fachbereichen einstellig referenziert, in Chemie dreistellig
          $ptext = "Tabelle";
          if ((($fb eq 1) or ($fb eq 2) or ($fb eq 4)) and ($prefi == 0)) {
            $reftext = "$refindex";
          } else {
            $reftext = "$sec.$ssec.$refindex";
          }
        }

        case 10 {
          # Eine Gleichung, wird in allen Fachbereichen dreistellig referenziert und bekommt Klammern um die Nummer
          # Bei Gleichungsnummern wird MLastIndex in mintmod.tex kuenstlich auf den Zaehler "equation" gesetzt
          $ptext = "Gleichung";
          $reftext = "($sec.$ssec.$refindex)";
        }

        case 11 {
          # Ein theorem oder theoremx wird in Mathe/Info/Physik dreistellig referenziert, in der Chemie einstellig
          $ptext = "Satz";
          if ((($fb eq 1) or ($fb eq 2) or ($fb eq 4)) and ($prefi == 0)) {
            $reftext = "$sec.$ssec.$refindex";
          } else {
            $reftext = "$refindex";
          }
        }

        case 12 {
          # Ein Video, wird in allen Fachbereichen einstellig referenziert, in Chemie dreistellig
          $ptext = "Video";
          if ((($fb eq 1) or ($fb eq 2) or ($fb eq 4)) and ($prefi == 0)) {
            $reftext = "$refindex";
          } else {
            $reftext = "$sec.$ssec.$refindex";
          }
        }

        case 13 {
          # Schlagworter (entries) in Modulen, nur die Position x.y.z wird angegeben
          $reftext = "$sec.$ssec";
          $ptext = "Modul";
        }

        
        else {
          logMessage($CLIENTWARN, "MRef konnte Objekttyp $objtype aus Label $lab nicht verarbeiten");
          $reftext = "";
        }
      }

      my $nrl = noregex($lab);
      
      if ($reftext ne "" ) {
        if ($prefi == 1) { $reftext = $ptext . " " . $reftext; }
        $divcontent =~ s/<!-- mmref;;$nrl;;$prefi; \/\/-->/<a class="MINTERLINK" href=\"$href\">$reftext<\/a>/g ;
      } else {
	push @converrors, "ERROR: Konnte Label $lab nicht aufloesen!\n";
	$divcontent =~ s/<!-- mmref;;$nrl;;$prefi; \/\/-->/(Verweis?)/g ;
      }
}

		while ($divcontent =~ /<!-- msref;;(.+?);;(.+?); \/\/-->/s ) {
		  # Expandiere MSRef
		  logMessage($VERBOSEINFO, "Expandiere Link $1 mit Titel $2");
 		  my $lab = $1;
 		  my $txt = $2;
                  my $nrl = noregex($lab);
		  my $href = "";
		  for ($i=0; $i <= $#LabelStorage; $i++ ) {
		    if ($LabelStorage[$i][0] eq $lab) {
		      $href = $linkpath . $LabelStorage[$i][6];
		    }
		  }
  
                  my $nrt = noregex($txt);

                    if ($href ne "") {
		    $divcontent =~ s/<!-- msref;;$nrl;;$nrt; \/\/-->/<a class="MINTERLINK" href=\"$href\">$txt<\/a>/g ;
		  } else {
		    push @converrors, "ERROR: Konnte Label $lab mit Text $txt nicht aufloesen!\n";
		    $divcontent =~ s/<!-- msref;;$lab;;$nrt; \/\/-->/(Verweis?)/g ;
		  }
		}

		#MathPlayer-Ersetzungen fuer die Math-Tags
# 		$divcontent =~ s/<m/<m:m/g;
# 		$divcontent =~ s/<\/m/<\/m:m/g;

		# Kopf der Seite erzeugen
		my $text = updatelinks($templatempl, $linkpath);

		#Stylesheet einsetzen
		my $tags = getstyleimporttags($linkpath);
		$text =~ s/<\/head/$tags<\/head/;

   



		$text .= "<div id=\"fixed\">\n";
		$text .= "<div class=\"head\">\n"   . $divhead       . "</div>\n";
		$text .= "<div class=\"toc\">\n"    . $divtoccaption . "</div>\n";
		$text .= "<div class=\"navi\">\n"   . $divnavi       . "</div>\n";
		$text .= "<div id=\"footer\">\n"    . $divfooter     . "</div>\n";
		$text .= "</div>\n";
		$text .= "<div id=\"notfixed\">\n";
		$text .= "<div class=\"head\">\n"   . $divhead       . "</div>\n";
		$text .= "<div class=\"toc\">\n"    . $divtoccaption . "</div>\n";
		$text .= "<div class=\"navi\">\n"   . $divnavi       . "</div>\n";
		$text .= "<div id=\"content\"><div id=\"text\"><div class=\"text\">\n"   . $divcontent    . "</div></div></div>\n";
		$text .= "</div>\n";


		# --------------

		#Titel der Seite einfuegen
		$title = $p->titlestring();
		$text =~ s/{TITLE}/$title/g;
		  
		
		#Endungen setzen
		$text =~ s/{EXT}/html/g;
		  
		#Zusatzpfad
		$text =~ s/{MATHMLPATH}/mpl\//g;


		# Abschluss der Seite
		$text .= $templatefooter;
	      

		#Postprocessing
  	        $text = postprocess($p,$text,"$outputfolder/$link");

                my $dname = $p->{DOCNAME};
  	        my $extension = "html";
  	        my $docname = "$link.$extension";
                my $fullpath = "$outputfolder/$docname";
  	        

                # Nummer des gerade aktuellen Fachbereichs (chapters) und Folgenummern ermitteln
                my $pp = $p;
                my $idstr = "";
                my $ssn = -1;
                while ($pp->{LEVEL} != ($contentlevel-4)) {
                    if ($pp->{LEVEL} == ($contentlevel-2)) { $ssn = $pp->{NR}; }
                    if ($idstr eq "") {
                      $idstr = $pp->{POS};
                    } else {
                      $idstr = $pp->{POS} . "." . $idstr;
                    }
                    $pp = $pp->{PARENT};
                }
  	        
  	        # Eigenen Dateinamen und Pfade als JS-Variable verfuegbar machen
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_ID = \"$idstr\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_UXID = \"$p->{UXID}\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SECTION_ID = $ssn;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var docName = \"$dname\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var fullName = \"$docname\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var fullNamePath = \"$fullpath\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var linkPath = \"$linkpath\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;

		#Ausgabe
		writefile($fullpath, $text);

		# Separate Exportdateien erzeugen
		my $fc = 1 + $#{$p->{EXPORTS}};
		if ($fc != 0) { logMessage($VERBOSEINFO, "Generiere $fc zusaetzliche Exportdateien"); }
  	        for ($i = 0; $i < $fc; $i++ ) {
  	          my $fname = ${$p->{EXPORTS}}[$i][0];
  	          writefile("$outputfolder/$link$fname", ${$p->{EXPORTS}}[$i][1]);
  	       }
  	       
		
	} else {
		# display == false
		# print "schreibe nicht " . $p->{NR} . "\n";
		logMessage($VERBOSEINFO, "NODISPLAY fuer $p->{TITLE}");
	}
	
	#Rekursion auf Unterseiten
	for ( $i=0; $i <= $#subpages; $i++ ) {
		printpages($subpages[$i], $outputfolder);
	}
}


#------------------------------------------------ ENDE NEUES DESIGN ---------------------------------------------------------------------------------------



# =========================
# = Objekt-Manipulationen =
# =========================

# 
# sub linkupdate()
# haenge den uebergebenen Text vor alle Links, die nicht absolut sind
# Parameter
#	$p			Objekt einer Seite
# 	$prepend	Text
sub linkupdate {
	my($p, $prepend) = @_;
	my (@subpages, $i, $text, $linkpath, $prepend2);
	
	if ($p->{TEXT} ne "") {
		#hole Text
		$text = $p->{TEXT};


		#haenge auch linkpath vor alle Links
		$prepend2 = $prepend . $p->linkpath();
		logMessage($VERBOSEINFO, "Setze $prepend2 vor alle Links");
		#Links aktualisieren
		$text = updatelinks($text, $prepend2);
		#speichern
		$p->{TEXT} = $text;
	}
	#Rekursion auf Unterseiten
	@subpages = @{$p->{SUBPAGES}};
	for ( $i=0; $i <=$#subpages; $i++ ) {
		linkupdate($subpages[$i], $prepend);
	}
}

# 
# sub updatelinks()
# haengt Text vor alle nicht absoluten Links
# Parameter
# 	$text		Text, der bearbeitet wird
#	$prepend	Text, der vorgehaengt wird
sub updatelinks {
	my ($text, $prepend) = @_;

	if ($prepend ne "") {
		# Erstmal tex-Makro MMaterial expandieren falls es direkt im HTML eingegeben wurde
		$text =~ s/\\MMaterial/:localmaterial:/g;

    $text =~ s/(src|href)=("|')(?!(\#|https:\/\/|http:\/\/|ftp:\/\/|mailto:|:localmaterial:|:directmaterial:))/$1=$2$prepend/g;


		$text =~ s/<param name=("|')movie("|') value=(\"|\')(?!(https|http|ftp))/$&$prepend/g;
 		$prepend =~ s/\//\\\//g;

    # $text =~ s/,("|')(?!(\#|'|"|http:\/\/|ftp:\/\/|mailto:|:localmaterial:|:directmaterial:))/,$1$prepend/g;
    if ($text =~ /,("|')(?!(\#|'|"|https:\/\/|http:\/\/|ftp:\/\/|mailto:|:localmaterial:|:directmaterial:))/ ) {
      logMessage($VERBOSEINFO, "Kombination Marker mit Protokollname noch im Dokument gefunden");
    }


    # Lokale Dateien befinden sich im gleichen Ordner ohne Prefix
		$text =~ s/:localmaterial:/./g;
		$text =~ s/:directmaterial://g;
	}
	return $text;
}


# 
# sub hidepageswotext()
# setztt die DISPLAY-Eigenschaft bei allen Seiten auf 0, die keinen Inhalt haben
# Parameter
# 	$p		Objekt einer Seite
sub hidepageswotext {
	my($p) = @_;
	my (@subpages, $i);
	
	if ($p->{TEXT} eq "") {
		$p->{DISPLAY} = 0;
		logMessage($VERBOSEINFO, "  Page " . $p->{TITLE} . " versteckt");
	}
	#Rekursion auf Unterseiten
	@subpages = @{$p->{SUBPAGES}};
	for ( $i=0; $i <=$#subpages; $i++ ) {
		hidepageswotext($subpages[$i]);
	}
}

# 
# sub createtocs()
# Setzt die tableofcontents an den gegebenen Markierungen ein
# Parameter
#   $p    Objekt einer Seite
sub createtocs {
  my ($p) = @_;

  logMessage($VERBOSEINFO, "    Seite " . $p->{TITLE});

  
  my @subpages = @{$p->{SUBPAGES}};
  my $toc = "Inhalte:<br />";

  # Inhaltsverzeichnis enthaelt die DIREKTEN Unterseiten der aktuellen Seite

  my $i;
  for ($i = 0; $i <= $#subpages; $i++) {
    my $lk = $subpages[$i]->link() . ".{EXT}";
    $toc = $toc . "<a class=\"MINTERLINK\" href='" . $lk ."'>" . $subpages[$i]->{TITLE} . "</a><br />";
  }

  my $text = $p->{TEXT};
  if ($text =~ s/<!-- toc -->/$toc/g) { $p->{TEXT} = $text; }

  #Rekursion auf Unterseiten
  logMessage($VERBOSEINFO, "  Iteriere über " . $#subpages . " Unterseiten");
  for ($i=0; $i <= $#subpages; $i++) {
    createtocs($subpages[$i]);
  }
}
  
  #Lese alle Link-Anker und speicher in dem hash %links,
  #auf welcher Seite die Anker auftauchen

# 
# sub relocatehelpsection()
# Richtet spezielle Eigenschaften der Hilfesektion ein und setzt sie richtig ein
# Parameter
# 	$p		Objekt einer Seite
# 	$h		0: Unbekannter Teil des Baums   1: Im Hilfeteil
sub relocatehelpsection {
  my($p, $h) = @_;
  my @subpages = @{$p->{SUBPAGES}};
  

  if ($h == 0) {
    if ($p->{TITLE} =~ m/(.*)HELPSECTION(.*)/ ) {
      logMessage($CLIENTINFO, "Hilfesektion wird eingerichtet");
      $h = 1;
      $p->{TITLE} = $1 . "Einstiegsseite" . $2;
    }
  }

  $p->{HELPSITE} = $h;
  #Rekursion auf Unterseiten
  my $i;
  for ( $i=0; $i <= $#subpages; $i++ ) {
	    relocatehelpsection($subpages[$i], $h);
  }

}

# 
# sub createlinks()
# korregiert seiteninterne Links
# Parameter
# 	$p		Objekt einer Seite
sub createlinks {
	my ($p) = @_;
	our %links;
	
	#Lese alle Link-Anker und speicher in dem hash %links,
	#auf welcher Seite die Anker auftauchen
	readlinks($p);
	#Ersetze die Links auf diese Anker
	writelinks($p);
	
	# sub readlinks()
	# Parameter
	# 	$p		Objekt einer Seite
	sub readlinks {
		my ($p) = @_;
		my (@subpages, $i, $text, @pagelinks);
		$text = $p->{TEXT};
		
		#Suche alle Link-Anker
		@pagelinks = ($text =~ /<a [^>]*?name=".*?".*?>.*?<\/a>/sg);
		#itteriere ueber das Array und speichere die Seite, auf dem
		#der Link-Anker steht in einem Hash
		for ( $i=0; $i <=$#pagelinks; $i++ ) {
			$pagelinks[$i] =~ /name="(.*?)"/;
			$links{$1} = $p->link();
			logMessage($VERBOSEINFO, "    Link-Anker $1 gefunden");
		}
		#setze die class-Eigenschaft dieser Link-Anker auf "label" GEHT DAS NOCH MIT MINTERLINK???
		$text =~ s/<a (name=".*?".*?>\s*?<\/a>)/<a class="label" $1/sg;
		$p->{TEXT} = $text;
		#Rekursion auf Unterseiten
		@subpages = @{$p->{SUBPAGES}};
		for ( $i=0; $i <=$#subpages; $i++ ) {
			readlinks($subpages[$i]);
		}
	}
	
	# sub writelinks()
	# Parameter
	# 	$p		Objekt einer Seite
	sub writelinks {
		my ($p) = @_;
		my (@subpages, $i, $text, @pagelinks);
		$text = $p->{TEXT};
		my $linkpath = $p->linkpath();
		
		#itteriere ueber die im Hash gespeicherten Link-Anker
		my $link;
		foreach $link (keys %links) {
			my $page = $links{$link};
			#ersetze den Link auf diesen Anker
			$text =~ s/href="#$link"/href="$linkpath$page.{EXT}#$link"/g;
		}
		$p->{TEXT} = $text;
		#Rekursion auf Unterseiten
		@subpages = @{$p->{SUBPAGES}};
		for ( $i=0; $i <=$#subpages; $i++ ) {
			writelinks($subpages[$i]);
		}
	}
}


# 
# sub mathmloptimize()
# Optimierungen fuer den MathML-Code
# Parameter
# 	$p		Objekt einer Seite
sub mathmloptimize {
	my ($p) = @_;
	my (@subpages, $i);
	
	#Rekursion auf Unterseiten
	@subpages = @{$p->{SUBPAGES}};
	for ( $i=0; $i <=$#subpages; $i++ ) {
		mathmloptimize($subpages[$i]);
	}
	
	#Loesche den Text "Chapter" bei Kapiteln (GEHT DAS NOCH MIT MINTERLINK???)
	my $title = $p->{TITLE};
	if ($title =~ /^<a name=.*?>\n(Chapter )?(.*?)<\/a>(<br \/>|&nbsp;&nbsp;)(.*)$/) {
		#$title =~ /\n(.*?)<\/a>(<br \/>|&nbsp;&nbsp;)(.*)$/;
		#$title = "$1 $3";
		$title = "$2 $4";
		$p->{TITLE} = $title;
	}
	
	#Theorem-Umgebungen nicht kursiv, Kursiv-Befehle loeschen
	my $text = $p->{TEXT};
	$text =~ s/<em>//g;
	$text =~ s/<\/em>//g;

	#Ein Komma wird von ttm als Operator interpretiert
	#Dezimalzahlen in einem <mn>-Tag
	#$text =~ s/<mn>([0-9]*)<\/mn><mo>,<\/mo><mn>([0-9]*)<\/mn>/<mn>$1,$2<\/mn>/g;
	#auch fuer Dezimalzahlen mit Potenz
	#            Zahl vor dem Komma /  Komma    /      Potenz:          Basis                         Exponent
	$text =~ s/<mn>([0-9]*)<\/mn><mo>,<\/mo>(\n|\r)*<msup><mrow><mn>([0-9]*)<\/mn><\/mrow><mrow><mn>([0-9])<\/mn><\/mrow>(\n|\r)*<\/msup>/
	<msup><mrow><mn>$1,$3<\/mn><\/mrow><mrow><mn>$4<\/mn><\/mrow>\n<\/msup>/g;
	
	#MathML-Tabellen ohne Breitenangabe und Ausrichtung
	#diese wuerden grosse Lehrraeume erzeugen (IE)
	$text =~ s/<mtable([^>]+)>/<mtable>/g;
	
	#Abgesetzte Formeln nicht in Tabellen sondern in <center>-Tags
	$text =~ s/<table width="100%"><tr><td align="center">\s*(<math(.|\n)*?<\/math>)\s*<\/td><\/tr><\/table>/<center>$1<\/center>/g;
	
	#Das Zeichen \subsetneq kennt ttm nicht
	$text =~ s/\\subsetneq/<mtext>\&subne\;<\/mtext>/g;
	
	#mathbb-Zeichen
	#Reals, Integers usw
	#$text =~ s/\\mathbb<mi>N<\/mi>/<naturalnumbers\/>/g;
	#$text =~ s/\\mathbb<mi>Z<\/mi>/<integers\/>/g;
	#$text =~ s/\\mathbb<mi>Q<\/mi>/<rationals\/>/g;
	#$text =~ s/\\mathbb<mi>R<\/mi>/<reals\/>/g;
	#$text =~ s/\\mathbb<mi>C<\/mi>/<complexes\/>/g;
	#$text =~ s/\\mathbb<mi>P<\/mi>/<primes\/>/g;
	$text =~ s/\\mathbb<mi>[A-Za-z]<\/mi>/<mo>&$1opf;<\/mo>/g;
	#$text =~ s/\\([A-Za-z])/<mtext>&$1opf\;<\/mtext>/g;
	
	#die gewollten Abstaende in Formel sind zu breit. Ersetzung durch schmalere
	$text =~ s/<mi>&emsp;<\/mi>/<mi>&nbsp;<\/mi>/g; # \,
	$text =~ s/<mi>&emsp;&emsp;<\/mi>/<mi>&nbsp;&nbsp;<\/mi>/g; # \;
	$text =~ s/<mi>&emsp;&emsp;&emsp;<\/mi>/<mi>&nbsp;&nbsp;&nbsp;<\/mi>/g; # \quad
	$text =~ s/<mi>&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;<\/mi>/<mi>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<\/mi>/g; # doppel \quad
	
	#\empty ist kein Integer, sondern Text
	$text =~ s/<mi>\&empty\;<\/mi>/<mtext>\&empty\;<\/mtext>/g;
	
  # Direkter Text (vor allem oeffnende Klammern) vor einer $-Umgebung erhalten einen Zeilenumbruch im HTML
  # vor dem math-Tag, was zu einem zusaetzlichen Leerzeichen vor der Formel fuehrt. Der Zeilenumbruch wird entfernt:
  $text =~ s/\n<math/<math/gs;

  #Bei Tabellen mit Rahmen sollen auch die Zellen Rahmen haben
  $text =~ s/<table border=\"1\">((.|\s)*?)<\/table>/replacetd($1)/eg;

  $p->{TEXT} = $text;
}


# 
# sub replacetd()
# setzt innerhalb einer Tabelle die css-Klassen der Tabellenzellen
# die Funktion wird in einem regulaeren Ausdruck der Funktion optimize verwendet
# Parameter
# 	$text	Text, in dem die Ersetzungen durchgefuehrt werden
sub replacetd {
	my($text);
	$text = $_[0];
	$text =~ s/<td([^>]*?)>/<td $1 class=\"rahmen\">/g;
	return("<table border=\"1\" class=\"rahmen\">" . $text . "<\/table>");
}



# ===================
# = Hilfsfunktionen =
# ===================



# 
# sub loadtemplates()
# laedt die standard-Templates und MathJax (vor dem MathPlayer)
# Parameter
# 	keine
sub loadtemplates {
  if ($config{localjax} eq 1) {
    logMessage($CLIENTINFO, "Binde MathJax lokal ein, das Verzeichnis MathJax wird im html-Baum erzeugt!");
    loadtemplates_local();
    logMessage($CLIENTINFO, "MathJax wird lokal adressiert");
  } else {
    if ($config{localjax} eq 0) {
      logMessage($CLIENTINFO, "Binde MathJax ueber NetService (cdn 2.4) ein");
      loadtemplates_netservice();
      logMessage($CLIENTINFO, "MathJax wird ueber Netservice adressiert");
    } else {
      logMessage($CLIENTERROR, "Unbekannte MathJax-Quelle: " . $config{localjax});
    }
  }
}


# Momentan wird nur templatempl benutzt

sub getdoctype_oldhtml4 {
    logMessage($CLIENTINFO, "Erstelle HTML-Dokumente nach DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1");
    my $doctype = <<DENDE;
<!DOCTYPE html PUBLIC
"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN"
"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">
DENDE
    return $doctype;
}

sub getdoctype {
    logMessage($CLIENTINFO, "Erstelle Standard-HTML5-Dokumente ohne spezialisierte DTD");
    my $doctype = "<!DOCTYPE html>\n";
    return $doctype;
}

# ImageFonts von MathJax werden abgeschaltet, um die Verzeichnisse klein zu halten (erstmal nicht weil IE streikt)    (  imageFont: null)

# expires=0 verbietet caching der Seiten, sollte nur in Anlauf-Phase benutzt werden!

sub loadtemplates_local {
    my $s = <<ENDE;
<html xmlns:m="http://www.w3.org/1998/Math/MathML">
<head>
<meta http-equiv="expires" content="0">
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{TITLE}</title>
<script type="text/javascript" src="MathJax/MathJax.js?config=TeX-AMS-MML_HTMLorMML&locale=de"></script>
<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  config: [":directmaterial:TeX-AMS-MML_HTMLorMML.js"],
  jax: [":directmaterial:input/MathML",":directmaterial:input/TeX",":directmaterial:output/HTML-CSS",":directmaterial:output/NativeMML"],
  extensions: [":directmaterial:mml2jax.js",":directmaterial:MathMenu.js",":directmaterial:MathZoom.js"],
  "HTML-CSS": {
      scale: 100,
      minScaleAdjust: 80,
      mtextFontInherit: true,
      styles: {},
      noReflows: true,
      linebreaks: { automatic: false }
   },
  MMLorHTML: {
   prefer: {
    MSIE: "HTML",
    Firefox: "HTML",
    Safari: "HTML",
    Chrome: "HTML",
    Opera: "HTML",
    other: "HTML"
      }
    }
});
</script>
<!-- Headerversion MPL/localjax -->
</head>
<body onload="loadHandler()" onbeforeunload="unloadHandler()">
ENDE

    # Entfernt vor letztem </script>: <OBJECT ID=MathPlayer CLASSID="clsid:32F66A20-7614-11D4-BD11-00104BD3F987"></OBJECT>
    # Entfernt vor ENDE: <?IMPORT NAMESPACE="m" IMPLEMENTATION="#MathPlayer">

    
    my $dt = getdoctype();
    my $scotext = "";
    if ($config{doscorm} eq 1) {
      $scotext = $scoheader;
    }
    $templatempl = $dt . $s . $templateheader . $scotext;
    logMessage($VERBOSEINFO, "DT = $dt");
}

sub loadtemplates_netservice {
    my $s = <<ENDE;
<html xmlns:m="http://www.w3.org/1998/Math/MathML">
<head>
<meta http-equiv="expires" content="0">
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{TITLE}</title>
<script type="text/javascript" src="https://cdn.mathjax.org/mathjax/2.4-latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML&locale=de"></script>
<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  config: [":directmaterial:TeX-AMS-MML_HTMLorMML.js"],
  jax: [":directmaterial:input/MathML",":directmaterial:input/TeX",":directmaterial:output/HTML-CSS",":directmaterial:output/NativeMML"],
  extensions: [":directmaterial:mml2jax.js",":directmaterial:MathMenu.js",":directmaterial:MathZoom.js"],
  "HTML-CSS": {
      scale: 100,
      minScaleAdjust: 80,
      mtextFontInherit: true,
      styles: {},
      noReflows: true
   },
  MMLorHTML: {
   prefer: {
    MSIE: "HTML",
    Firefox: "HTML",
    Safari: "HTML",
    Chrome: "HTML",
    Opera: "HTML",
    other: "HTML"
      }
    }
});
</script>
<!-- Headerversion MPL/netservicejax -->
</head>
<body onload="loadHandler()" onunload="unloadHandler()">
ENDE
    my $dt = getdoctype();
    my $scotext = "";
    if ($config{doscorm} eq 1) {
      $scotext = $scoheader;
    }
    $templatempl = $dt . $s . $templateheader . $scotext;
    logMessage($VERBOSEINFO, "DT = $dt");
}

# --------------------------------------------- Zerlegung des Dokuments  ----------------------------------------------------------------------------------------------------------------------

sub converter_conversion {

logTimestamp("Starting conversion");

#Alte Daten loeschen
logMessage($CLIENTINFO, "Copying files into " . $config{outtmp});
system "rm -rf " . $config{outtmp};
system "mkdir -p " . $config{outtmp};
system "cp -R files/* " . $config{outtmp};
logMessage($CLIENTINFO, " ok");


logMessage($VERBOSEINFO, "Es werden " . ($#DirectHTML + 1) . " DirectHTML-Statements werden verwendet");

logTimestamp("Starting ttm tex->html converter");
system "./ttm-src/ttm -p./tex < tex/vorkursxml.tex 1>$xmlfile 2>$xmlerrormsg";
logTimestamp("Loading ttm output file $xmlfile");
my $text = loadfile($xmlfile);
my $ttm_errors = loadfile($xmlerrormsg);
my @ttm_errors = split("\n", $ttm_errors);

my $j = 0;

for ($i = 0; $i <= $#ttm_errors; $i++) {
  if ($ttm_errors[$i] =~ m/\*\*\*\* Unknown command (.+?), /s ) {
    logMessage($CLIENTWARN, "(ttm) " . $ttm_errors[$i]);
    push @converrors, "ERROR: ttm konnte LaTeX-Kommando $1 nicht verarbeiten";
    $j++;
  } else {
    logMessage($CLIENTINFO, "(ttm) " . $ttm_errors[$i]);
  }
}

if (($config{dorelease} eq 1) and ($j > 0)) {
      logMessage($CLIENTERROR, "ttm found $j unknown commands, not valid in release version!");
}

# Debug-Meldungen ausgeben
while ($text =~ s/<!-- debugprint;;(.+?); \/\/-->/<!-- debug;;$1; \/\/-->/s ) { logMessage($DEBUGINFO, $1); }

# Aufgabenpunktetabelle generieren
for ($i=0; $i <= 9; $i++ ) {
  push @sitepoints, 0;
  push @expoints, 0;
  push @testpoints, 0;
  push @sections, "";
}

while ($text =~ s/<!-- mdeclaresection;;(.+?);;(.+?);;(.+?);; \/\/-->//s ) { 
  if ($1 eq 1) { # besser Kursinhaltsseiten irgendwie erkennen
    my $l = $2 - 1;
    $sections[$l] = $3;
  }
}

while ($text =~ s/<!-- mdeclarepoints;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);; \/\/-->//s ) { 
  logMessage($VERBOSEINFO, "POINTS: Module $1, id $2, points $3, intest $4, chapter $5");
  if ($5 eq 1) {
    my $l = $1 - 1;
    $expoints[$l] += $3;
    if ($4 == "1") {
      $testpoints[$l] += $3;
    }
  }
}

while ($text =~ s/<!-- mdeclareuxid;;(.+?);;(.+?);;(.+?);; \/\/-->//s ) { 
  push @uxids, [$1, $2, $3];
}

while ($text =~ s/<!-- mdeclaresiteuxid;;(.+?);;(.+?);;(.+?);; \/\/-->/<!-- mdeclaresiteuxidpost;;$1;; \/\/-->/s ) { 
  push @siteuxids, $1;
  if ($2 eq 1) { $sitepoints[$3-1]++; }
}

my $ia = 0;
my $ib = 0;
for ( $ia = 0; $ia <=$#uxids; $ia++ ) {
  for ( $ib = $ia + 1; $ib <=$#uxids; $ib++ ) {
    if ($uxids[$ia][0] eq $uxids[$ib][0]) {
      my $tmpstr = "Gleiche uxid: " . $uxids[$ia][0] . " mit ids " . $uxids[$ia][2] . " und " . $uxids[$ib][2];
      push @converrors, $tmpstr;
    }
  }
}

for ( $ia = 0; $ia <=$#siteuxids; $ia++ ) {
  for ( $ib = $ia + 1; $ib <=$#siteuxids; $ib++ ) {
    if ($siteuxids[$ia] eq $siteuxids[$ib]) {
      my $tmpstr = "Gleiche siteuxid: " . $siteuxids[$ia];
      push @converrors, $tmpstr;
    }
  }
}


for ($i=0; $i <= 9; $i++ ) {
  logMessage($VERBOSEINFO, "Punkte in section " . ($i+1) . ": " . $expoints[$i] . ", davon " . $testpoints[$i] . " von Tests");
  logMessage($VERBOSEINFO, "Sites in section " . ($i+1) . ": " . $sitepoints[$i]);
}

if ($text =~ s/<!-- mlocation;;(.+?);;(.+?);;(.+?);; \/\/-->//s ) {
  $locationicon = $1;
  $locationlong = $2;
  $locationshort = $3;
  $locationsite = "location.html";
  logMessage($CLIENTINFO, "Verwende Standort-Deklaration für $locationlong");
} else {
  $locationsite = "";
  push @converrors, "Keine Standort-Deklaration gefunden, Standortbutton erscheint nicht im Kurs.";
}


# Alles ab 'File translated...' aus ttm-Ausgabe entfernen
$text =~ s/<hr \/><small>File translated from.*<\/body>.*//s;


$templateheader = generate_scriptheaders() . $templateheader . "\n";

if ($config{parameter}{feedback_service} ne "") {
  logMessage($CLIENTINFO, "FeedbackServer deklariert: " . $config{parameter}{feedback_service});
} else {
  push @converrors, "Kein FeedbackServer deklariert, es wird kein Feedback verschickt.";
}
if ($config{parameter}{data_server} ne "") {
  logMessage($CLIENTINFO, "DataServer deklariert: " . $config{parameter}{data_server});
  logMessage($CLIENTINFO, "Description: " . $config{parameter}{data_server_description});
} else {
  push @converrors, "Kein DataServer in Konfigurationsdatei deklariert (Parameter data_server)!";
}

if ($config{parameter}{exercise_server} ne "") {
  logMessage($CLIENTINFO, "ExerciseServer deklariert: " . $config{parameter}{exercise_server});
} else {
  push @converrors, "Kein ExerciseServer in Konfigurationsdatei deklariert (Parameter exercise_server)!";
}


# Hier pruefen ob ueberhaupt in config vorhanden!!!
$config{parameter}{signature_timestamp} = strftime "%Y-%m-%d %H-%M-%S", localtime;
$config{parameter}{signature_convmachine} = `hostname`;
$config{parameter}{signature_convmachine} =~ s/\n//sg ;
$config{parameter}{signature_convuser} = (getpwuid($<))[0];

# Generiere Course-ID, diese sollte pro Kurs und Version eindeutig sein
$config{parameter}{signature_CID} = "(" . $config{parameter}{signature_main} . ";;" . $config{parameter}{signature_version} . ";;" . $config{parameter}{signature_localization} . ")";

logMessage($CLIENTINFO, "     main: " . $config{parameter}{signature_main});
logMessage($CLIENTINFO, "  version: " . $config{parameter}{signature_version});
logMessage($CLIENTINFO, "   locale: " . $config{parameter}{signature_localization});
logMessage($CLIENTINFO, "timestamp: " . $config{parameter}{signature_timestamp});
logMessage($CLIENTINFO, "conv-user: " . $config{parameter}{signature_convuser});
logMessage($CLIENTINFO, "c-machine: " . $config{parameter}{signature_convmachine});
logMessage($CLIENTINFO, "      CID: " . $config{parameter}{signature_CID});
logMessage($CLIENTINFO, "Diese Informationen werden im HTML-Baum hinterlegt");

# Wir befinden uns gerade im zu erzeugenden Baum, in dem perl ein Unverzeichnis ist, das Kopieren der Dateien von perl/files nach .. wurde schon durchgefuehrt
my $mints_open = open(MINTS, "> " . $config{outtmp} . "/convinfo.js") or die "FATAL: Could not create convinfo.js.\n";
print MINTS "// Automatically generated by mconvert.pl, will be included by the standard template\n";
print MINTS "var scormLogin = " . $config{scormlogin} . ";\n";
print MINTS "var isRelease = " . $config{dorelease} . ";\n";
print MINTS "var doCollections = " . $config{docollections} . ";\n";

if ($config{testonly} eq 1) {
  print MINTS "var testOnly = 1;\n";
  print "TESTONLY aktiviert!\n";
  # Deaktiviert Buttons
  $confsite = "";
  $datasite = "";
  $searchsite = "";
} else {
  print MINTS "var testOnly = 0;\n";
}

if ($config{dorelease} ne 1) {
  print MINTS "console.log(\"KEINE RELEASE-VERSION\");\n";
}
print MINTS "var isVerbose = " . $config{doverbose} . ";\n";
if ($config{doverbose} eq 1) {
  print MINTS "console.log(\"VERBOSE-VERSION\");\n";
}

# Freie Parameter aus config eintragen
my $ckey;
my $cval;
while (($ckey, $cval) = each(%{$config{'parameter'}})) {
  print MINTS "var $ckey = \"$cval\";\n";
}

print MINTS "var globalsitepoints = [];\n";
print MINTS "var globalexpoints = [];\n";
print MINTS "var globaltestpoints = [];\n";
print MINTS "var globalsections = [];\n";
for ($i=0; $i<=$#expoints; $i++) {
  print MINTS "globalsitepoints[$i] = " . $sitepoints[$i] . ";\n";
  print MINTS "globalexpoints[$i] = " . $expoints[$i] . ";\n";
  print MINTS "globaltestpoints[$i] = " . $testpoints[$i] . ";\n";
  print MINTS "globalsections[$i] = \"" . $sections[$i] . "\";\n";
}
close(MINTS);


if ($config{parameter}{do_export} eq "1") { logMessage($CLIENTINFO,  "EXPORTVERSION WILL BE GENERATED");  }
if ($config{parameter}{do_feedback} eq "1") { logMessage($CLIENTINFO, "FEEDBACKVERSION WILL BE GENERATED");  }

my @umwordindexlist = ();
my @wordindexlist = ();
my @wordindexlinklist = ();
$i = 0;
my $li = "ELI_SW";
while ($text =~ s/<!-- mpreindexentry;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?); \/\/-->/<!-- mindexentry;;$1; \/\/--><a class=\"label\" name=\"$li$i\"><\/a><!-- mmlabel;;$li$i;;$2;;$3;;$4;;$5;;13; \/\/-->/s ) {
  my $umstr = $1;
  push @wordindexlist, $1;
  push @wordindexlinklist, "$li$i";
  $umstr =~ s/ä/ae/g ;
  $umstr =~ s/ö/oe/g ;
  $umstr =~ s/ü/ue/g ;
  $umstr =~ s/Ä/Ae/g ;
  $umstr =~ s/Ö/Oe/g ;
  $umstr =~ s/Ü/Ue/g ;
  $umstr =~ s/ß/ss/g ;
  push @umwordindexlist, $umstr;
  $i++;
}

# Sortieren mit IdiotSort FUNKTIONIERT NICHT MIT UMLAUTEN
my $swap = 1;
logMessage($VERBOSEINFO, "Sortiere " . ($#wordindexlist-1) . " Stichwoerter"); 
while ($swap==1) {
  $swap = 0;
  for (my $i=0; $i <= $#wordindexlist; $i++ ) {
    for (my $j=$i+1; $j <= $#wordindexlist; $j++ ) {
      if (lc($umwordindexlist[$i]) gt lc($umwordindexlist[$j])) {
        my $s = $umwordindexlist[$i];
        $umwordindexlist[$i] = $umwordindexlist[$j];
        $umwordindexlist[$j] = $s;
        $s = $wordindexlist[$i];
        $wordindexlist[$i] = $wordindexlist[$j];
        $wordindexlist[$j] = $s;
        $s = $wordindexlinklist[$i];
        $wordindexlinklist[$i] = $wordindexlinklist[$j];
        $wordindexlinklist[$j] = $s;
        $swap = 1;
      }
    }
  }
}

# Suchtabelle erstellen  
my $st = "<div class='searchtable'>\n";
my $ki = 0;
for ($ki = 0; $ki <= $#wordindexlist; $ki++) {
  # $st .= "<!-- mmref;;" . $wordindexlinklist[$j] . ";;0; \/\/--><br >";
  
 
  my $pr = 0;
  if ($ki eq 0) {
    $pr = 1;
  } else {
    if ($wordindexlist[$ki] eq $wordindexlist[$ki-1]) { $pr = 0; } else { $pr = 1; }
  }
 
  if ($pr eq 1) { $st .= "<br />" . $wordindexlist[$ki] . ": "; } else { $st .= " , "; }
  $st .=  "<!-- mmref;;" .  $wordindexlinklist[$ki] . ";;1; \/\/-->";
}
$st .= "</div>\n";
$text =~ s/<!-- msearchtable \/\/-->/$st/s ;



loadtemplates();


logMessage($VERBOSEINFO, "Ermittele Kapitelstruktur");

my $root = ModulPage->new();
$root->{TITLE} = "ROOT";

logMessage($VERBOSEINFO, "ROOT-Objekt erzeugt mit folgenden Einträgen:");
while ($ckey = each(%{$root})) {
  if ($root->{$ckey}) {
    logMessage($VERBOSEINFO, "  $ckey => " . $root->{$ckey});
  } else {
    logMessage($VERBOSEINFO, "  $ckey-Wert nicht initialisiert!");
  }
}



logTimestamp("Starting decomposition");
$root->split($text, $paramsplitlevel, 0); # = Startlevel fuer root-Objekt
$root->{DISPLAY} = 0;

   
logTimestamp("Starte Display-Check");
hidepageswotext($root);

logTimestamp("Starte MathML Optimierungen");
mathmloptimize($root);

logTimestamp("Starte Link-Updates");
linkupdate($root, "../");


# Die folgenden Manipulationen muessen nach linkupdate
# passieren, da dort Links auf Seiten innerhalb der
# Seitenstruktur erstellt werden

        
logTimestamp("Starte TOC-Erzeugung");
createtocs($root);

logTimestamp("Starte Link-Ersetzung");
createlinks($root);

logTimestamp("Relocate Helpsection");
relocatehelpsection($root,0);

@LabelStorage = ();

my $outfinal = "";
storelabels($root);
$outfinal = $config{outtmp};
logMessage($CLIENTINFO, "Writing output to $outfinal");
printpages($root, $outfinal);

# print "Vorhandene Labels im HTML-Baum:\n";
# 
# my $l;
# for ( $l=0; $l <= $#LabelStorage; $l++ ) {
#   # [ $lab, $sub, $sec, $ssec, $sssec, $anchor, $pl]
#   print " lab=$LabelStorage[$l][0], subject=$LabelStorage[$l][1], nr=$LabelStorage[$l][2].$LabelStorage[$l][3].$LabelStorage[$l][4], anchor=$LabelStorage[$l][5], pl=$LabelStorage[$l][6]\n";
# }

# collection-Exportdatei schreiben
if ($config{docollections} eq 1) {
  logMessage($VERBOSEINFO, "Exportfile for contained collections is generated:");
  my $nco = $#colexports + 1;
  if ($nco le 0) {
    logMessage($VERBOSEINFO, "  No exports found!");
  } else {
    logMessage($VERBOSEINFO, "Exporting $nco collections");
    my $colexportfile = open(MINTS, "> collectionexport.json") or die "FATAL: Cannot write collectionexport.json";
    print MINTS "{ \"comment\": \"Automatisch generierte JSON-Datei basierend auf Kurs-ID " . $config{parameter}{signature_CID} . "\",\n \"collections\": [";
    for (my $k = 0; $k <= $#colexports; $k++) {
    print MINTS "  ";
      if ($k ge 1) { print MINTS ","; }
      print MINTS "{ \"id\": \"" . $colexports[$k][0] . "\", \"exercises\": " . $colexports[$k][2] . "}";
    }
    
    
    print MINTS "]}\n";
    close(MINTS);
  }
}

if ($config{doverbose} == "1") {
  my $graph = GraphViz->new();
  my @list = ();
  push @list, $root;
  while ($#list != -1) {
    my $page = $list[0];
    splice(@list, 0, 1);
    my $title = $page->{UXID};
    if ($title eq $UNKNOWN_UXID) {
      $title = $page->{TITLE} . " " . $page->{ID};
    }
    logMessage($VERBOSEINFO, "graph item uxid = $title");
    $title = decode("latin1", $title);
    $title = encode("utf-8", $title);
    $graph->add_node($title);
    if ($page->{LEVEL} >= 1) {
      my $pretitle = $page->{PARENT}->{UXID};
      if ($pretitle eq $UNKNOWN_UXID) {
        $pretitle = $page->{PARENT}->{TITLE} . " " . $page->{PARENT}->{ID};
      }
      $pretitle = decode("latin1", $pretitle);
      $pretitle = encode("utf-8", $pretitle);
      $graph->add_edge($title, $pretitle);
    }
    my @subpages = @{$page->{SUBPAGES}};
    my $i;
    for ($i = 0; $i <= $#subpages; $i++) {
      push @list, $subpages[$i];
    }
  }
  
  
  my $graph_png = open(MINTS, ">graph.png") or die("FATAL: Cannot write graph png");
  print MINTS $graph->as_png();
  close(MINTS);
}

#Rechte setzen
system "chmod -R 777 " . $config{outtmp};


if ($#converrors ge 0) {
  logMessage($CLIENTINFO, "----------------------- COMPILATION MESSAGES ---------------------------------");
  my $yi = 0;
  for ($yi = 0; $yi <= $#converrors; $yi++) {
    logMessage($CLIENTINFO, "  $converrors[$yi]");
  }
} else {
  logMessage($VERBOSEINFO, "  No compilation messages occurred");
}

logTimestamp("Finished computation");

}

# Parameter: Name der Konfigurationsdatei relativ zum Aufrufer
sub setup_options {
  $mconfigfile = $_[0];
  if ($mconfigfile =~ m/(.+).pl/ ) {
    if ($mconfigfile =~ m/\// ) { die("FATAL: Configuration file must be in calling directory"); }
    logMessage($CLIENTINFO, "Configuration file: " . $mconfigfile);
    unless (%config = do $mconfigfile) {
      warn "Couldn't parse $mconfigfile: $@" if $@;
      warn "Couldn't run $mconfigfile" unless %config;
    }
  } else {
    die("FATAL: Configuration file $mconfigfile must be of type name.pl");
  }
    
  logMessage($CLIENTINFO, "Configuration description: " . $config{description});
}


# Parameter: string, content of a tex file
# returns 1 if tex file is valid for a release
sub checkRelease {
  my $tex = $_[0];
  my $reply = 1;
  # no experimental environments
  if ($tex =~ m/\\begin{MExperimental}/s ) {
    logMessage($VERBOSEINFO, "MExperimental found in tex file");
    $reply = 0;
  }
  if ($tex =~ m/\% TODO/s ) {
    logMessage($VERBOSEINFO, "TODO comment found in tex file");
    $reply = 0;
  }
  return $reply;
}


# ----------------------------- Start Hauptprogramm --------------------------------------------------------------

# my $IncludeTags = ""; # Sammelt die Makros fuer predefinierte Tagmakros, diese werden an mintmod.tex angehaengt

# Logfile als erstes einrichten, auf der Ebene des Aufrufs
open(LOGFILE, "> $mainlogfile") or die("ERROR: Cannot open log file, aborting!");


#Zeit speichern und Startzeit anzeigen
$starttime = time;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
logMessage($CLIENTINFO, "Starting conversion: " . ($year+1900 ) . "-" . ($mon+1) . "-$mday at $hour:$min:$sec");

if ($#ARGV eq 0) {
  # Nur ein Parameter: Gibt Konfigurationsdatei relativ zum Aufruf an
  setup_options($ARGV[0]);
} else {
  if ($#ARGV ge 1) {
    # Ein oder mehr Parameter: Konfiguationsdatei plus Kommandos der Form option=wert
    setup_options($ARGV[0]);
    my $i;
    for ($i = 1; $i <= $#ARGV; $i++) {
    
      if ($ARGV[$i] =~ m/(.+)=(.*)/ ) {
        my $obj = $1;
        my $val = $2;
        # check if modified parameter exists
        if (exists $config{$obj}) {
          logMessage($CLIENTINFO, "Parameter modification: \"$obj\" changed from \"" . $config{$obj} . "\" to \"$val\"");
          $config{$obj} = $val;
        } else {
          logMessage($CLIENTINFO, "New parameter added: \"$obj\" set to \"$val\"");
          $config{$obj} = $val;
        }
      } else {
        logMessage($FATALERROR, "Command line argument " . $ARGV[$i] . " not of type <parameter>=<value>");
      }
    }
  } else {
    die($helptext);
  }
}

checkSystem();

my $absexedir = Cwd::cwd(); 
$basis = $absexedir;

checkOptions();

$rfilename = $config{source} . "/" . $config{module}; # sollte durch PERL-Join ersetzt werden

logMessage($VERBOSEINFO, " Absolute directory: " . $absexedir);
logMessage($VERBOSEINFO, "Converter directory: " . $basis);
logMessage($VERBOSEINFO, "   Source directory: " . $config{source});
logMessage($VERBOSEINFO, "   Output directory: " . $config{output});
logMessage($VERBOSEINFO, "   Main module file: " . $rfilename);
logMessage($VERBOSEINFO, "Generating HTML tree as described in " . $rfilename);

if ($config{doscorm} eq 1) {
  logMessage($CLIENTINFO, "Tree will be SCORM-compatible (version 2004v4)");
} else {
  logMessage($VERBOSEINFO, "No SCORM support");
}

if ($config{dopdf} eq 1) {
  logMessage($CLIENTINFO, "Generating PDF files");
} else {
  logMessage($CLIENTINFO, "PDF files not requested");
}

if ($config{qautoexport} eq 1) {
  logMessage($CLIENTINFO, "Exercise autoexport activated");
}

if ($config{dotikz} eq 1) {
  logMessage($CLIENTINFO, "...TikZ externalization activated");
}

open(F,$rfilename) or die("FATAL: Cannot open main tex file $rfilename");
close(F);


logTimestamp("Finished initializiation");

# Preprocessing of main file
my $roottex = "";
my $tex_open = open(MINTS, "< $rfilename") or die("FATAL: Cannot read main tex file $rfilename");
my $texzeile = "";
while(defined($texzeile = <MINTS>)) {
  # Wegen direkter HTML-Zeilen darf man %-Kommentare nicht streichen
  $roottex .= $texzeile;
}
close(MINTS);

logMessage($CLIENTINFO, "Setting up output directory " . $config{output});
system("rm -fr " . $config{output});
system("mkdir " . $config{output});
system("cp -R $basis/converter " . $config{output} . "/.");
system("cp -R " . $config{source} . "/* " . $config{output} . "/converter/tex/.");

# Preprocessing aller tex-Files
my $filecount = 0;
my $globalposdirecthtml = 0; # Fuer DirectHTML-Array, ist unique fuer alle Teildateien
my $call = "find -P " . $config{output} . "/converter/tex/. -name \\*.tex";
logMessage($VERBOSEINFO, "Executing: $call");
my $texlist = `$call`; # Finde alle tex-Files, auch in den Unterverzeichnissen
my @texs = split("\n",$texlist);
my $nt = $#texs + 1;
logMessage($VERBOSEINFO, "$nt texfiles found, processing...");
my $ka;
my $pcompletename = "";
my $dotikzfile = 0;
for ($ka = 0; $ka < $nt; $ka++) {

  if (($texs[$ka] =~ /$macrofile/ ) or ($texs[$ka] =~ /tree(.)\.tex/ ) or ($texs[$ka] =~ /tree\.tex/ )) {
    logMessage($VERBOSEINFO, "Preprocessing ignores $texs[$ka]");
  } else {
    # -------------------------------- Start Preprocessing per texfile -------------------------------------------------------
    my $textex = "";
    $texzeile = "";
    $pcompletename = $texs[$ka];
    $pcompletename =~ m/(.+)\/(.+?).tex/i;
    my $pdirname = $1;
    my $pfilename = $2 . ".tex";
    
    my $tex_info = `file -i $pcompletename`;
    my $charset_ok = 0;
    if ($tex_info =~ m/charset=iso-8859-1/s ) {
      logMessage($VERBOSEINFO, "  charset = iso-8859-1 (latin1)");
      $charset_ok = 1;
    }
    
    if ($tex_info =~ m/charset=us-ascii/s ) {
      logMessage($VERBOSEINFO, "  charset = us-ascii found (nice but latin1 is ok)");
      $charset_ok = 1;
    }
    
    if ($charset_ok ne 1) {
      $tex_info =~ m/charset=(.+)/i ;
      logMessage($CLIENTWARN, "  bad charset " . $1 . " in file " . $texs[$ka] . ", must be latin1");
    }
    
    
    $tex_open = open(MINTS, "< $pcompletename") or die "FATAL: Could not open $texs[$ka]\n";
    while(defined($texzeile = <MINTS>)) {
      # Wegen direkter HTML-Zeilen darf man %-Kommentare nicht streichen
      # $texzeile =~ s/\%(.*)//g ;
      $textex .= $texzeile;
    }
    close(MINTS);
    
    
    my $modulname = "";
    if ($textex =~ /\\MSection\{(.+?)\}/ ) {
      $modulname = $1;
    }
    my $prx = "";
    my $pfname = "";
    if ($texs[$ka] =~ /(.*)\/tex\/(.+)\/(.+?)\.tex/ ) {
      $prx = $2;
      $pfname = $3;
    } else {
      die("FATAL: Could not decode $texs[$ka]");
    }
    $prx =~ s/.\///g;
    if ($modulname ne "") {
      logMessage($VERBOSEINFO, "Tree-preprocess on module $modulname in directory $prx");
    } else {
      logMessage($VERBOSEINFO, "Tree-preprocess on bare file $pfname in directory $prx");
    }
 
    if ($config{dorelease} eq 1) {
      if (checkRelease($textex) eq 0) {
        logMessage($CLIENTERROR, "tex-file " . $texs[$ka] . " did not pass release check");
      }
    }

 
    $filecount++;
    
    # Kommentarzeilen radikal entfernen (außer wenn \% statt % im LaTeX-Code steht oder wenn in verb-line)
    my $coms = 0;
    
    # Suchen welche Sonderzeichen fuer verb-Kommandos eingesetzt werden
    
    my $vi = 0;
    my @verbac = ($textex =~ m/\\verb(.)/g );
    my @verbc = ();
    for ($vi = 0; $vi <= $#verbac; $vi++) {
      my $found = 0;
      my $vb;
      for ($vb = 0; (($vb <= $#verbc) and ($found == 0)); $vb++ ) {
        if ($verbc[$vb] eq $verbac[$vi]) { $found = 1; }
      }
      if ($found == 0) {
        my $c = $verbac[$vi];
        push @verbc, $c;
      }
    }
    
    
    my $vc = $#verbc + 1;
    if ($vc > 0) { logMessage($VERBOSEINFO, " $vc different verb-escape chars found in tex-file"); }
      
    for ($vi = 0; $vi < $vc; $vi++ ) {
      my $c = $verbc[$vi];
      logMessage($VERBOSEINFO, " verb-char $c");
      if ($c eq "\%") {
        # Es gibt wirklich Autoren die in einem LaTeX-Dokument das % als Begrenzer fuer \verb einsetzen, das macht es tricky
	while ($textex =~ s/\\verb$c([^$c]*?)$c/\\verb\\PERCTAG$1\\PERCTAG/ ) { logMessage($VERBOSEINFO, "  Delimiter in \%-verb-line escaped"); }
      } else {
	while ($textex =~ s/\\verb$c([^$c]*?)\%([^$c]*?)$c/\\verb$c$1\\PERCTAG$2$c/ ) { logMessage($VERBOSEINFO, "  \% in verb-line escaped (special char $c)"); }
      }
    }
    
    while ($textex =~ s/(?<!\\)\%([^\n]+?)\n/\%\n/s ) { $coms++; }
    if ($coms != 0) { logMessage($VERBOSEINFO, "  $coms LaTeX-commentlines removed from file"); }

    while ($textex =~ s/\\PERCTAG/\%/ ) { logMessage($VERBOSEINFO, "  \% in verb-line reinstated"); }

    
    $dotikzfile = 0;
    if ($textex =~ s/\\Mtikzexternalize//gs ) {
      logMessage($CLIENTINFO, "  tikzexternalize activated");
      if ($config{dotikz} eq 1) { $dotikzfile = 1; }
    }

    
    # Frageumgebungen ggf. fuer Export vorbereiten
    if ($config{qautoexport} eq 1) {
      $textex =~ s/\\begin{MExercise}(.+?)\\end{MExercise}/\\begin{MExportExercise}$1\\end{MExportExercise}/sg ;
    }
     
    if ($textex =~m/\\MSection{(.+?)}/s ) {
      $globalexstring .= "\\MSubsubsectionx{" . $1 . "}\n";
    }
     
    # Exportmarkierte Frageumgebungen in DirectHTML umsetzen, das muss vor jeglichem Preprocessing stattfinden
    my $qex = 0;
    while ($textex =~ s/\\begin{MExportExercise}(.+?)\\end{MExportExercise}/\\begin{MExercise}$1\\end{MExercise}\n\\begin{MDirectHTML}\n<!-- qexportstart;$qex; \/\/-->$1<!-- qexportend;$qex; \/\/-->\n\\end{MDirectHTML}/s ) { 
      $qex++;
      $globalexstring .= "\\ \\\\\n\\begin{MExercise}\n" . $1 . "\n\\end{MExercise}\n";
    }
       
       
    # MDirectMath umsetzen (als DirectHTML)
    while($textex =~ s/\\begin{MDirectMath}(.+?)\\end{MDirectMath}/\\ifttm\\special{html:<!-- directhtml;;$globalposdirecthtml; \/\/-->}\\fi/s ) {
      push @DirectHTML , "\\[" . $1 . "\\]";
      $globalposdirecthtml++;
    }

    # MDirectHTML umsetzen
    while($textex =~ s/\\begin{MDirectHTML}(.+?)\\end{MDirectHTML}/\\ifttm\\special{html:<!-- directhtml;;$globalposdirecthtml; \/\/-->}\\fi/s ) {
      push @DirectHTML , $1;
      $globalposdirecthtml++;
    }

    
     # Copyright-notices umsetzen, wichtig ist hier dass die DirectHTML-Eintraege und die Aufgabenexporte schon gemacht sind
    while($textex =~ s/\\MCopyrightNotice{(.+?)}{(.+?)}{(.+?)}{(.+?)}{(.+?)}/\\MCopyrightNoticePOST{$1}{$2}{$3}{$4}{$5}/s ) {
      my $authortext = "";
      if ($3 eq "MINT") {
        $authortext = "\\MExtLink{http://www.mint-kolleg.de}{MINT-Kolleg Baden-Württemberg}";
      } else {
        if ($3 eq "VEMINT") {
          $authortext = "\\MExtLink{http://www.vemint.de}{VEMINT-Konsortium}";
        } else {
          if ($3 eq "NONE") {
            $authortext = "Unbekannter Autor";
            } else {
            $authortext = "\\MExtLink{$3}{Autor}";
          }
        }
      }
      
      if ($2 eq "NONE") {
	$copyrightcollection .= "\\MCRef{$5} & $1 & $authortext & Ersterstellung & $4 \\\\ \\ \\\\\n";
      } else {
        if ($2 eq "TIKZ") {
          $copyrightcollection .= "\\MCRef{$5} & $1 & $authortext & Grafikdatei erzeugt aus tikz-Code & $4 \\\\ \\ \\\\\n";
        } else {
            if ($2 eq "FSZ") {
                $copyrightcollection .= "\\MCRef{$5} & $1 & $authortext & Aufgenommen im \\MExtLink{http://www.fsz.kit.edu}{Fernstudienzentrum} des \\MExtLink{http://www.kit.edu}{KIT} & $4 \\\\ \\ \\\\\n";
            } else {
                $copyrightcollection .= "\\MCRef{$5} & $1 & $authortext & \\MExtLink{$2}{Originaldatei} & $4 \\\\ \\ \\\\\n";
            }
         }
      }
    }

    if ($textex =~ s/\\tikzexternalize//gs ) {
      logMessage($CLIENTINFO, "  found BARE tikzexternalize and removed it (please use macro from $macrofile instead)");
    }

    
    #  ------------------------ Pragmas einlesen und verarbeiten ----------------------------------

    if ($textex =~ m/\\MPragma{SolutionSelect}/ ) {
      if ($config{nosols} eq 0) {
        logMessage($CLIENTINFO, "  Pragma SolutionSelect: Ignored due to nosols==0");
      } else {
        logMessage($CLIENTINFO, "  Pragma SolutionSelect: MSolution-environments will be removed");
	while ($textex =~ s/\\begin{MSolution}(.+?)\\end{MSolution}/\\relax/s ) { ; }
    logMessage($CLIENTINFO,  "MHint{Lösung}-environments will be removed");
	while ($textex =~ s/\\begin{MHint}{Lösung}(.+?)\\end{MHint}/\\relax/s ) { ; }
	while ($textex =~ s/\\begin{MHint}{L"osung}(.+?)\\end{MHint}/\\relax/s ) { ; }
	while ($textex =~ s/\\begin{MHint}{L\\"osung}(.+?)\\end{MHint}/\\relax/s ) { ; }
      }
    }

    if ($textex =~ m/\\MPragma{MathSkip}/ ) {
      logMessage($CLIENTINFO, "  Pragma MathSkip: Skips starting math-environments inserted");
      $textex =~ s/(?<!\\)\\\[/\\MSkip\\\[/g;
      $textex =~ s/(?<!\\)\$\$/\\MSkip\$\$/g;
      $textex =~ s/(?<!\\)\\begin{eqnarray/\\MSkip\\begin{eqnarray/g;
      $textex =~ s/(?<!\\)\\begin{equation/\\MSkip\\begin{equation/g;
      $textex =~ s/(?<!\\)\\begin{align/\\MSkip\\begin{align/g;
    }

    while ($textex =~ s/\\MPragma{Substitution;(.+?);(.+?)}/\\MPragma{Nothing}/ ) {
      logMessage($CLIENTINFO, "  Pragma Substitution: $1 --> $2");
      my $s1 = $1;
      my $s2 = $2;
      $textex =~ s/$s1/$s2/g ;
    }

    my $incfound;
    while ($textex =~ s/\\MPreambleInclude{(.*)}/\\MPragma{Nothing}/ ) {
      my $prename = $1;
      logMessage($CLIENTINFO, "  Local preamble included: $prename");
      # Nicht doppelt einbinden, Liste geht ueber ALLE tex-files!
      $incfound = 0;
      for ( $i=0; $i <= $#IncludeStorage; $i++ ) {
        if ($IncludeStorage[$i][1] eq $prename) {
          logMessage($CLIENTINFO, "    Preamble found again: " . $prename . " (will be ignored, preamble from file " . $IncludeStorage[$i][0] . " is in use)");
          $incfound = 1;
        }
      }
      if ($incfound eq 0) {
        my $inccontent = "";
        my $tex_inc_open = open(MINTI, "< $pdirname\/".$prename) or die "FATAL: Could not read preamble $pdirname\/$prename";
        while(defined($texzeile = <MINTI>)) {
          $inccontent .= $texzeile;
        }
        close(MINTI);
        push @IncludeStorage, [ $pcompletename, $prename, $inccontent ];
      }

    }

      
    
    if ($modulname ne "") {
      # Dokumentstruktur an tree anpassen, includes und preamble werden schon vorgegeben
      $textex =~ s/\\begin{document}//g ;
      $textex =~ s/\\input{$macrofile}//g ;
      $textex =~ s/\\input{$macrofilename}//g ;
      $textex =~ s/\\end{document}//g ;
      $textex =~ s/\\input{(.+?)}/\\input{$prx\/$1}/g; # !!!!!!!!!!!!!!!
      # input-Anweisungen der Modulebene anpassen: jedes Modul liegt einem eigenen Verzeichnis
      # Alle printindex-Kommandos entfernen
      $textex =~ s/\\printindex//g;
      $textex =~ s/\\MPrintIndex//g;
    }

    # Mit MDia eingebundene dia-Files verarbeiten (eps->png aus dia lokal produzieren, png's fuer das PDF erhalten hoeheres dpi)

    my $suffixpdf = "mintpdf";
    my $suffixhtml = "minthtml";
    while ($textex =~ m/\\MDia\{(.+?)\}/g ) {
      my $dprx = $config{output} . "/converter/tex/$prx/$1";
      if ($config{diaok} == "0") {
        logMessage($CLIENTWARN, "dia/conv-chain disabled, NOT processing dia diagramm $dprx");
      } else {
        logMessage($VERBOSEINFO, "Processing dia diagramm $dprx");
        system "dia --export $dprx.png --filter=cairo-alpha-png $dprx.dia";
      
        my $rt = 0;
      
        $rt = system("dia --export $dprx.eps $dprx.dia");
        if ($rt == 0) {
          system "convert -density 180 $dprx.eps -resample 180 $dprx$suffixpdf.png"; 
          $rt = system("convert -density 53 $dprx.eps -resample 53 $dprx$suffixhtml.png");
        }
      
        if ($rt != 0) {
          $config{diaok} = 0;
          logMessage($CLIENTERROR, "dia/conv-chain failed with return value $rt");
        }
      }
    } 

    # Eindimensionale pmatrix-Umgebungen als eindimensionale Arrays umsetzen
    if ($textex =~ s/\\begin{pmatrix}([^&]*?)\\end{pmatrix}/\\ifttm\\left({\\begin{array}{c}$1\\end{array}}\\right)\\else\\begin{pmatrix}$1\\end{pmatrix}\\fi/sg ) {
      logMessage($VERBOSEINFO, "  pmatrix-environment of dimension 1 substituted");
    }
    
    # flushleft-Umgebungen im html ignorieren
    if ($textex =~ s/\\begin{flushleft}(.*?)\\end{flushleft}/\\ifttm{$1}\\else\\begin{flushleft}$1\\end{flushleft}\\fi/sg ) {
      logMessage($VERBOSEINFO, "  flushleft-environment removed (no counterpart in html available right now)");
    }

    # vdots und hdots ersetzen
    $textex =~ s/\\hdots/\\MHDots/g ;
    $textex =~ s/\\vdots/\\MVDots/g ;
    
    
    if ($textex =~ m/\\begin{pmatrix}/s ) { logMessage($VERBOSEINFO, "  Multidimensional pmatrix-environments found, cannot be processed"); }
    
    # \relax auf \MRelax umbiegen, da \relax nicht von ttm unterstuetzt
    if ($textex =~ s/\\relax/\\MRelax/g ) { logMessage($VERBOSEINFO, "  Command \\relax replaced"); }
    
    # newpage und co aus html-Konversion ausschliessen
    $textex =~ s/\\newpage/\\ifttm\\else\\newpage\\fi/g ;
    $textex =~ s/\\pagebreak/\\ifttm\\else\\pagebreak\\fi/g ;
    $textex =~ s/\\clearpage/\\ifttm\\else\\clearpage\\fi/g ;
    $textex =~ s/\\allowbreak/\\ifttm\\else\\allowbreak\\fi/g ;

    # Ligaturbefehl aus html-Konversion ausschliessen
    $textex =~ s/\\\//\\ifttm\\else\\\/\\fi\%\n/g ;

    # Umlaute in Knopftitel fuer MHint ersetzen (wird von ttm ignoriert weil als Teil des TeX-Kommandos interpretiert)
    $textex =~ s/\\begin\{MHint\}\{([^\{\}]*?)ö([^\{\}]*?)\}/\\begin\{MHint\}\{$1\"o$2\}/sg ;
    $textex =~ s/\\begin\{MHint\}\{([^\{\}]*?)ä([^\{\}]*?)\}/\\begin\{MHint\}\{$1\"a$2\}/sg ;
    $textex =~ s/\\begin\{MHint\}\{([^\{\}]*?)ü([^\{\}]*?)\}/\\begin\{MHint\}\{$1\"u$2\}/sg ;
    $textex =~ s/\\begin\{MHint\}\{([^\{\}]*?)Ö([^\{\}]*?)\}/\\begin\{MHint\}\{$1\"O$2\}/sg ;
    $textex =~ s/\\begin\{MHint\}\{([^\{\}]*?)Ä([^\{\}]*?)\}/\\begin\{MHint\}\{$1\"A$2\}/sg ;
    $textex =~ s/\\begin\{MHint\}\{([^\{\}]*?)Ü([^\{\}]*?)\}/\\begin\{MHint\}\{$1\"U$2\}/sg ;
    $textex =~ s/\\begin\{MHint\}\{([^\{\}]*?)ß([^\{\}]*?)\}/\\begin\{MHint\}\{$1\"s$2\}/sg ;

    
    my $rpr = "CRLF";
    while ($textex =~ /$rpr/i ) { $rpr = $rpr . "x" };


    # Nach equation- und eqnarray-starts den Labeltyp anpassen
    my $eqprefix = "\\setcounter{MLastType}{10}\\addtocounter{MLastTypeEq}{1}\\addtocounter{MEquationCounter}{1}\\setcounter{MLastIndex}{\\value{MEquationCounter}}\n";
    my $eqpostfix = "\\addtocounter{MLastTypeEq}{-1}\n";
    $textex =~ s/\\begin{eqnarray}/$eqprefix\\begin{eqnarray}/g ;
    $textex =~ s/\\begin{equation}/$eqprefix\\begin{equation}/g ;
    $textex =~ s/\\end{eqnarray}/\\end{eqnarray}\n$eqpostfix/g ;
    $textex =~ s/\\end{equation}/\\end{equation}\n$eqpostfix/g ;

    # Nach table-starts den Labeltyp anpassen
    my $tableprefix = "\\setcounter{MLastType}{9}\\addtocounter{MLastTypeEq}{2}\\addtocounter{MTableCounter}{1}\\setcounter{MLastIndex}{\\value{MTableCounter}}\n";
    my $tablepostfix = "\\addtocounter{MLastTypeEq}{-2}\n";
    $textex =~ s/\\begin{table}/$tableprefix\\begin{table}/g ;
    $textex =~ s/\\end{table}/\\end{table}\n$tablepostfix/g ;

    # MLabels in equation/eqnarray umsetzen, so dass sie vor dem Environment (in dem alles als Mathe geparset wird) stehen
#     while ($textex =~ s/\\begin{equation}(.*?)([\n ]*)\\MLabel{(.+?)}([\n ]*)(.*?)\\end{equation}/\\MLabel{$3}\n\\begin{equation}$1 $5\\end{equation}/s ) {;} 
#     while ($textex =~ s/\\begin{eqnarray}(.*?)([\n ]*)\\MLabel{(.+?)}([\n ]*)(.*?)\\end{eqnarray}/\\MLabel{$3}\n\\begin{eqnarray}$1 $5\\end{eqnarray}/s ) {;} 

    # align* umsetzen in erweitertes eqnarray*
    # Dabei wird "&{SYMBOL}" ersetzt durch "& {SYMBOL} &", "& " ersetzt durch "& &"
    # App-Variante: && wird als & & interpretiert 
    # Momentan nicht aktiv: alles nach "&&" wird in die letzte abgetrennte Spalte gesetzt


    # \text-Kommandos so umbauen, dass umrandende Leerzeichen richtig gesetzt werden

    # \text-Kommandos mit korrekter Klammerzaehlung parsen
    my $tcl = "$rpr XKL";
    my $tcr = "$rpr XKR";
    while ($textex =~ /\\text{/ ) {
      my $a = index($textex,"\\text{") + 5;
      my $b = $a;
      my $cc = 1;
      while ($cc > 0) {
        $b++;
        if (substr($textex,$b,1) eq "}") { $cc--; }
        if (substr($textex,$b,1) eq "{") { $cc++; }
      }
      substr($textex,$b,1) = $tcr;
      substr($textex,$a,1) = $tcl;
    }

    # Erst "\ "-Leerzeichen rausnehmen
    while ($textex =~ s/\\text$tcl\\\s(.*?)$tcr/\\;\\text$tcl$1$tcr/s ) { ; }
    while ($textex =~ s/\\text$tcl(.*?)\\\s$tcr/\\text$tcl$1$tcr\\;/s ) { ; }
    while ($textex =~ s/\\text$tcl\s(.*?)$tcr/\\;\\text$tcl$1$tcr/s ) { ; }
    while ($textex =~ s/\\text$tcl(.*?)\s$tcr/\\text$tcl$1$tcr\\;/s ) { ; }

    # Restliche Klammerreplika ersetzen
    $textex =~ s/\\text$tcl(.*?)$tcr/\\text{$1}/gs;


    # print "Using CRLF-Prefix: $rpr\n";
    $textex =~ s/\n/ $rpr A /g;
    $textex =~ s/\r/ $rpr B /g;

    # Proof-Umgebungen anpassen: unter ttm braucht das mintmod-Environment einen Parameter und er muss in {...} stehen
    $textex =~ s/\\begin{proof}(?!\[)/\\begin{proof}\[Beweis\]/g ;
    $textex =~ s/\\begin{proof}\[(.+?)\]/\\begin{MProof}{$1}/g ;
    $textex =~ s/\\end{proof}/\\end{MProof}/g ;

    # CopyrightHTML anpassen
    
    # MEvalMathDisplay-Umgebungen abfangen und durch generische divs zur mathjax-Darstellung ersetzen, Inhalt geht an eine knockout-Observable und wird von deren Events geparset
    my $emc = 5;
    while ($textex =~ s/\\begin{MEvalMathDisplay}(.*?)\\end{MEvalMathDisplay}/\\begin{MEvalMathDisplay}<--EVMTAG-->\\end{MEvalMathDisplay}/s ) {
      my $orgmath = $1;
      my $texmath = $orgmath;
      
      # Umgebung bei verwendeten Variablen registrieren
      # while ($texmath =~ s/\\MVar{(.+?)}/\\\\/s ) { }
      
      $texmath =~ s/\\MVar\{(.+?)\}/\[var\_$1\]/gs; # Parser akzeptiert keine LaTeX-like-Kommandos
      $texmath =~ s/\\/\\\\/sg; # string is input to a java function which will parse \\ as a single backslash
      $texmath =~ s/ $rpr A /\\n/sg; # this must be a bare javascript-string
      $texmath =~ s/ $rpr B /\\r/sg; # this must be a bare javascript-string
      $texmath =~ s/\\/\\\\/sg; # string is moved by the viewmodel-transferprocess which evaluates escapes
      my $k = $emc;
      my $obs = "obs_math_";
      # Generate alphabetic name from number, since it is used as function name
      while ($k ne 0) {
	if (($k % 2) == 1) {
	  $k--;
	  $k /= 2;
	  $obs .= "b";
	} else {
	  $k /= 2;
	  $obs .= "a";
	}
      }
      my $dobs = "dv" . $obs;
      my $sata = "<!-- postmodelstart \/\/-->registerVariables(\"$texmath\",viewmodel.$obs);<!-- postmodelstop \/\/-->";
      $textex =~ s/\\begin{MEvalMathDisplay}<--EVMTAG-->\\end{MEvalMathDisplay}/\\ifttm\\begin{html}$sata<!-- viewmodelstart \/\/-->$obs: ko.observable("$texmath"),<!-- viewmodelstop \/\/--><div id="$dobs" data-bind="evalmathjax: $obs"><\/div>\\end{html}\\else\\begin{equation*}$orgmath\\end{equation*}\\fi/s ;
      $emc++;
    }
    
    # alignat* wie align* parsen
    $textex =~ s/\\begin{alignat\*}/\\begin{align\*}/g ;
    $textex =~ s/\\end{alignat\*}/\\end{align\*}/g ;

    # Nummeriere die alignstatements
    my $h = 1;
    while ($textex =~ s/\\begin{align\*}/\\begin{$rpr $h}/ ) { $h = $h + 1; }
    $h = 1;
    while ($textex =~ s/\\end{align\*}/\\end{$rpr $h}/ ) { $h = $h + 1; }


    $h = 1;
    while ($textex =~ /\\begin{$rpr $h}(.+?)\\end{$rpr $h}/ ) {
      my $content = $1;
      my $rep = $content;



      # Align-Umgebungen umformen

      $rep =~ s/\&\&/\& \&/g ;

      # intertext-Anweisungen aus Spaltenende loesen
      $rep =~ s/\\intertext{/\\\\ \\intertext{/g ;


      # Alles was in intertext-Klammern steht separat ablegen bei korrekter Zaehlung der Klammern

#       my $after = $rep;
#       $after =~ s/ $rpr A /\n/g;
#       $after =~ s/ $rpr B /\r/g;
#       print "BEFORE: \n$after\n\n";


      my @its = ();
      my $bail = 0;
      my $no = 1;
      while (($rep =~ /\\intertext{/ ) and ($bail==0)) {
        
        my $tpa = index($rep,"\\intertext{");
        my $tpb = $tpa+11;
        my $cl = 1;
        while (($cl > 0) and ($tpb<length($rep))) {
          $tpb++;
          if (substr($rep,$tpb,1) eq "{") { $cl++; }
          if (substr($rep,$tpb,1) eq "}") { $cl--; }
        }

        if ($cl != 0) {
          logMessage($CLIENTWARN, "Could not parse intertext (cl=$cl) in:\n$rep\n");
          $bail = 1;
        } else
        {
          
        }
        $tpb++;
        my $itext = substr($rep,$tpa,($tpb - $tpa));
        push @its, [$no, $itext];
        $rep = substr($rep,0,$tpa) . "\\MINTERTEXTREPLACEMENT{<!-- xitext;;$no; //-->}" . substr($rep,$tpb,length($rep)-($tpb));
        $no++;
      }

#       $after = $rep;
#       $after =~ s/ $rpr A /\n/g;
#       $after =~ s/ $rpr B /\r/g;
#       print "AFTER: \n$after\n\n";

      # Unterumgebungen separat speichern und am Ende wieder rueckeinsetzen um Probleme mit \\ und & zu vermeiden
      my @umg = ();

      my $j = 0;
      while ($rep =~ s/\\begin{(.+?)}(.+?)\\end{(.+?)}/$rpr TX $j/ ) {
        push @umg, [$j, $1, $2];
        $j++;
      }
      

      # Finde die maximale Spaltenzahl
      my @rows = split(/\\\\/,$rep);
      my @bems = split(/\\\\/,$rep);
      my $cn = 1;
      my $dobem = 0;
      for ($j=0; $j <= $#rows; $j++) {
    
        # &&-inhalt separat ablegen
        if ($rows[$j] =~ s/\&\&(.*)// ) { $dobem = 1; $bems[$j] = $1; } else { $bems[$j] = ""; }
        my $k = ($rows[$j] =~ tr/\&//);
        $k++;
        if ($k > $cn) { $cn = $k; }
      }
      
      # Bringe alle Zeilen auf die maximale Spaltenzahl und haenge die Bemerkungen an
      my $c;
      for ($j=0; $j <= $#rows; $j++) {
        my $k = ($rows[$j] =~ tr/\&//);
        for ($c=0; $c < ($cn - $k); $c++) {
        # Eine Spalte an Zeile $j anhaengen
        $rows[$j] = $rows[$j] . " \& ";
      }
      if ($dobem eq 1) { $rows[$j] = $rows[$j] . "\& \\;\\;$bems[$j]"; }
     }
      
      $rep = "";
      for ($j=0; $j <= $#rows; $j++) {
	if ($j ne 0 ) { $rep = $rep . "\\\\"; }
	$rep = $rep . $rows[$j];
      }
      
      $rep = "\\begin{eqnarray\*}" . $rep . "\\end{eqnarray\*}";

      # intertext-Anweisungen in align-Umgebungen ausbauen
      while ($rep =~ s/\\begin{eqnarray\*}(.*?)\\MINTERTEXTREPLACEMENT{(.*?)}/\\begin{eqnarray\*}$1\\end{eqnarray\*}$2\\begin{eqnarray\*}/ ) {
        # print "DEBUG: MINTERTEXT replatziert mit content $2\n";
      }

      # Geparkte intertexts einbauen
      for (my $k = 0; $k <= $#its; $k++) {
        my $nom = $its[$k][0];
        my $rl = $its[$k][1];
        $rl =~ s/\\intertext//g ;
        if (!($rep =~ s/<!-- xitext;;$nom; \/\/-->/$rl/ )) {
          logMessage($CLIENTWARN, "Could not relocate intertext $nom , content is $rl");
        }
      }

      # Geparkte Unterumgebungen einbauen
      for (my $k = 0; $k <= $#umg; $k++) {
      my $myc = $umg[$k][0];
      my $cmd = $umg[$k][1];
      my $co = $umg[$k][2];
      if ($rep =~ s/$rpr TX $myc/\\begin{$cmd}$co\\end{$cmd}/ ) {
      logMessage($VERBOSEINFO, "  Umgebung entparkt: $cmd: $co");
	}
      }


      $textex =~ s/\\begin{$rpr $h}(.+?)\\end{$rpr $h}/\\ifttm$rep\\else\\begin{$rpr lign\*}$content\\end{$rpr lign\*}\\fi/ ;
      $h = $h + 1;
    }

    $textex =~ s/$rpr lign/align/sg;
    $textex =~ s/ $rpr A /\n/sg;
    $textex =~ s/ $rpr B /\r/sg;

    # print "NEW:\n$textex\n\n";
 

    # -------------------------------- Ende Preprocessing per texfile -------------------------------------------------------
   
    # Schreiben der Datei oder vorher noch tikz-externalize
    
    if ($dotikzfile eq 1) {
      # Modifikationen sind hier noch nicht geschrieben und mintmod reicht Mtikzexternalize weiter
      # Lokales Makropaket installieren
      
      # Programm wird an dieser Stelle im Aufrufverzeichnis ausgefuehrt
      chdir($pdirname);
      system("cp $basis/converter/tex/$macrofile .");
      system("cp $basis/converter/tex/maxpage.sty .");
      my $mca = "pdflatex -shell-escape $pfilename";
      logMessage($CLIENTINFO, "  Starte pdflatex mit shellescape: $mca");
      my $rtt = system($mca);
      if ($rtt != 0) {
        logMessage($CLIENTERROR, "  pdflatex with tikzexternalize failed");
      } else {
        logMessage($CLIENTINFO, "  pdflatex with tikzexternalize ok");
      }
    }
    chdir($absexedir);

    $tex_open = open(MINTS, "> $texs[$ka]") or die "FATAL: Could not write $texs[$ka]\n";
    print MINTS $textex;
    close(MINTS);

    
  }
}

logTimestamp($CLIENTINFO, "Preparsing of $filecount texfiles finished");
logMessage($VERBOSEINFO, "  $globalposdirecthtml blocks for DirectHTML found");

$copyrightcollection = "\\begin{tabular}{llll}\%\n$copyrightcollection\\end{tabular}\n";

# Kopiere Konfigurationsdatei in Ausgabe-converter-Baum
logMessage($VERBOSEINFO, "Copying configfile $mconfigfile to " . $config{output} . "/converter/config.pl");
system("cp " . $mconfigfile . " " . $config{output} . "/converter/config.pl");

# Create copyright text file
my $copyrightfile = $config{output} . "/converter/tex/copyrightcollection.tex";
my $mints_open = open(MINTS, "> $copyrightfile") or die "FATAL: Could not create copyright file";
print MINTS "\%---------- Von mconvert.pl generierte Datei ------------\n$copyrightcollection";
close(MINTS);

# Erstelle Datei mit DirectHTML-Texten
my $directhtmlfile = $config{output} . "/converter/directhtml.txt";
$mints_open = open(MINTS, "> $directhtmlfile") or die "FATAL: Could not create file for DirectHTML.";
print MINTS "<!-- file directhtml.txt is autogenerated, do not modify //-->\n";
for ($i=0; $i <= $#DirectHTML; $i++ ) {
  print MINTS "<!-- startfilehtml;$i; //-->";
  print MINTS $DirectHTML[$i]."\n";
  print MINTS "<!-- stopfilehtml;$i; //-->";
}
close(MINTS);

# Erstelle Datei mit DirectHTML-Texten
my $directexercisesfile = $config{output} . "/converter/directexercises.tex";
$mints_open = open(MINTS, "> $directexercisesfile") or die "FATAL: Could not create file for DirectExercises";
print MINTS $globalexstring;
close(MINTS);

# Create main file for converter build
my $ttminputfile = $config{output} . "/converter/tex/vorkursxml.tex";
$mints_open = open(MINTS, "> $ttminputfile") or die "FATAL: Could not create converter input file";
print MINTS "% DIESE DATEI WURDE AUTOMATISCH ERSTELLT, UND SOLLTE NICHT VERAENDERT WERDEN (mconvert)\n";
print MINTS "\\documentclass{book}\n";
print MINTS "\\input{$macrofile}\n";
print MINTS "\\title{MINT-Module}\n";
print MINTS "\\author{MINT-Kolleg Baden-W\"urttemberg}\n";
print MINTS "\\newcounter{MChaptersGiven}\n";
print MINTS "\\setcounter{MChaptersGiven}{1}\n";
print MINTS "\\begin{document}\n";
print MINTS "\\input{" . $config{module} . "}\n";
print MINTS "\\end{document}\n";
close(MINTS);

# Create main file for PDF build
my $pdfinputfile = $config{output} . "/converter/tex/vorkurspdf.tex";
$mints_open = open(MINTS, "> $pdfinputfile") or die "FATAL: Could not create PDF input file";
print MINTS "% DIESE DATEI WURDE AUTOMATISCH ERSTELLT, UND SOLLTE NICHT VERAENDERT WERDEN (mconvert)\n";
print MINTS "\\newcounter{MChaptersGiven}\n";
print MINTS "\\setcounter{MChaptersGiven}{1}\n";
print MINTS "\\input{$macrofile}\n";
print MINTS "\\title{MINT-Module}\n";
print MINTS "\\author{MINT-Kolleg Baden-W\"urttemberg}\n";
print MINTS "\\begin{document}\n";
print MINTS "\\input{" . $config{module} . "}\n";
print MINTS "\\end{document}\n";
close(MINTS);

# Icons konvertieren
chdir($config{output});
logMessage($VERBOSEINFO, "PreIcons: CWD is " . cwd());
my @orgicons = <converter/buttons_org/*>; # Shell-Selektionsanweisung akzeptiert keine Strings bzw. parsed diese vorher!
my $file = "";
my $dyniconcss = "";
logMessage($VERBOSEINFO, "Converting icons");
foreach $file (@orgicons) {
   createButtonFiles($file, 100, 100); # 50,170 fuer halbgesaettigtes blau
   my $bnms = "";
   my $inms = "";
   if ($file =~ /(.*)buttons_org\/(.*).png/) {
      my $cssicon = "padding: 1px";
      $bnms = $2;
      $inms = $2;
      $inms =~ s/button_// ;
      $inms = $inms . "icon";
      # iconclasses fuer navi im neuen Design
      $dyniconcss .= " + \"";
      $dyniconcss .= injectEscapes(".inormal$bnms\n\{\n $cssicon;\n background-image: url('[LINKPATH]images\/$bnms"."1.png');\n\}\n");
      $dyniconcss .= injectEscapes(".iselected$bnms\n\{\n $cssicon;\n background-image: url('[LINKPATH]images\/$bnms"."2.png');\n\}\n");
      $dyniconcss .= injectEscapes(".igrey$bnms\n\{\n $cssicon;\n background-image: url('[LINKPATH]images\/$bnms"."3.png');\n\}\n\n");
      $dyniconcss .= "\"\r\n";
   }
}
chdir(".."); # Verlaesst sich darauf, dass $config{output} nur eine Verzeichnisebene ist !

logMessage($VERBOSEINFO, "Creating stylesheets");
chdir($config{output} . "/converter/precss");
system("php -n grundlagen.php >grundlagen.pcss");

# Ersetze Farben im Stylesheet mit den Vorgaben

my $cccs = open(CSS, "< grundlagen.pcss") or die "FATAL: Could not open pcss-file";
my $cccs2 = open(OCSS, "> grundlagen.css") or die "FATAL: Could not create css-file";
my $cccsJ = open(JCSS, "> dynamiccss.js") or die "FATAL: Could not create dynmiccss.js-file";
my @mycss = <CSS>;

close(CSS);


my $ckey = "";
my $cval = "";

# Freie Parameter sind in convinfo.js eingetragen!

# Farben parsen (Strings, das #-Prefix wird dynamisch zugefuegt)
my $jrow = "";
my $fz;
print JCSS "var COLORS = new Object();\n";
while (($ckey, $cval) = each(%{$config{'colors'}})) {
  print JCSS "COLORS.$ckey = \"$cval\";\n";
}

# Fonts parsen (Strings)
print JCSS "var FONTS = new Object();\n";
while (($ckey, $cval) = each(%{$config{'fonts'}})) {
  $cval = injectEscapes($cval);
  print JCSS "FONTS.$ckey = \"$cval\";\n";
}

# Sizes parsen (numerische Werte)
print JCSS "var SIZES = new Object();\n";
while (($ckey, $cval) = each(%{$config{'sizes'}})) {
  print JCSS "SIZES.$ckey = $cval;\n";
}

# Farben, Fonts und Sizes in CSS-Dateien ersetzen, css-Datei auch als JavaScript-Variable OHNE ERSETZUNG erzeugen
print JCSS "var DYNAMICCSS = \"\"\n";
my $row;
foreach $row (@mycss) {
  print OCSS $row; # unveraendert in Ziel-CSS schreiben, Ersetzung wird dynamisch von den Seiten vorgenommen
  $row = injectEscapes($row);
  print JCSS " + \"" . $row . "\"\n";
  while (($ckey, $cval) = each(%{$config{'colors'}})) {
    $row =~ s/\[-$ckey-\]/\#$cval/g ;
  }
  while (($ckey, $cval) = each(%{$config{'fonts'}})) {
    $row =~ s/\[-$ckey-\]/$cval/g ;
  }
  while (($ckey, $cval) = each(%{$config{'sizes'}})) {
    $cval .= "px";
    $row =~ s/\[-$ckey-\]/$cval/g ;
  }
}
print JCSS "$dyniconcss;\n";
close(OCSS);
close(JCSS);


system("cp grundlagen.css ../files/css/.");
system("cp dynamiccss.js ../files/.");

# mintmod.tex so veraendern, dass lokale Preamblen und Tagmakros eingebunden werden, sowie automatisierte tags
chdir("../tex");
# MUSS APPEND SEIN
my $ipf = open(MINTP, ">> $macrofile") or die "FATAL: Could not append local preambles to $macrofile";
print MINTP "\n% ---------- Automatisch eingebundene Preamblen aus mconvert.pl heraus ---------------\n";
logMessage($CLIENTINFO, "Included preambles:");
for ( $i=0; $i <= $#IncludeStorage; $i++ ) {
  logMessage($CLIENTINFO, " module=$IncludeStorage[$i][0], filename=$IncludeStorage[$i][1]");
  print MINTP "% Automatische Einbindung der Preamble " . $IncludeStorage[$i][1] . ":\n";
  print MINTP $IncludeStorage[$i][2] . "\n";
}

# print MINTP "% Automatisierte Tagmakros ---------- \n";
# print MINTP "\\ifttm\n";
# print MINTP "\\else\n";
# print MINTP "\\fi\n";

close(MINTP);

$ipf = open(MINTP, "< $macrofile") or die "FATAL: Count not reopen $macrofile";
my $mintstr = "";
my $mintr = "";
while(defined($mintr = <MINTP>)) {
  $mintstr .= $mintr;
}
close(MINTP);

my $mint_tex = $mintstr;
my $mint_html = $mintstr;

$mint_tex =~ s/\\ifttm(.+?)\\else(.+?)\\fi/$2/sg;
$mint_tex =~ s/\\ifttm(.+?)\\fi/\n/sg;
$mint_html =~ s/\\ifttm(.+?)\\else(.+?)\\fi/$1/sg;
$mint_html =~ s/\\ifttm(.+?)\\fi/$1/sg;


logMessage($VERBOSEINFO, "TeX-Macro definitions in $macrofile:");


while($mint_tex =~ m/\\def\\(.+?)(\#.)*\{/sg ) {
  logMessage($VERBOSEINFO, "  def: $1");
}
while($mint_tex =~ m/\\newcommand\{(.+?)\}/sg ) {
  logMessage($VERBOSEINFO, "  newcommand: $1");
}

# Erzeuge den HTML-Baum
chdir("../..");
$ndir = getcwd; # = $output in voller expansion
chdir("$ndir/converter");
logMessage($VERBOSEINFO, "Changing to directory $ndir/converter");

# Zerlegung und Umwandlung der XML-Datei vornehmen
converter_conversion();

chdir("tex");
my $pdfok = 1;
if ($config{dopdf} eq 1) {
    my $doct = "";
    my $docdesc = "";
    while ((($doct, $docdesc) = each(%{$config{generate_pdf}})) and ($pdfok == 1)) {
      logMessage($CLIENTINFO, "======= Generating PDF file $doct.tex ($docdesc) ========================================");

      my $rt1 = system("pdflatex $doct.tex");
      if ($rt1 != 0) {
        print("RETURNVALUE $rt1 from pdflatex, aborting PDFs entirely\n");
	$pdfok = 0;
      } else {      
	$rt1 = system("pdflatex $doct.tex");
	if ($rt1 != 0) {
          print("RETURNVALUE $rt1 from pdflatex, aborting PDFs entirely\n");
	  $pdfok = 0;
	} else {      
	  $rt1 = system("makeindex $doct");
	  if ($rt1 != 0) {
            print("RETURNVALUE $rt1 from pdflatex, aborting PDFs entirely\n");
	    $pdfok = 0;
	  } else {      
	    $rt1 = system("pdflatex $doct.tex");
	    if ($rt1 != 0) {
              print("RETURNVALUE $rt1 from pdflatex, aborting PDFs entirely\n");
	      $pdfok = 0;
	    }
	  }
	}
      }
    $i++;
  }
  if ($pdfok == 1) {
    print("======= PDF files build successfully =======================================\n");
  } else {
    print("======= PDF files have not been build =================================\n");
  }
}


logMessage($VERBOSEINFO, "Changing back to directory $ndir");
chdir("$ndir");

# Loesche das build-Verzeichnis und berichtige den Baum
if ($config{dopdf} eq 1) {
  if ($pdfok == 1) {
    system("cp $ndir/converter/tex/*.pdf $ndir/.");
    print("PDFs generated\n");
  } else {
    print("No PDFs generated due to errors\n");
  }
}

if ($config{doscorm} eq 1) { system("cp -R $ndir/converter/SCORM2004v4/* $ndir/."); }


if ($config{localjax} eq 1) {
  logMessage($CLIENTINFO, "MathJax 2.4 (full package) is added locally");
  system("mkdir $ndir/MathJax");
  system("tar -xzf $ndir/converter/mathjax24complete.tgz --directory=$ndir/MathJax/.");
  #system("tar -xzf $ndir/converter/mathjax23reduced.tgz --directory=$ndir/MathJax/.");
  #print "Nutze reduzierte Version von MathJax ohne ImageFonts (benoetigt IE6+, Chrome, Safari 3.1+, Firefox 3.5+, oder Opera 10+)\n";
}

system("mv $ndir/converter/" . $config{outtmp} . "/* $ndir/.");
system("rmdir $ndir/converter/" . $config{outtmp});

if ($config{cleanup} == 0) {
  logMessage($CLIENTINFO, "CONVERTER-SUBDIRECTORY IS NOT BEING REMOVED");
} else {
  system("rm -fr $ndir/converter");
  logMessage($CLIENTINFO, "converter-directory cleaned up");
}

# Globales Starttag suchen und Baum dazu anpassen

$call = "find -P $ndir/. -name \\*.html";
my $htmllist = `$call`; # Finde alle html-Files, auch in den Unterverzeichnissen
my @htmls = split("\n",$htmllist);
$nt = $#htmls + 1;
my $htmlzeile = "";
my $starts = 0;
for ($ka = 0; $ka < $nt; $ka++) {
    my $content = "";
    my $hfilename = $htmls[$ka];
    my $html_open = open(MINTS, "< $hfilename") or die "FATAL:: Could not open $htmls[$ka]\n";
    while(defined($htmlzeile = <MINTS>)) {
      if ($htmlzeile =~ m/<!-- mglobalstarttag -->/ ) {
        $starts++;
        logMessage($VERBOSEINFO, "--- Starttag found in file $hfilename");
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $startfile = "mpl/" . $2 . ".html";
        $entryfile = "entry_" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalchaptertag -->/ ) {
        logMessage($VERBOSEINFO, "--- Chaptertag found in file $hfilename");
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $chapterfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalconftag -->/ ) {
        logMessage($VERBOSEINFO, "--- Configtag found in file $hfilename");
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $configfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobaldatatag -->/ ) {
        logMessage($VERBOSEINFO, "--- Datatag found in file $hfilename");
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $datafile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalfavotag -->/ ) {
        print "--- Favoritestag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $favofile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mgloballocationtag -->/ ) {
        logMessage($VERBOSEINFO, "--- Locationtag found in file $hfilename");
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $locationfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalsearchtag -->/ ) {
        logMessage($VERBOSEINFO, "--- Searchtag found in file $hfilename");
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $searchfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalstesttag -->/ ) {
        logMessage($VERBOSEINFO, "--- STesttag found in file $hfilename");
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $stestfile = "mpl/" . $2 . ".html";
      }
    }
    close(MINTS);
}

if ($starts eq 0 ) {
  die("FATAL: Global start tag not found, HTML tree is disfunctional");
} else {
  if ($starts ne 1) {
    logMessage($CLIENTERROR, "Multiple start tags found, using last one");
  }
}

createRedirect("index.html", $startfile, 0);
if ($config{doscorm} == 1) {
  createRedirect($entryfile, $startfile, 1);
}
if ($chapterfile ne "") { createRedirect("chapters.html", $chapterfile,0); } else { logMessage($CLIENTINFO, "No Chapter-file defined"); }
if ($configfile ne "") { createRedirect("config.html", $configfile,0); } else { logMessage($CLIENTINFO, "No Config-file defined"); }
if ($datafile ne "") { createRedirect("cdata.html", $datafile,0); } else { logMessage($CLIENTINFO, "Keine Data-Datei definiert"); }
if ($searchfile ne "") { createRedirect("search.html", $searchfile,0); } else { logMessage($CLIENTINFO, "Keine Search-Datei definiert"); }
if ($favofile ne "") { createRedirect("favor.html", $favofile,0); } else { logMessage($CLIENTINFO, "Keine Favoriten-Datei definiert"); }
if ($locationfile ne "") { createRedirect("location.html", $locationfile,0); } else { logMessage($CLIENTINFO, "Keine Location-Datei definiert"); }
if ($stestfile ne "") { createRedirect("stest.html", $stestfile,0); } else { logMessage($CLIENTINFO, "Keine Starttest-Datei definiert"); }

if ($config{doscorm} eq 1) { createSCORM(); }

if ($config{borkify} eq 1) {
  chdir("$ndir/mpl");
  borkifyHTML();
  chdir("..");
  minimizeJS();
}

chdir($ndir);

system("rm -fr *.js~");

if ($config{dozip} eq 0) {
  logMessage($CLIENTINFO, "HTML module " . ((($config{dopdf} eq 1) and ($pdfok eq 1)) ? "and PDF " : " ") . "created");
} else {
  system("chmod -R 777 *");
  system("zip -r $zip *");
  system("cp $zip ../.");
  chdir("..");
  system("rm -fr $ndir");
  logMessage($CLIENTINFO, "HTML module" . ((($config{dopdf} eq 1) and ($pdfok eq 1)) ? "and PDF " : " ") . "created and zipped to $zip");
}

logMessage($CLIENTINFO, "Tree entry chain:");
logMessage($CLIENTINFO, "$  ndir/index.html -> $ndir/$startfile");
if ($config{doscorm} == 1) {
  logMessage($CLIENTINFO, "  SCORM -> $ndir/$entryfile -> $ndir/$startfile");
}

logTimestamp("mconvert.pl finished successfully");

close(LOGFILE);

exit;


