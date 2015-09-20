#!/usr/bin/env perl

use strict;
use warnings;

#
#  mconvert.pl
#  Nimmt Preprocessing und Einrichtung der Verzeichnisstruktur vor und ruft den eigentlichen Konverter (conv.pl) auf
#  Autor: Daniel Haase, 2014
#  daniel.haase@kit.edu
#
use Cwd;
use File::Path;

my $helptext = "Usage: mconvert.pl <configuration.pl>\n\n";

# use lib "/home/daniel/BWSYNC/PreTU9Konverter/converter";
# use courseconfig;

# --------------------------------- Parameter zur Erstellung des Modulpakets ----------------------------------

our %config = ();       
our $mconfigfile = "";       # Konfigurationsdatei (mit Pfad relativ vom Aufruf aus)
our $basis = "";             # Das Verzeichnis, in dem converter liegt (wird momentan auf aktuelles Verzeichnis gesetzt)
our $rfilename = "";         # Filename of main tex file including path relative to execution directory
our $zip = "";               # Filename of zip file (if neccessary)

our @IncludeStorage = ();
our @PDFDeclare = ();
our @DirectHTML = ();

# -------------------------------------------------------------------------------------------------------------

my @tominify = ("mintscripts.js", "servicescripts.js", "intersite.js", "convinfo.js", "userdata.js", "mparser.js", "dlog.js", "exercises.js");

# -------------------------------------------------------------------------------------------------------------

my $breakoff = 0;
my $i;
my $ndir = ""; # wird am Programmstart gefuellt

my $copyrightcollection = "";

my $globalexstring = "";

# Redirects passend zu den Buttons
our $startfile = ""; # Wird vor Aufruf von createSCORM gesetzt
our $chapterfile = "";
our $configfile = "";
our $datafile = "";
our $searchfile = "";
our $favofile = "";
our $locationfile = "";
our $stestfile = "";
our $betafile = "";

# ----------------------------- Funktionen -----------------------------------------------------------------------

our $randcharstr = "0123456789,.;abcxysqrt()/*+-";

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
  # print("$u is a unit mod $lan\n");
  
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
  print("Minimiere JS:\n");
  my $borknt = $#tominify + 1;
  print "  $borknt js-Dateien vorgesehen\n";
  my $borkka;
  my $borkfilename = "";
  for ($borkka = 0; $borkka < $borknt; $borkka++) {
    $borkfilename = $tominify[$borkka];

    
    my $rt = `grep console.log $borkfilename`;
    if ($rt ne "") {
      print "  JavaScript-Datei $borkfilename enthaelt console.log-Befehle, die durch logMessage zu ersetzen sind!\n";
    }
    
    my $borkcall = "file -i $borkfilename";
    $rt = `$borkcall`;
    my $domini = 0;
    print("  -> " . $borkfilename);
    if ($rt =~ m/charset\=us\-ascii/s ) {
      print " (ist ASCII-codiert)\n";
      $domini = 1;
    } else {
      $rt =~ m/charset\=(.+)\n/s ;
      print " => Charset " . $1 . " ungeeignet, nur ASCII erlaubt, wird nicht minimiert!\n";
    }
    
    if ($domini eq 1) { 
      $borkcall = "java -jar $basis/converter/yuicompressor-2.4.8.jar $borkfilename -o $borkfilename";
      print("     " . $borkcall . "\n");
      system($borkcall);
      $fdi++;
    }
  }
  
  print "  $fdi Dateien minimiert\n";
}

# Borkifiziert alle HTML-Dateien im aktuellen Verzeichnis (rekursiv!)
sub borkifyHTML {

  my $fdi = 0;
  print("Borkifiziere HTML:\n");
  my $borkfilecount = 0;
  my $borkcall = "find -P . -name \\*.html";
  my $borktexlist = `$borkcall`; # Finde alle tex-Files, auch in den Unterverzeichnissen
  my @borktexs = split("\n",$borktexlist);
  my $borknt = $#borktexs + 1;
  print "  $borknt html-Dateien gefunden\n";
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
      # print("    Lösung $s borkifiziert\n");
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
  
  print "  $fdi Dateien borkifiziert\n";

}


# Prueft, ob die zum Konvertieren notwendigen Systembestandteile vorhanden sind
sub checkSystem {
  # Pruefe ob dia installiert ist KANN AUSKOMMENTIERT WERDEN WENN DIA NICHT BENUTZT WERDEN SOLL
  my $reply = `dia --version 2>&1`;
  if ($reply =~ m/0\.97\.2/i ) {
    # dia erfolgreich getestet
  } else {
    print("Program dia (version 0.97.2) not found, dia-compilation will not work");
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
    print "JDK found, using javac from version $1\n";
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


# Parameter: filename, redirect-url
sub createRedirect {
  my $filename = $_[0];
  my $rurl = $_[1];

  my $indexhtml = <<ENDE;
<!DOCTYPE HTML>
<html lang="de-DE">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="refresh" content="1;url=$rurl">
        <script type="text/javascript">
             window.location.href = "$rurl"
        </script>
        <title>Weiterleitung auf Hauptseite der Onlinemodule</title>
    </head>
    <body>
        Klicken Sie <a class="MINTERLINK" href="$rurl">hier</a>, falls Sie nicht automatisch weitergeleitet werden.
    </body>
</html>
ENDE
  
  my $tempfile = open(MINTS, ">$ndir/$filename");
  print MINTS $indexhtml;
  close(MINTS);
  print "Redirect auf $rurl in $filename erstellt\n";
}

sub createSCORM {
  # Stelle Dateireferenzen fuer Manifestdatei zusammen, iteriere dazu jede einzelne Datei im Baum
  print "Sammle Dateireferenzen fuer SCORM-Manifest, Startdatei ist $startfile\n";
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
  my $manifest_title = "Onlinemodule 1";
  my $manifest_comment = "Manifest template fuer MINT-Onlinemodule nach Spezifikation SCORM 2004 4th Edition bzw. 1.2, diese Datei wurde automatisch generiert, www.mint-kolleg.de";

  
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
    <resource identifier="r1" type="webcontent" adlcp:scormType="sco" href="$startfile"> 
    
$mfiles
    
    </resource>
  </resources>
</manifest>
ENDE


#        <imsss:primaryObjective objectiveID = "PRIMARYOBJ" satisfiedByMeasure="true">
#          <imsss:minNormalizedMeasure> 0.6 </imsss:minNormalizedMeasure>
#        </imsss:primaryObjective>


  print "Erstelle SCORM-Manifestdatei mit title=$manifest_title, version=$manifest_version und id=$manifest_id\n";
  
    # Erstelle Manifestdatei fuer SCORM
  my $scorm_open = open(MINTS, "> ./imsmanifest.xml") or die "Fehler beim Erstellen der Manifestdatei.\n";
  print MINTS "$manifest";
  close(MINTS); 
  
  print "HTML-Baum wird als SCORM-Lernmodul Version 2004v4 eingerichtet\n";
}

# Checks if options are consistent, quits with a fatal error otherwise
sub checkOptions {
  open(F,$basis . "/converter/conv.pl") or die ("FATAL: conv.pl not found in $basis/converter");
  close(F);

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
}


# ----------------------------- Start Hauptprogramm --------------------------------------------------------------

# my $IncludeTags = ""; # Sammelt die Makros fuer predefinierte Tagmakros, diese werden an mintmod.tex angehaengt



checkSystem();

if ($#ARGV eq 0) {
  # Nur ein Parameter: Gibt Konfigurationsdatei relativ zum Aufruf an
    $mconfigfile = $ARGV[0];
    if ($mconfigfile =~ m/(.+).pl/ ) {
      if ($mconfigfile =~ m/\// ) { die("FATAL: Configuration file must be in calling directory"); }
      print("  Configuration file: " . $mconfigfile . "\n");
      unless (%config = do $mconfigfile) {
        warn "Couldn't parse $mconfigfile: $@" if $@;
        warn "Couldn't run $mconfigfile" unless %config;
      }
    } else {
      die("FATAL: Configuration file must be of type name.pl");
    }
    
    print("   Configuration used: " . $config{description} . "\n");

} else {
    die($helptext);
}

my $absexedir = Cwd::cwd(); 
$basis = $absexedir;

checkOptions();

$rfilename = $config{source} . "/" . $config{module}; # sollte durch PERL-Join ersetzt werden

print(" Absolute directory: " . $absexedir . "\n");
print("Converter directory: " . $basis . "\n");
print("   Source directory: " . $config{source} . "\n");
print("   Output directory: " . $config{output} . "\n");
print("   Main module file: " . $rfilename . "\n");
print("Generating HTML tree as described in " . $rfilename . "\n");

if ($config{doscorm} eq 1) {
  print("...tree will be SCORM-compatible (version 2004v4)\n");
} else {
  print("...no SCORM support\n");
}

if ($config{dopdf} eq 1) {
  print("...generating PDF files\n");
} else {
  print("...no PDF files\n");
}

if ($config{qautoexport} eq 1) {
  print("...exercise autoexport activated\n");
}

if ($config{dotikz} eq 1) {
  print("...TikZ externalization activated\n");
}

open(F,$rfilename) or die("FATAL: Cannot open main tex file $rfilename");
close(F);

# Preprocessing of main file
my $roottex = "";
my $tex_open = open(MINTS, "< $rfilename") or die("FATAL: Cannot read main tex file $rfilename");
my $texzeile = "";
while(defined($texzeile = <MINTS>)) {
  # Wegen direkter HTML-Zeilen darf man %-Kommentare nicht streichen
  $roottex .= $texzeile;
}
close(MINTS);

while ($roottex =~ s/\\MPragma{PDFTEXDeclare;(.+?)}/\\MPragma{Nothing}/ ) {
  print "Root-Pragma PDFTEXDeclare: $1\n";
  push @PDFDeclare, [ $1 ];
}

my $colorfile = "";

if ($roottex =~ s/\\MColorFile{(.+?)}// ) {
  $colorfile = $1; # Dateiname Relativ zu converter/precss
  print("Colorfile declared: " . $colorfile . "\n");
} else {
  $colorfile = "farben_bare.ini";
  print("No colorfile given, using standard " . $colorfile . "\n");
}


print("Settup up output directory " . $config{output} . "\n");
system("rm -fr " . $config{output});
system("mkdir " . $config{output});
system("cp -R $basis/converter " . $config{output} . "/.");
system("cp -R " . $config{source} . "/* " . $config{output} . "/converter/tex/.");

# Preprocessing aller tex-Files
my $filecount = 0;
my $globalposdirecthtml = 0; # Fuer DirectHTML-Array, ist unique fuer alle Teildateien
my $call = "find -P " . $config{output} . "/converter/tex/. -name \\*.tex";
print "Executing: $call\n";
my $texlist = `$call`; # Finde alle tex-Files, auch in den Unterverzeichnissen
my @texs = split("\n",$texlist);
my $nt = $#texs + 1;
print "$nt texfiles found, processing...\n";
my $ka;
my $pcompletename = "";
my $dotikzfile = 0;
for ($ka = 0; $ka < $nt; $ka++) {

  if (($texs[$ka] =~ /mintmod/ ) or ($texs[$ka] =~ /tree(.)\.tex/ ) or ($texs[$ka] =~ /tree\.tex/ )) {
    print "Preprocessing ignores $texs[$ka]\n";
  } else {
    # -------------------------------- Start Preprocessing per texfile -------------------------------------------------------
    my $textex = "";
    $texzeile = "";
    $pcompletename = $texs[$ka];
    $pcompletename =~ m/(.+)\/(.+?).tex/i;
    my $pdirname = $1;
    my $pfilename = $2 . ".tex";
    # print "...using directory $pdirname\n";
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
      print "Tree-preprocess on module $modulname in directory $prx\n";
    } else {
      print "Tree-preprocess on bare file $pfname in directory $prx\n";
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
    if ($vc > 0) { print " $vc different verb-escape chars found in tex-file\n"; }
      
    for ($vi = 0; $vi < $vc; $vi++ ) {
      my $c = $verbc[$vi];
      print " verb-char $c\n";
      if ($c eq "\%") {
        # Es gibt wirklich Autoren die in einem LaTeX-Dokument das % als Begrenzer fuer \verb einsetzen, das macht es tricky
	while ($textex =~ s/\\verb$c([^$c]*?)$c/\\verb\\PERCTAG$1\\PERCTAG/ ) { print "  Delimiter in \%-verb-line escaped\n"; }
      } else {
	while ($textex =~ s/\\verb$c([^$c]*?)\%([^$c]*?)$c/\\verb$c$1\\PERCTAG$2$c/ ) { print "  \% in verb-line escaped (special char $c)\n"; }
      }
    }
    
    while ($textex =~ s/(?<!\\)\%([^\n]+?)\n/\%\n/s ) { $coms++; }
    if ($coms != 0) { print "  $coms LaTeX-commentlines removed from file\n"; }

    while ($textex =~ s/\\PERCTAG/\%/ ) { print "  \% in verb-line reinstated\n"; }

    
    $dotikzfile = 0;
    if ($textex =~ s/\\Mtikzexternalize//gs ) {
      print "  tikzexternalize activated\n";
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
    # if ($qex != 0) { print "  " . $qex . " Aufgaben exportiert\n"; }
       
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
      print "  found BARE tikzexternalize and removed it (please use macro from mintmod.tex instead)\n";
    }

    
    #  ------------------------ Pragmas einlesen und verarbeiten ----------------------------------

    if ($textex =~ m/\\MPragma{SolutionSelect}/ ) {
      if ($config{nosols} eq 0) {
        print "  Pragma SolutionSelect: Ignored due to nosols==0\n";
      } else {
        print "  Pragma SolutionSelect: MSolution-environments will be removed: ";
	while ($textex =~ s/\\begin{MSolution}(.+?)\\end{MSolution}/\\relax/s ) { print "."; }
	print "\n";
        print "                         MHint{Lösung}-environments will be removed: ";
	while ($textex =~ s/\\begin{MHint}{Lösung}(.+?)\\end{MHint}/\\relax/s ) { print "."; }
	while ($textex =~ s/\\begin{MHint}{L"osung}(.+?)\\end{MHint}/\\relax/s ) { print "."; }
	while ($textex =~ s/\\begin{MHint}{L\\"osung}(.+?)\\end{MHint}/\\relax/s ) { print "."; }
	print "\n";
      }
    }

    # PYTHONPARSING --------------------------------------
    
    if ($textex =~ m/\\MPragma{MathSkip}/ ) {
      print "  Pragma MathSkip: Skips starting math-environments inserted\n";
      $textex =~ s/(?<!\\)\\\[/\\MSkip\\\[/g;
      $textex =~ s/(?<!\\)\$\$/\\MSkip\$\$/g;
      $textex =~ s/(?<!\\)\\begin{eqnarray/\\MSkip\\begin{eqnarray/g;
      $textex =~ s/(?<!\\)\\begin{equation/\\MSkip\\begin{equation/g;
      $textex =~ s/(?<!\\)\\begin{align/\\MSkip\\begin{align/g;
    }

    while ($textex =~ s/\\MPragma{Substitution;(.+?);(.+?)}/\\MPragma{Nothing}/ ) {
      print "  Pragma Substitution: $1 --> $2\n";
      my $s1 = $1;
      my $s2 = $2;
      $textex =~ s/$s1/$s2/g ;
    }

    my $incfound;
    while ($textex =~ s/\\MPreambleInclude{(.*)}/\\MPragma{Nothing}/ ) {
      my $prename = $1;
      print "  Local preamble included: $prename\n";
      # Nicht doppelt einbinden, Liste geht ueber ALLE tex-files!
      $incfound = 0;
      for ( $i=0; $i <= $#IncludeStorage; $i++ ) {
        if ($IncludeStorage[$i][1] eq $prename) {
          print "    Preamble found again: " . $prename . " (will be ignored, preamble from file " . $IncludeStorage[$i][0] . " is in use)\n";
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
      $textex =~ s/\\input{mintmod\.tex}//g ;
      $textex =~ s/\\input{mintmod}//g ;
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
    while (($textex =~ m/\\MDia\{(.+?)\}/g ) and ($config{diaok} == 1)) {
      my $dprx = $config{output} . "/converter/tex/$prx/$1";
      #print "DEBUG Verarbeite dia-Diagramm $dprx\n";
      # system "dia --export $dprx.png --filter=cairo-alpha-png $dprx.dia";
      
      my $rt = 0;
      
      $rt = system("dia --export $dprx.eps $dprx.dia");
      if ($rt == 0) {
        system "convert -density 180 $dprx.eps -resample 180 $dprx$suffixpdf.png"; 
        $rt = system("convert -density 53 $dprx.eps -resample 53 $dprx$suffixhtml.png");
      }
      
      if ($rt != 0) {
        $config{diaok} = 0;
        print "ERROR dia/conv-chain failed with return value $rt\n";
      }
    } 

    if (($config{diaok} == 0) and ($breakoff == 0)) { $breakoff = 1; print "ERROR dia/conv-chain aborted\n"; }
    
    # Eindimensionale pmatrix-Umgebungen als eindimensionale Arrays umsetzen
    if ($textex =~ s/\\begin{pmatrix}([^&]*?)\\end{pmatrix}/\\ifttm\\left({\\begin{array}{c}$1\\end{array}}\\right)\\else\\begin{pmatrix}$1\\end{pmatrix}\\fi/sg ) {
      print "  pmatrix-environment of dimension 1 substituted\n";
    }
    
    # flushleft-Umgebungen im html ignorieren
    if ($textex =~ s/\\begin{flushleft}(.*?)\\end{flushleft}/\\ifttm{$1}\\else\\begin{flushleft}$1\\end{flushleft}\\fi/sg ) {
      print "  flushleft-environment removed (no counterpart in html available right now)\n";
    }

    # vdots und hdots ersetzen
    $textex =~ s/\\hdots/\\MHDots/g ;
    $textex =~ s/\\vdots/\\MVDots/g ;
    
    
    if ($textex =~ m/\\begin{pmatrix}/s ) { print "  Multidimensional pmatrix-environments found, cannot be processed!\n"; }
    
    # \relax auf \MRelax umbiegen, da \relax nicht von ttm unterstuetzt
    if ($textex =~ s/\\relax/\\MRelax/g ) { print "  Command \\relax replaced\n"; }
    
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
          print "ERROR: could not parse intertext (cl=$cl) in:\n$rep\n\n";
          $bail = 1;
        } else
        {
          
        }
        $tpb++;
        my $itext = substr($rep,$tpa,($tpb - $tpa));
        # print "DEBUG: Extract ist |$itext|\n";
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
      my $k;
      for ($k = 0; $k <= $#its; $k++) {
        my $nom = $its[$k][0];
        my $rl = $its[$k][1];
        $rl =~ s/\\intertext//g ;
        if (!($rep =~ s/<!-- xitext;;$nom; \/\/-->/$rl/ )) {
          print "ERROR: Could not relocate intertext $nom , content is $rl\n";
        }
      }

      # Geparkte Unterumgebungen einbauen
      for ($k = 0; $k <= $#umg; $k++) {
      my $myc = $umg[$k][0];
      my $cmd = $umg[$k][1];
      my $co = $umg[$k][2];
      if ($rep =~ s/$rpr TX $myc/\\begin{$cmd}$co\\end{$cmd}/ ) {
      # print "  Umgebung entparkt: $cmd: $co\n";
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
      system("cp $basis/converter/tex/mintmod.tex .");
      system("cp $basis/converter/tex/maxpage.sty .");
      my $mca = "pdflatex -shell-escape $pfilename";
      print "  Starte pdflatex mit shellescape: $mca\n";
      my $rtt = system($mca);
      if ($rtt != 0) {
        print "  pdflatex with tikzexternalize failed!\n";
      } else {
        print "  pdflatex with tikzexternalize ok\n";
      }
    }
    chdir($absexedir);

    $tex_open = open(MINTS, "> $texs[$ka]") or die "FATAL: Could not write $texs[$ka]\n";
    print MINTS $textex;
    close(MINTS);

    
  }
}

print "Preparsing of $filecount texfiles finished\n";
print "  $globalposdirecthtml blocks for DirectHTML found\n";

$copyrightcollection = "\\begin{tabular}{llll}\%\n$copyrightcollection\\end{tabular}\n";

# Kopiere Konfigurationsdatei in Ausgabe-converter-Baum
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
print MINTS "\\input{mintmod.tex}\n";
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
print MINTS "\\input{mintmod.tex}\n";
print MINTS "\\title{MINT-Module}\n";
print MINTS "\\author{MINT-Kolleg Baden-W\"urttemberg}\n";
print MINTS "\\begin{document}\n";
print MINTS "\\input{" . $config{module} . "}\n";
print MINTS "\\end{document}\n";
close(MINTS);

# Icons konvertieren
my $iconselector = $config{output} . "/converter/buttons_org/*";
print "CWD is " . cwd() . "\n";
print "Iconselector is $iconselector\n";
my @orgicons = <$iconselector>;
my $file = "";
my $f = "";
print "Converting icons:\n";
my $icondynfile = $config{output} . "/converter/files/css/dynicons.css";
my $ics = open(MINTS, "> $icondynfile") or die "FATAL: Could not create CSS style file";
print MINTS "\/* This file was automatically generated by mconvert.pl, do not modify it! *\/\n\n";
foreach $file (@orgicons) {
   # Normaler Button
   $f = $file;
   $f =~ s/converter\/buttons_org/converter\/files\/images/ ;
   $f =~ s/.png/1.png/ ;
   system("cp -f $file $f"); 

   # Gedrueckter Button (gamma-Korrektur auf 5 gesetzt)
   $f = $file;
   $f =~ s/converter\/buttons_org/converter\/files\/images/ ;
   $f =~ s/.png/2.png/ ;
   system("convert -gamma 2 $file $f"); 
   
   # Gegrauter Button (Farbsaettigung entfernt)
   $f = $file;
   $f =~ s/converter\/buttons_org/converter\/files\/images/ ;
   $f =~ s/.png/3.png/ ;
   system("convert -colorspace Gray $file $f"); 
  
   my $bnms = "";
   my $inms = "";
   if ($file =~ /(.*)buttons_org\/(.*).png/) {
      $bnms = $2;
      $inms = $2;
      $inms =~ s/button_// ;
      $inms = $inms . "icon";
      print MINTS "\/* Icon entry $inms *\/\n";

      # iconclasses fuer navigation im alten Design
#       print MINTS "div\#navigation li\#$inms a \{\n";
#       print MINTS "  background-image: url('..\/images\/$bnms"."1.png');\n";
#       print MINTS "\}\n";
#       print MINTS "div\#navigation li\#$inms a.selected \{\n";
#       print MINTS "  background-image: url('..\/images\/$bnms"."2.png');\n";
#       print MINTS "  color: \#708005;\n";
#       print MINTS "\}\n";
#       print MINTS "div\#navigation li\#$inms a:hover \{\n";
#       print MINTS "  background-image: url('..\/images\/$bnms"."2.png');\n";
#       print MINTS "\}\n";
      
      # iconclasses fuer navi im neuen Design
      print MINTS ".inormal$bnms\n\{\n background-image: url('..\/images\/$bnms"."1.png');\n\}\n";
      # print MINTS ".inormal$bnms:hover\n\{\n background-image: url('..\/images\/$bnms"."2.png');\n\}\n";
      print MINTS ".iselected$bnms\n\{\n background-image: url('..\/images\/$bnms"."2.png');\n\}\n";
      print MINTS ".igrey$bnms\n\{\n background-image: url('..\/images\/$bnms"."3.png');\n\}\n\n";
 
      # print " - $inms\n";
   }

    

}
close(MINTS);

# # Predefinierte Tagmakros umsetzen (NICHT MEHR VERWENDET)
# print "Erzeuge predefinierte Tagmakros:\n";
# my $tagf = open(MINTS, "< $output/converter/textags.ini") or die "Fehler beim Erstellen der Tagmakros: textags.ini nicht gefunden.\n";
# my $tagsource = "";
# while(defined($texzeile = <MINTS>)) {
#   $texzeile =~ s/\\\%/XYZPERCTAG/g ; # LaTeX-Kommentare am Zeilenende entfernen, und Prozentzeichen löscht Zeilenumbruch
#   $texzeile =~ s/\%(.*)\n//g ; # LaTeX-Kommentare am Zeilenende entfernen, und Prozentzeichen löscht Zeilenumbruch
#   $texzeile =~ s/XYZPERCTAG/\%/g ;
#   $tagsource .= $texzeile;
# }
# close(MINTS);
# 
# # Parsen der Tags (sollte in textags.ini ebenso lauten):
# # Struktur eines tagmakros:
# # Parameter stehen in beiden Definitionen als #1,#2,... zur Verfügung,
# # PDF-Definition ist in LaTeX, HTML-Definition direkt als HTML mit direkter
# # Verwendung der Parameter (compile-evaluation).
# #
# #   {tagmacro:MAKRONAME}{AnzahlParameter}{DIRECTHTML=0,1}{PDFDEFINITION}{HTMLDEFINITION}
# 
# my @tagarray = $tagsource =~ /( \{ (?: [^{}]* | (?0) )* \} )/xg;
# $i = 0;
# while ($i <= $#tagarray) {
#   if ($tagarray[$i] =~ m/{tagmacro:(.+)}/s ) {
#     my $tmname = $1;
#     if (($i+4) > $#tagarray) { die("ERROR: textags.ini hat fehlerhaftes Format, nicht genug Angaben fuer Makro $tmname"); }
#     if ($i ge 1) { print(" "); }
#     print $tmname;
# 
#     my $tmpars = $tagarray[$i+1];
#     $tmpars =~ s/{(.+)}/$1/g ;
#     my $tmdirect = $tagarray[$i+2];
#     $tmdirect =~ s/{(.+)}/$1/g ;
#     my $tmpdf = $tagarray[$i+3];
#     my $tmhtml = $tagarray[$i+4];
#     $tmhtml =~ s/\{(.*)\}/$1/ ;
#     
#     
#     my $hparas = ";;$tmpars";
#     my $j = 1;
#     for ($j = 1; $j < ($tmpars+1); $j++) { $hparas .= ";;\}\#$j\\special\{html:"; }
#     
#     my $htmltag;
#     $tmhtml =~ s/\\\#/\#\_/g ;
#     if ($tmdirect ne 0) { $tmhtml =~ s/\#([0123456789]+)/\}\#$1\\special\{html:/g; }
#     $tmhtml =~ s/\#\_/\#/g ;
#     if ($tmdirect ne 0) { $tmhtml = "\\special\{html:$tmhtml\}"; }
#     
#     $htmltag = "\\newcommand\{$tmname\}[$tmpars]\{$tmhtml\}";
#     $IncludeTags .= "\\ifttm\n\\newcommand{$tmname}\[$tmpars\]$tmpdf\n\\else\n$htmltag\n\\fi\n";
#    
#     
#     $i += 5;
#   } else {
#     die("ERROR: textags.ini hat fehlerhaftes Format: " . $tagarray[$i] . "\n");
#   }
# }
# 
# print "\n";

# # Java-Kram (NICHT MEHR BENOETIGT)
# print "Erzeuge Java-Bytecode\n";
# system("javac *.java");
# system("cp *.class ../files/.");

print "Creating stylesheets\n";
chdir($config{output} . "/converter/precss");
system("php -n grundlagen.php >grundlagen.pcss");

# Ersetze Farben im Stylesheet mit den Vorgaben

my $cccs = open(CSS, "< grundlagen.pcss") or die "FATAL: Could not open pcss-file";
my $cccs2 = open(OCSS, "> grundlagen.css") or die "FATAL: Could not create css-file";
my @mycss = <CSS>;
close(CSS);

my $fcs = open(FARBEN, "< $colorfile") or die "FATAL: Could not open color file $colorfile in directory precss";
my @farben = <FARBEN>;
close(FARBEN);

my $row;
my $fz;
foreach $row (@mycss) {
  foreach $fz (@farben) {
    if (($fz =~ /=/ ) and (!($fz =~ /#/ )))
    {
      my $pre = "";
      my $post = "";
      ($pre,$post) = split(/=/,$fz);
      $pre =~ s/ //g;
      $post =~ s/ //g;
      $post =~ s/\n//g;
      $post = "\#" . $post;
      $row =~ s/\[-$pre-\]/$post/g ;
    }
  }
  print OCSS $row;
}
close(OCSS);

system("cp grundlagen.css ../files/css/.");

# mintmod.tex so veraendern, dass lokale Preamblen und Tagmakros eingebunden werden
chdir("../tex");
# MUSS APPEND SEIN
my $ipf = open(MINTP, ">> mintmod.tex") or die "FATAL: Could not append local preamles to mintmod.tex";
print MINTP "\n% ---------- Automatisch eingebundene Preamblen aus mconvert.pl heraus ---------------\n";
print "Included preambles:\n";
for ( $i=0; $i <= $#IncludeStorage; $i++ ) {
  print " module=$IncludeStorage[$i][0], filename=$IncludeStorage[$i][1]\n";
  print MINTP "% Automatische Einbindung der Preamble " . $IncludeStorage[$i][1] . ":\n";
  print MINTP $IncludeStorage[$i][2] . "\n";
}
# print MINTP "% Predefinierte Tagmakro --------- \n";
# print MINTP $IncludeTags . "\n";
close(MINTP);


# Erzeuge den HTML-Baum
chdir("../..");
$ndir = getcwd; # = $output in voller expansion
chdir("$ndir/converter");
print("Changing to directory $ndir/converter\n");
print("Starting conv.pl:\n");
my $rt1 = system("./conv.pl");
if ($rt1 != 0) { die("FATAL exit from conv.pl"); }
chdir("tex");
my $pdfok = 1;
if ($config{dopdf} eq 1) {
    # Ganzer Baum wird erstellt: Die Fachbereiche separat texen
    my $doct = "";
    for ( $i=0; ($i <= $#PDFDeclare) and ($pdfok == 1); $i++ ) {
      $doct = $PDFDeclare[$i][0];
      print "======= Generating PDF file $doct.tex ========================================\n";

      $rt1 = system("pdflatex $doct.tex");
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
  }
  if ($pdfok == 1) {
    print("======= PDF files build successfully =======================================\n");
  } else {
    print("======= PDF files have not been build =================================\n");
  }
}


print("Changing back to directory $ndir\n");
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
  print "MathJax 2.4 (full package) is added locally\n";
  #print "MathJax wird nicht lokal angelegt, sondern ueber Web bezogen\n";
  system("mkdir $ndir/MathJax");
  system("tar -xzf $ndir/converter/mathjax24complete.tgz --directory=$ndir/MathJax/.");
  #system("tar -xzf $ndir/converter/mathjax23reduced.tgz --directory=$ndir/MathJax/.");
  #print "Nutze reduzierte Version von MathJax ohne ImageFonts (benoetigt IE6+, Chrome, Safari 3.1+, Firefox 3.5+, oder Opera 10+)\n";
}

system("mv $ndir/converter/" . $config{outtmp} . "/* $ndir/.");
system("rmdir $ndir/converter/" . $config{outtmp});

if ($config{cleanup} == 0) {
  print "DEBUG converter-subdirectory is NOT removed\n";
} else {
  system("rm -fr $ndir/converter");
  print "converter-directory cleaned up\n";
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
        print "--- Starttag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $startfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalchaptertag -->/ ) {
        print "--- Chaptertag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $chapterfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalconftag -->/ ) {
        print "--- Configtag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $configfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobaldatatag -->/ ) {
        print "--- Datatag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $datafile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalfavotag -->/ ) {
        print "--- Favotag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $favofile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mgloballocationtag -->/ ) {
        print "--- Locationtag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $locationfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalsearchtag -->/ ) {
        print "--- Searchtag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $searchfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalstesttag -->/ ) {
        print "--- STesttag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $stestfile = "mpl/" . $2 . ".html";
      }
      if ($htmlzeile =~ m/<!-- mglobalbetatag -->/ ) {
        print "--- Betatag found in file $hfilename\n";
        $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
        $betafile = "mpl/" . $2 . ".html";
      }
    }
    close(MINTS);
}

if ($starts eq 0 ) {
  die("FATAL: Global start tag not found, HTML tree is disfunctional");
} else {
  if ($starts ne 1) {
    print "ERROR: Multiple start tags found, using last one\n";
  }
}

createRedirect("index.html", $startfile);
if ($chapterfile ne "") { createRedirect("chapters.html", $chapterfile); } else { print "No Chapter-file defined!\n"; }
if ($configfile ne "") { createRedirect("config.html", $configfile); } else { print "No Config-file defined!\n"; }
if ($datafile ne "") { createRedirect("cdata.html", $datafile); } else { print "Keine Data-Datei definiert!\n"; }
if ($searchfile ne "") { createRedirect("search.html", $searchfile); } else { print "Keine Search-Datei definiert!\n"; }
if ($favofile ne "") { createRedirect("favor.html", $favofile); } else { print "Keine Favoriten-Datei definiert!\n"; }
if ($locationfile ne "") { createRedirect("location.html", $locationfile); } else { print "Keine Location-Datei definiert!\n"; }
if ($stestfile ne "") { createRedirect("stest.html", $stestfile); } else { print "Keine Starttest-Datei definiert!\n"; }
if ($betafile ne "") { createRedirect("betasite.html", $betafile); } else { print "Keine Beta-Datei definiert!\n"; }

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
  print("\nHTML module " . ((($config{dopdf} eq 1) and ($pdfok eq 1)) ? " and PDF " : " ") . "have been created. Start file is $ndir/$startfile.\n\n");
} else {
  system("chmod -R 777 *");
  system("zip -r $zip *");
  system("cp $zip ../.");
  chdir("..");
  system("rm -fr $ndir");
  print("\nHTML module" . ((($config{dopdf} eq 1) and ($pdfok eq 1)) ? " and PDF " : " ") . "have been created and zipped to $zip. Start file in this zip tree is $startfile.\n\n");
}

print "mconvert.pl finished successfully\n\n";

exit;


