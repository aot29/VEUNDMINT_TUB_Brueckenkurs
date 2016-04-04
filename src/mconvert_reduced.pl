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
# 1 Info wird nach Aufgaben eingegliedert und aus der Vorwaerts-RÃ¼ckwÃ¤rtskonfig ausgeklammert
our $contentlevel = 4; # Level der subsubsections
our $XIDObj = -1;

our @LabelStorage; # Format jedes Eintrags: [ $lab, $sub, $sec, $ssec, $sssec, $anchor, $pl ]

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

our $paramsplitlevel = 3; # Maximales Level ab dem die Seiten getrennte HTML-Dateien sind

our $templatempl = ""; # wird von split::loadtemplates gefuellt

# our @feedbacktitles = ("Beschreibung/Aufgabenstellung ist unverständlich","Der Inhalt bzw. die Frage ist zu schwer","War genau richtig","Das ist mir zu leicht","Fehler in Modulelement melden");
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
      logMessage($FATALERROR, "perl version 5.10 is required, but found perl 5" . $1);
    }
  } else {
    logMessage($FATALERROR, "perl (at least version 5.10) is required");
  }

  # Pruefe ob ein JDK installiert ist
  $reply = `javac -version 2>&1`;
  if ($reply =~ m/javac (.+)/i ) {
    logMessage($CLIENTINFO, "JDK found, using javac from version $1");
  } else {
    logMessage($FATALERROR, "JDK not found");
  }
  
  # Pruefe ob php installiert ist
  $reply = `php --help 2>&1`;
  if ($reply =~ m/HTML/i ) {
    # php erfolgreich getestet
  } else {
    logMessage($FATALERROR, "PHP (version 5 and PHP-curl) not found\n");
  }

  # Pruefe ob pdf2svg installiert ist
  $reply = `pdf2svg`;
  if ($reply =~ m/Usage:/i ) {
    logMessage($CLIENTINFO, "pdf2svg found");
  } else {
    logMessage($FATALERROR, "pdf2svg not found");
  }

  # Pruefe ob inkscape installiert ist
  $reply = `inkscape --help`;
  if ($reply =~ m/--without-gui/i ) {
    logMessage($CLIENTINFO, "inkscape command line tool found");
  } else {
    logMessage($FATALERROR, "inkscape command line tool not found");
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

  if ($scormclear == 0) {
    writefile("$ndir/$filename", $indexhtml);
  } else {
    writefile("$ndir/$filename", $indexhtmlscorm);
  }
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


  logMessage($VERBOSEINFO, "Creating SCORM manifest: title=$manifest_title, version=$manifest_version, id=$manifest_id");
  
  # Erstelle Manifestdatei fuer SCORM
  writefile("./imsmanifest.xml", $manifest);
  logMessage($CLIENTINFO, "Creating HTML tree as a SCORM module version 2004v4");
}

# Checks if given parameter key is present and has a nonempty string as value
sub checkParameter {
  my $p = $_[0];
  if (exists $config{parameter}{$p}) {
    if ($config{parameter}{$p} eq "") {
      logMessage($FATALERROR, "Mandatory option parameter $p is an empty string");
    }
  } else {
    logMessage($FATALERROR, "Mandatory option parameter $p is missing");
  }
}

# Checks if options are present and consistent, quits with a fatal error otherwise
sub checkOptions {
  open(F, $config{source}) or logMessage($FATALERROR, "Cannot open source directory " . $config{source});
  close(F);

  if ($config{docollections} eq 1) {
    if (($config{nosols} eq 1) or ($config{qautoexport} eq 1) or ($config{cleanup} eq 1)) {
      logMessage($FATALERROR, "Option docollections is inconsistent with nosols, qautoexport and cleanup, deactivate one of them");
    }
  }

  if ($config{dorelease} eq 1) {
    if (($config{cleanup} eq 0) or ($config{docollections} eq 1) or ($config{doverbose} eq 1)) {
      logMessage($FATALERROR, "Option dorelease is inconsistent with cleanup=0, docollections=1 and doverbose=1, deactivate dorelease");
    }
  }

  if ($config{scormlogin} eq 1) {
    if ($config{doscorm} eq 0) {
      logMessage($FATALERROR, "Option scormlogin is inconsistent with doscorm=0, activate doscorm");
    }
  }

  $zip = ""; # Pfad+Name der zipdatei
  if ($config{dozip} eq 1) {
    if ($config{output} =~ m/(.+)\.zip/i) {
      $zip = $config{output}; # Wird in der Variant-Iteration durch xyz_var.zip ersetzt
      $config{output} = $1 . "DIRECTORY";
    } else {
      logMessage($FATALERROR, "zip-filename " . $config{output} . " not of type name.zip");
    }
  }
  
  # Check mandatory option parameters
  logMessage($CLIENTINFO, "Checking " . ($#mandatory+1) . " parameters ... ");
  my $a;
  for ($a = 0; $a <= $#mandatory; $a++) {
    checkParameter($mandatory[$a]);
  }
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

{
package Page;

# sub new()
# Konstruktor der Klasse
# Parameter

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
  for (my $j = 0; $j <= $self->{LEVEL}; $j++) {
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

  for (my $i = 0; $i < $k; $i++ ) {
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
	package ModulPage; # -> TContent
	use base 'Page';



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

# sub noregex()
# Kapselt alle Sonderzeichen in einem Matching-Pattern
# Parameter
#   $s          Der Matching-String
# Rueckgabe: Der String wobei allen Sonderzeichen ein backslash vorangestellt wurde
# Ausnahme: "*" um Dateisuche zu ermoeglichen

sub noregex {
  my $s = $_[0];
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

  
  if ($config{parameter}{stdmathfont} == "1") {
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
  }

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

  # SVGStyles einsetzen
  while ($text =~ m/<!-- svgstyle;(.+?) \/\/-->/s ) {
    my $tname = $1;
    if (exists $tikzpng{$tname}) {
      my $style = $tikzpng{$tname};
      logMessage($VERBOSEINFO, "Found style info for svg on $tname: $style");
      $text =~ s/<!-- svgstyle;$tname \/\/-->/$style/g ; 
      delete $tikzpng{$tname};
    } else {
      logMessage($CLIENTERROR, "Could not find image information for $tname");
      $text =~ s/<!-- svgstyle;$tname \/\/-->//g ; 
    }
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

  
  # DirectRoulette-divs einrichten
  while ($text =~ m/<!-- rouletteexc-start;(.+?);(.+?); \/\/-->(.+?)<!-- rouletteexc-stop;(.+?);(.+?); \/\/-->/s ) {
    my $rid = $1;
    my $id = $2;
    
    my $maxid = 0;
    
    if (exists $DirectRoulettes{$rid}) {
      $maxid = $DirectRoulettes{$rid};
    } else {
      logMessage($CLIENTERROR, "Could not find roulette id $rid");
    }
    my $vis = ($id eq "0") ? "block" : "none";
    
    my $bt = "<div class=\"rouletteselector\"><button type=\"button\" class=\"roulettebutton\" onclick=\"rouletteClick(\'$rid\',$id,$maxid);\">Neue Aufgabe</button><br />";
    
    $text =~ s/<!-- rouletteexc-start;$rid;$id; \/\/-->(.+?)<!-- rouletteexc-stop;$rid;$id; \/\/-->/<div style=\"display:$vis\" id=\"DROULETTE$rid\.$id\">$bt$1<\/div><\/div>/s ;
    logMessage($VERBOSEINFO, "Roulette $rid.$id done");
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



#------------------------------------------------ START NEUES DESIGN ---------------------------------------------------------------------------------------


# Erzeugt das head-div fuer die html-Seiten
sub getheader {
  # Inhalt wird von js-Funktionen dynamisch gefuellt
  return "<div class=\"headmiddle\">&nbsp;</div>\n"; # ohne echten div-Inhalt werden icons nicht erzeugt
}

# Erzeugt das footer-div fuer die html-Seiten
sub getfooter {
  # Inhalt von footer_left wird von js-Funktionen dynamisch gefuellt
  my $footer = "<div id=\"footerleft\"></div>" .
               "<div id=\"footerright\">" . $config{parameter}{footer_right} . "</div>" .
               "<div id=\"footermiddle\">" . $config{parameter}{footer_middle} . "</div>\n";
  return $footer;
}

# Erzeugt das settings-div fuer die html-Seiten
sub getsettings {
  my $settings = <<ENDE;
<p>
<center>
<b>Auswahl des Farbschemas für den Onlinekurs</b><br />
<ul style="width:75%;list-style-type:none;columns:4;-webkit-columns:4;-moz-columns:4">
<li style="padding:20px;background-color:rgba(41,100,255,1)"><center><button class="stdbutton" type="button" onclick="selectColor(STYLEBLUE);">Blaues Schema</button></center></li>
<li style="padding:20px;background-color:rgba(255,41,100,1)"><center><button class="stdbutton" type="button" onclick="selectColor(STYLERED);">Rotes Schema</button></center></li>
<li style="padding:20px;background-color:rgba(41,255,100,1)"><center><button class="stdbutton" type="button" onclick="selectColor(STYLEGREEN);">Grünes Schema</button></center></li>
<li style="padding:20px;background-color:rgba(100,100,100,1)"><center><button class="stdbutton" type="button" onclick="selectColor(STYLEGREY);">Graues Schema</button></center></li>
</ul>
</center>
</p>

<br /><br />

<p>
<center>Auswahl der mathematischen Notation</center><br />
<ul style="list-style-type:none">
  <li>
  <button type="button" class="stdbutton" onclick="selectVariant('std');">Diese Notation festlegen</button> &nbsp;
  <a href="https://de.wikipedia.org/wiki/DIN_1302">DIN 1302</a> (Schulbuchnotation)<br />
  \\(\\displaystyle
  ]a;b[\\ , \\ \\mathbb N =\\lbrace 1;2;3;\\ldots\\rbrace \\ , \\ P=(a;b;c)\\ ,\\ \\vec{x}= \\left(\\begin{array}{c} 1\\\\2  \\end{array}\\right) \\ ,\\ \\sqrt2 =1,414\\ldots
  \\)
  </li>
  <li>
  <button type="button" class="stdbutton" onclick="selectVariant('unotation');">Diese Notation festlegen</button> &nbsp;
  Alternative Notation, die in vielen technischen Studiengängen eingesetzt wird<br />
  \\(\\displaystyle
  (a,b)\\ , \\ \\mathbb N =\\lbrace 1,2,3,\\ldots\\rbrace \\ , \\ P=(a,b,c)\\ ,\\ \\vec{x}= \\left(\\begin{array}{c} 1\\\\2  \\end{array}\\right) \\ ,\\ \\sqrt2 =1.414\\ldots
  \\)
  </li>
</ul>
</p>
<p>
<br /><br />
<center>
<button type="button" class="stdbutton" onclick="toggle_settings();">Zurück zum Kurs</button>
</center>
</p>
ENDE
  
  return $settings;
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
# Parameter: Das Seitenobjekt
sub getnavi {
  my ($site) = @_;

  my $p;
  my $navi = "";
  $navi .= "<!--ZOOMSTOP-->\n";

  # Link auf die vorherige Seite
  $p = $site->navprev();
  my $ac = ""; # $config{strings}{button_previous} nicht mehr benoetigt im bdesign
  my $icon = "nprev";
  my $anchor;
  if (($site->{XCONTENT} == 1) and (!($p))) {
    if ($site->{XPREV} != -1) {
      $p = $site->{XPREV};
      # $icon = "xnprev";
    }
  }
  if (($p) and ($site->{LEVEL} == $contentlevel)) {
    $anchor = "<a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $p->link() . ".{EXT}\"></a>";
  } else {
    $anchor = "";
  }
  $navi .= "<div class=\"$icon\">" . $anchor . "</div>\n";

  # Link auf die naechste Seite
  $p = $site->navnext();
  $ac = ""; # $config{strings}{button_next}; nicht mehr benoetigt im bdesign
  $icon = "nnext";
  if (($site->{XCONTENT} == 1) and (!($p))) {
    if ($site->{XNEXT} != -1) {
      $p = $site->{XNEXT};
      # $icon = "xnnext";
    }
  }
  if (($site->{LEVEL} == ($contentlevel-2)) and ($site->{XNEXT} ne -1)) {
    # Von Modulhauptseite kommt man mit "Weiter" auf die erste contentseite
    $p = $site->{XNEXT};
    # $icon = "xnnext";
  }
  if (($site->{LEVEL} == ($contentlevel-3)) and ($site->{XNEXT} ne -1)) {
    # Von FB-Hauptseite kommt man mit "Weiter" auf die erste Modulhauptseite
    $p = $site->{XNEXT};
    # $icon = "xnnext";
  }

  if (($p) and (($site->{LEVEL}==$contentlevel) or ($site->{LEVEL}==($contentlevel-2)) or ($site->{LEVEL}==($contentlevel-3)))) {
    $anchor = "<a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $p->link() . ".{EXT}\"></a>";
  } else {
    $anchor = "";
  }
  $navi .= "<div class=\"$icon\">" . $anchor . "</div>\n";

  # Links auf die subsubsections im gleichen Teilbaum
  $navi .= "<ul>\n";

    if ($site->{LEVEL}!=$contentlevel) {
      if ($site->{XCONTENT}==3) {
        # Link auf Aufgabenstellung bei Loesungsseiten
	$navi .= "  <li class=\"xsectbutton\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $site->{BACK}->link() . ".{EXT}\">" . "Zum Modul" . "</a></li>\n";
	logMessage($FATALERROR," Backtracks from solution pages should no longer appear since MSolution is deprecated");
      } else {
        # Link auf Modulstart setzen bei hoeheren Ebenen
	my $pp = $site;
	if ($pp->{LEVEL}!=$contentlevel) {
	  my @sp = @{$pp->{SUBPAGES}};
	  $pp = $sp[0];
	}
	if ($pp->{HELPSITE} eq 0) {
	  $navi .= "  <li class=\"xsectbutton\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $pp->link() . ".{EXT}\">" . $config{strings}{module_starttext} . "</a></li>\n";
	} else {
	  $navi .= "  <li class=\"xsectbutton\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $pp->link() . ".{EXT}\">" . "Mehr Informationen" . "</a></li>\n";
	}
      }
    }

    my $parent;
    if ($parent = $site->{PARENT}) {
      my @pages = @{$parent->{SUBPAGES}};
      for (my $i = 0; $i <= $#pages; $i++ ) {
	my $p = $pages[$i];
	my $attr ="normal";
	if ($p->secpath() eq $site->secpath()) { $attr = "s"; }
	my $icon = $p->{ICON};
	if ($icon eq "STD") { $icon = "book"; }
	$icon = translateoldicons($icon);
	# bdesign: no images
	$icon = "xsectbutton";
	my $cap = $p->{CAPTION};
	if ($icon ne "NONE") {
	  #$icon = "button_" . $icon;
	  if (($p->{DISPLAY}) and ($site->{LEVEL}==$contentlevel)) {
	    # Knopf fuer Seite normal darstellen mit Attributen
	    $navi .= "  <li class=\"$icon\"><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p->link() . ".{EXT}\">" . $cap . "</a></li>\n";
	  } else {
	    if ($site->{LEVEL}!=$contentlevel) {
	      # Keine Navigationsbuttons wenn auf oberer Ebene
	    } else
	    {
	      # Knopf fuer gesperrte Seite ausgrauen und nicht verlinken
	      $attr = "g";
	      $navi .= "  <li class=\"$icon\">" . $cap . "</li>\n";
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
                  $tsec .= "<a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p4->link() . ".{EXT}\"><div class=\"xsymb " . $p4->{TOCSYMB} . "\"></div></a>\n";
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
		my $divsettings = updatelinks(getsettings(),$linkpath);
		# Kein update erforderlich da $p verwendet wird:
		my $divnavi = getnavi($p); 
		#my $divtoccaption = gettoccaption($p);
		my $divtoccaption = gettoccaption_menustyle($p);
		my $divcontent = getcontent($p);


		
		
		
		
		

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
		$text .= "<div id=\"fhead\" class=\"head\">\n"   . $divhead       . "</div>\n";
		$text .= "<div id=\"ftoc\" class=\"toc\">\n"    . $divtoccaption . "</div>\n";
		$text .= "<div id=\"fnavi\" class=\"navi\">\n"   . $divnavi       . "</div>\n";
		$text .= "<div id=\"footer\">\n"    . $divfooter     . "</div>\n";
		$text .= "<div id=\"settings\" style=\"visibility:hidden\">\n" . $divsettings . "</div>\n";
		$text .= "</div>\n";
		$text .= "<div id=\"notfixed\">\n";
		$text .= "<div id=\"nfhead\" class=\"head\">\n"   . $divhead       . "</div>\n";
		$text .= "<div id=\"nftoc\" class=\"toc\">\n"    . $divtoccaption . "</div>\n";
		$text .= "<div id=\"nfnavi\" class=\"navi\">\n"   . $divnavi       . "</div>\n";
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

  for (my $i = 0; $i <= $#subpages; $i++) {
    my $lk = $subpages[$i]->link() . ".{EXT}";
    $toc = $toc . "<a class=\"MINTERLINK\" href='" . $lk ."'>" . $subpages[$i]->{TITLE} . "</a><br />";
  }

  my $text = $p->{TEXT};
  if ($text =~ s/<!-- toc -->/$toc/g) { $p->{TEXT} = $text; }

  #Rekursion auf Unterseiten
  logMessage($VERBOSEINFO, "  Iteriere über " . $#subpages . " Unterseiten");
  for (my $i = 0; $i <= $#subpages; $i++) {
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
  for (my $i = 0; $i <= $#subpages; $i++ ) {
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
	
	# Korrektur eines Bugs in MathJax 2.6 (trat <=2.4 nicht auf): displaystyle=true wird nicht auf Tabellen vererbt, also auch innerhalb der Tabelle deklarieren
	$text =~ s/<mstyle displaystyle="true"><mrow>\n<mtable([^>]+)>/<mstyle displaystyle="true"><mrow>\n<mtable$1><mstyle displaystyle="true">/sg ;
	
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






# --------------------------------------------- Konvertierung des Dokuments zu XML ----------------------------------------------------------------------------------------------------------------------

# Parameter: output-directory
sub converter_conversion {




# PYTHON CONVERSION







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

my $confinfocontent = "";
$confinfocontent .= "// Automatically generated by mconvert.pl, will be included by the standard template\n";
$confinfocontent .= "var scormLogin = " . $config{scormlogin} . ";\n";
$confinfocontent .= "var isRelease = " . $config{dorelease} . ";\n";
$confinfocontent .= "var doCollections = " . $config{docollections} . ";\n";

if ($config{testonly} eq 1) {
  $confinfocontent .= "var testOnly = 1;\n";
  print "TESTONLY aktiviert!\n";
  # Deaktiviert Buttons
  $confsite = "";
  $datasite = "";
  $searchsite = "";
} else {
  $confinfocontent .= "var testOnly = 0;\n";
}

if ($config{dorelease} ne 1) {
  $confinfocontent .= "console.log(\"KEINE RELEASE-VERSION\");\n";
}
$confinfocontent .= "var isVerbose = " . $config{doverbose} . ";\n";
if ($config{doverbose} eq 1) {
  $confinfocontent .= "console.log(\"VERBOSE-VERSION\");\n";
}

# Freie Parameter aus config eintragen
my $ckey;
my $cval;
while (($ckey, $cval) = each(%{$config{'parameter'}})) {
  $confinfocontent .= "var $ckey = \"$cval\";\n";
}

$confinfocontent .= "var globalsitepoints = [];\n";
$confinfocontent .= "var globalexpoints = [];\n";
$confinfocontent .= "var globaltestpoints = [];\n";
$confinfocontent .= "var globalsections = [];\n";
for (my $i = 0; $i <= $#expoints; $i++) {
  $confinfocontent .= "globalsitepoints[$i] = " . $sitepoints[$i] . ";\n";
  $confinfocontent .= "globalexpoints[$i] = " . $expoints[$i] . ";\n";
  $confinfocontent .= "globaltestpoints[$i] = " . $testpoints[$i] . ";\n";
  $confinfocontent .= "globalsections[$i] = \"" . $sections[$i] . "\";\n";
}

writefile($config{outtmp} . "/convinfo.js" , $confinfocontent);

if ($config{parameter}{do_export} eq "1") { logMessage($CLIENTINFO,  "EXPORTVERSION WILL BE GENERATED");  }
if ($config{parameter}{do_feedback} eq "1") { logMessage($CLIENTINFO, "FEEDBACKVERSION WILL BE GENERATED");  }

my @umwordindexlist = ();
my @wordindexlist = ();
my @wordindexlinklist = ();
my $icount = 0;
my $li = "ELI_SW";
while ($text =~ s/<!-- mpreindexentry;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?); \/\/-->/<!-- mindexentry;;$1; \/\/--><a class=\"label\" name=\"$li$icount\"><\/a><!-- mmlabel;;$li$icount;;$2;;$3;;$4;;$5;;13; \/\/-->/s ) {
  my $umstr = $1;
  push @wordindexlist, $1;
  push @wordindexlinklist, "$li$icount";
  $umstr =~ s/ä/ae/g ;
  $umstr =~ s/ö/oe/g ;
  $umstr =~ s/ü/ue/g ;
  $umstr =~ s/Ä/Ae/g ;
  $umstr =~ s/Ö/Oe/g ;
  $umstr =~ s/Ü/Ue/g ;
  $umstr =~ s/ß/ss/g ;
  push @umwordindexlist, $umstr;
  $icount++;
}

# Sortieren mit IdiotSort FUNKTIONIERT NICHT MIT UMLAUTEN
my $swap = 1;
logMessage($VERBOSEINFO, "Sortiere " . ($#wordindexlist-1) . " Stichwoerter"); 
while ($swap==1) {
  $swap = 0;
  for (my $i = 0; $i <= $#wordindexlist; $i++ ) {
    for (my $j = $i + 1; $j <= $#wordindexlist; $j++ ) {
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
    for (my $i = 0; $i <= $#subpages; $i++) {
      push @list, $subpages[$i];
    }
  }
 
  writefile("graph.png", $graph->as_png());
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
  if ($mconfigfile =~ m/(.+)\.pl/ ) {
    if ($mconfigfile =~ m/\// ) { logMessage($FATALERROR, "Configuration file must be in calling directory"); }
    
    if (-e $mconfigfile) {
      logMessage($CLIENTINFO, "Configuration file: " . $mconfigfile);
      unless (%config = do $mconfigfile) {
        warn "Couldn't parse $mconfigfile: $@" if $@;
        warn "Couldn't run $mconfigfile" unless %config;
      }
    } else {
      logMessage($FATALERROR, "Configuration file $mconfigfile does not exist");
    }
  } else {
    logMessage($FATALERROR, "Configuration file $mconfigfile must be of type name.pl");
  }
  $configactive = 1;  
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

# Parameter: Variant id string, main tex file
sub create_tree {



  # PYTHON CONVERSION
  
  
  

  logMessage($VERBOSEINFO, "Creating stylesheets");
  chdir($outputdir . "/converter/precss");
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
  
  print JCSS " + \"\";";
    
  close(OCSS);
  close(JCSS);

  system("cp grundlagen.css ../files/css/.");
  system("cp dynamiccss.js ../files/.");

  chdir("../tex");

  # print MINTP "% Automatisierte Tagmakros ---------- \n";
  # print MINTP "\\ifttm\n";
  # print MINTP "\\else\n";
  # print MINTP "\\fi\n";
 
  my $mint_tex = $modmacrotex;
  my $mint_html = $modmacrotex;

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
  converter_conversion($outputdir);

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
    logMessage($CLIENTINFO, "MathJax 2.6 (full package) is added locally");
    system("mkdir $ndir/MathJax");
    system("tar -xzf $ndir/converter/mathjax26complete.tgz --directory=$ndir/MathJax/.");
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

  my $npng = keys %tikzpng;
  if ($npng ge 1) {
    logMessage($CLIENTERROR, "$npng tikz externalized files have not been used in svg style infos");
    my $tname;
    foreach $tname (keys %tikzpng) {
      logMessage($VERBOSEINFO, "  $tname");
    }
  }

  if ($starts eq 0 ) {
    logMessage($FATALERROR, "Global start tag not found, HTML tree is disfunctional");
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
    chdir("..");
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
  
  logTimestamp("Finishing create_tree on variant $variantactive in directory " . getcwd);
}


# ----------------------------- Start Hauptprogramm --------------------------------------------------------------

# my $IncludeTags = ""; # Sammelt die Makros fuer predefinierte Tagmakros, diese werden an mintmod.tex angehaengt

# Logfile als erstes einrichten, auf der Ebene des Aufrufs
open(LOGFILE, "> $mainlogfile") or die("ERROR: Cannot open log file, aborting!");


#Zeit speichern und Startzeit anzeigen
$starttime = time;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
logMessage($CLIENTINFO, "Starting conversion: " . ($year+1900 ) . "-" . ($mon+1) . "-$mday at $hour:$min:$sec");

logMessage($CLIENTINFO, "Using encoding $stdencoding for read/write operations");

if ($#ARGV eq 0) {
  # Nur ein Parameter: Gibt Konfigurationsdatei relativ zum Aufruf an
  setup_options($ARGV[0]);
} else {
  if ($#ARGV ge 1) {
    # Ein oder mehr Parameter: Konfiguationsdatei plus Kommandos der Form option=wert
    setup_options($ARGV[0]);
    for (my $i = 1; $i <= $#ARGV; $i++) {
    
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
    logMessage($FATALERROR, $helptext);
  }
}

checkSystem();

$basis = Cwd::cwd(); 

checkOptions();

$rfilename = $config{source} . "/" . $config{module}; # sollte durch PERL-Join ersetzt werden

logMessage($VERBOSEINFO, " Absolute directory: " . $basis);
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

$variantactive = $config{variant};

logTimestamp("Finished initializiation");
create_tree($rfilename);
logTimestamp("mconvert.pl finished successfully");


close(LOGFILE);

exit;
