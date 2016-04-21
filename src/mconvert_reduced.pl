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


# --------------------------------- Parameter zur Erstellung des Modulpakets ----------------------------------


# Mandatory option parameter in config file
our @mandatory = ("signature_main", "signature_version", "signature_localization",
   "reply_mail", "data_server", "exercise_server", "feedback_service", "data_server_description", "data_server_user",
   "footer_middle", "footer_right", "mainlogo", "do_feedback", "do_export", "stdmathfont");

our $rfilename = "";         # Filename of main tex file including path relative to execution directory
our $zip = "";               # Filename of zip file (if neccessary)


# stellt das Verhalten des Menues im Header ein
# 0 bedeutet, dass Info die erste Seite eines Moduls ist
# 1 Info wird nach Aufgaben eingegliedert und aus der Vorwaerts-Rückwärtskonfig ausgeklammert
our $XIDObj = -1;

# our @LabelStorage; # Format jedes Eintrags: [ $lab, $sub, $sec, $ssec, $sssec, $anchor, $pl ]

our $PageIDCounter = 1;


# -------------------------------------------------------------------------------------------------------------

my @tominify = ("mintscripts.js", "servicescripts.js", "intersite.js", "convinfo.js", "userdata.js", "mparser.js", "dlog.js", "exercises.js");

# -------------------------------------------------------------------------------------------------------------

our $macrotex = ""; # Wird vor dem Aufruf von ttm mit dem Original-Inhalt der Makrodatei gefuellt
our $modmacrotex = "";
our $variantactive; # Bestimmt Variante der Kursumsetzung

our $starttime; # Timestamp beim Start des Programms

my $breakoff = 0;
my $ndir = ""; # wird am Programmstart gefuellt

my $copyrightcollection = "";

my $globalexstring = "";

#our $entryfile = ""; # Die erste und nur einmal pro Session aktivierte Datei, startet in der Regel $startfile

# Redirects passend zu den Buttons
#our $startfile = ""; # Wird vor Aufruf der Funktion createSCORM gesetzt durch StartTag, entryfile ebenso
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

our $paramsplitlevel = 3; # Maximales Level ab dem die Seiten getrennte HTML-Dateien sind

our $templatempl = ""; # wird von split::loadtemplates gefuellt

# our @feedbacktitles = ("Beschreibung/Aufgabenstellung ist unverst�ndlich","Der Inhalt bzw. die Frage ist zu schwer","War genau richtig","Das ist mir zu leicht","Fehler in Modulelement melden");
our @colexports = (); # Wird vom postprocessing in split.pm gefuellt

our @converrors = (); # Array aus Strings

our $mainsiteline = 0;

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
  
  for (my $i = 0; $i < $n; $i++) {
    $t .= substr($str,($u*$i) % $n,1);
  }
 
  return $t;
}


# Parameter: Ziellaenge und zu borkifizierender String
sub borkString {
  my $lan = $_[0];
  my $str = $_[1];
  
  my $t = "";
  
  for (my $i = 0; $i < $lan; $i++) {
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
    $borkhtml = readfile($borkfilename);
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
    for (my $i = 0; $i <= $#st; $i++) {
      my $b = borkString($lan, $st[$i][1]);
      $GSLS .= "if(c==" . $st[$i][0] . "){str=debork(\"$b\"," . $st[$i][2]. ");}";
    }
    
    $GSLS .= "return str;\}\n";
    $borkhtml =~ s/__CQJ/\n$GSLS\n__CQJ/s ;
    
    writefile($borktexs[$borkka], $borkhtml);
  }
  
  logMessage($VERBOSEINFO, "  $fdi Dateien borkifiziert");

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


  logMessage($VERBOSEINFO, "Creating SCORM manifest: title=$manifest_title, version=$manifest_version, id=$manifest_id");
  
  # Erstelle Manifestdatei fuer SCORM
  writefile("./imsmanifest.xml", $manifest);
  logMessage($CLIENTINFO, "Creating HTML tree as a SCORM module version 2004v4");
}





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



# Aufrufreihenfolge: JSCRIPTPOSTMODUL, globalreadyHandler, globalloadHandler


# -------------------------------------- subs --------------------------------------------------------------------------------

# --------------------------------------------- Objektdefinitionen ---------------------------------------------------------------------------------------------------------------------


# Parameter: $id, die eindeutige Collection-ID, $opt:   Die Optionen fuer die Collection
sub generatecollectionmark {
  my $id = $_[0];
  my $opt = $_[1];
 
  my $s = "<!-- collectionplaceholder: $id, $opt //-->";
  return $s;
}



#------------------------------------------------ START NEUES DESIGN ---------------------------------------------------------------------------------------




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


# =====================
# = Objekte schreiben =
# =====================
# 


# --------------------------------------------- Konvertierung des Dokuments zu XML ----------------------------------------------------------------------------------------------------------------------

# Parameter: output-directory
sub converter_conversion {




# PYTHON CONVERSION


   


# collection-Exportdatei schreiben
if ($config{docollections} eq 1) {
  logMessage($VERBOSEINFO, "Exportfile for contained collections is generated:");
  my $nco = $#colexports + 1;
  if ($nco le 0) {
    logMessage($VERBOSEINFO, "  No exports found!");
  } else {
    logMessage($VERBOSEINFO, "Exporting $nco collections");
    my $colexpcontent = "";
    $colexpcontent .= "{ \"comment\": \"Automatisch generierte JSON-Datei basierend auf Kurs-ID " . $config{parameter}{signature_CID} . "\",\n \"collections\": [";
    for (my $k = 0; $k <= $#colexports; $k++) {
    $colexpcontent .= "  ";
      if ($k ge 1) { print MINTS ","; }
      $colexpcontent .= "{ \"id\": \"" . $colexports[$k][0] . "\", \"exercises\": " . $colexports[$k][2] . "}";
    }
    $colexpcontent .= "]}\n";
    writefile("collectionexport.json", $colexpcontent);
  }
}


logTimestamp("Finished computation");

}

