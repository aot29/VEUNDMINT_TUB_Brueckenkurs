#!/usr/bin/env perl

#  Daniel Haase, 2014
#  daniel.haase@kit.edu

our $version = "Version 3.0";
our $dokversion = "M3.0";

# Diese Einstellungen haben keine Auswirkungen auf die produzierten Module, daher nicht in Parameterdatei
our $logfile = "./conv.log";
our $xmlfile = "converted.xml";

# =======================
# = Parameter festlegen =
# =======================

use File::Path;
use File::Data;
use Page;
use split;
use File::Copy;
use File::Slurp;
use POSIX qw(strftime);
use Net::Domain qw (hostname hostfqdn hostdomain);

our %config = ();
unless (%config = do 'config.pl') {
  warn "Couldn't parse config.pl: $@" if $@;
  warn "Couldn't run config.pl" unless %config;
}

# Diese Einstellungen muessen mit denen in mconvert.pl uebereinstimmen !
our $doconctitles = 1; # =1 -> Titel der Vaterseiten werden mit denen der Unterseiten auf den Unterseiten kombiniert [war bei alten Onlinemodulen der Fall macht aber eigentlich keinen Sinn]

# Diese sind mittlerweile in intersite.js fest verdrahtet!
our $confsite = "config.html";
our $datasite = "cdata.html";
our $searchsite = "search.html";
our $chaptersite = "chapters.html";
our $startsite = "index.html";
our $favorsite = ""; # "favor.html";
our $stestsite = "stest.html";
our $betasite = "betasite.html";

our $locationsite = ""; # Wird aus Dokument geholt
our $locationlong = ""; # Wird aus Dokument geholt
our $locationshort = "";# Wird aus Dokument geholt
our $locationicon = "";# Wird aus Dokument geholt

our $paramsplitlevel = 3;

our $templatempl = ""; # wird von split::loadtemplates gefuellt

# our @feedbacktitles = ("Beschreibung/Aufgabenstellung ist unverständlich","Der Inhalt bzw. die Frage ist zu schwer","War genau richtig","Das ist mir zu leicht","Fehler in Modulelement melden");

our @DirectHTML = (); # Wird als separate Datei von mconvert.pl erzeugt
our @sitepoints = ();
our @expoints = ();
our @testpoints = ();
our @sections = ();
our @uxids = ();
our @siteuxids = ();
our @colexports = (); # Wird vom postprocessing in split.pm gefuellt

our @converrors = (); # Array aus Strings

our $isBeta = 1; # = 0 -> release, wird auf 0 gesetzt wenn kein globalbetatag im xml

our $mainsiteline = 0;


# <script src="ace/ace.js" type="text/javascript" charset="utf-8"></script>
# <script src="src/theme-eclipse.js" type="text/javascript" charset="utf-8"></script>
# <script src="src/mode-java.js" type="text/javascript" charset="utf-8"></script>

#<script src="jquery-1.3.2.min.js" type="text/javascript"></script>
#<script src="jquery.qtip-1.0.0-rc3.min.js" type="text/javascript"></script>

sub generate_scriptheaders {
   my @c = split(/ /,$main::config{scriptheaders});
   my $itags = "";
   print "Using headers: ";
   foreach $cs (@c) {
     $itags = $itags . "<script src=\"$cs\" type=\"text/javascript\"></script>\n";
     print "$cs "; 
   }
   print "\n";
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




# stellt das Verhalten des Menues im Header ein
# 0 bedeutet, dass Info die erste Seite eines Moduls ist
# 1 Info wird nach Aufgaben eingegliedert und aus der Vorwaerts-RÃ¼ckwÃ¤rtskonfig ausgeklammert
our $newBehavior = 1;
our $contentlevel = 4; # Level der subsubsections
our $PageIDCounter = 1;
our $XIDObj = -1;

our @LabelStorage; # Format jedes Eintrags: [ $lab, $sub, $sec, $ssec, $sssec, $anchor, $pl ]

# =======================
# = Spracheinstellungen =
# =======================

# -------------------------------------- subs --------------------------------------------------------------------------------

sub main::VERSION_MESSAGE {
    print "conv.pl $version\n";
}

sub main::HELP_MESSAGE {
    print "Usage: conv.pl [-nopdf]\n";
    print "Die Hauptdatei ist stets vorkursxml.tex\n";
    print "Flags:\n";
    print "  -nopdf Deaktiviert die Verlinkung von PDF-Dokumenten.\n\n";
}

sub verarbeitung {
	my ($root) = @_;

	# interaktive Aufgaben einsetzen
	aufgabenersetzen($root);

	# Auf Unterabschnitte verlinken
	hidepageswotext($root);

	# MathML Optimierungen
	logtext("\nMathML Optimierungen");
	mathmloptimize($root);
	logtext("Vorkurs Optimierungen");

	# Vorhandene Links mit ../ versehen
	linkupdate($root, "../");


	# Die folgenden Manipulationen muessen nach linkupdate
	# passieren, da dort Links auf Seiten innerhalb der
	# Seitenstruktur erstellt werden

	# Loesungseiten erstellen
	aufgabenloesungen($root);

        # tocs erzeugen (vor createlinks, weil dort die links im toc gesetzt werden)
        createtocs($root);

	# Links und Anker setzen
	createlinks($root);

        # Spezialbehandlung fuer die Hilfesektion
        relocatehelpsection($root,0);
}


# Funktionen fuer interaktive Aufgaben
# ====================================

#
# sub aufgabenersetzen()
# Die interaktiven Teile der Aufgaben werden in eigenen .html-Dateien definiert.
# Diese Dateien sind im Unterordner aufgabenentwurf / exercisedraft gespeichert.
#
# Durch die Definitionen im tex-Header werden Html-Kommentare der Form
# <!-- Include dateiname -->
# eingefuegt. Diese werden nun durch den Inhalt der Aufgaben-Dateien ersetzt.
#
# Parameter
#	$p			Objekt einer Seite
sub aufgabenersetzen {
	my($p) = @_;
	my (@subpages, $i);
	my ($text, $count, $replace);

	#lade Text
	$text = $p->{TEXT};
	if ($text ne "") {
		#suche nach den html-Kommentaren fuer interaktive Aufgaben
		#und ersetze diese
		$count=0;
		while ($text =~ /<!-- Include (.*?) -->/) {
			if (-e $1) {
				$replace = loadfile($1);
				$text =~ s/<!-- Include (.*?) -->/$replace/;
				$count++;
			} else {
				$p->logtext("Datei $1 existiert nicht.");
				$text =~ s/<!-- Include (.*?) -->//;
			}
		}
		#Text speichern
		$p->{TEXT} = $text;
		if ($count>0) {
			$p->logtext("$count interaktive Aufgaben eingefuegt");
		}
	}
	#Rekursion auf Unterseiten
	@subpages = @{$p->{SUBPAGES}};
	for ( $i=0; $i <=$#subpages; $i++ ) {
		aufgabenersetzen($subpages[$i]);
	}
}


#
# sub aufgabenloesungen()
# Erstellt aus den Aufgabenloesungen, die durch bestimmte Tags markiert werden
# Unterseiten vom Typ SolutionPage und ersetzt den Bereich durch einen Link.
#
# Loesungen sind nur bei Seiten erlaubt, die selber keine Unterseiten haben.
# Dies liegt daran, dass die Loesungen selbst auch als Unterseiten realisiert werden
# und es sonst Probleme bei der vor/zurueck-Navigation gibt.
#
# Parameter
#	$p			Objekt einer Seite
sub aufgabenloesungen {
	my($p) = @_;
	my(@subpages, $i);
	my($text, $count, $lsg);

	#Unterseiten erst holen, da noch zusaetzliche Unterseiten
	#erstellt werden
	@subpages = @{$p->{SUBPAGES}};

	if ($#subpages < 0) {
		#lade Text
		$text = $p->{TEXT};
		if ($text ne "") {
			$count=0;
			$text =~ /<div class="(aufgabe|aufgaberahmen)">(\n)?<b>((.|\n)*?)<\/b>/;
			$aufgabentitle=$3;
			$hilf = $';
			if ($hilf =~ /<div class="(aufgabe|aufgaberahmen)">(\n)?<b>((.|\n)*?)<\/b>/) {
				$alte_aufgabe=$`;
			} else {
				$alte_aufgabe=$hilf;
			}
			
			# Normale Seite: Musterloesungen extrahieren, Testseite: Musterlösungen löschen
			if ($p->{TESTSITE} eq 1) {
			  $text =~ s/<!-- loesung -->(.*?)<!-- endloesung -->//sg ;
			}
			
			#suche nach den html-Kommentaren fuer Loesungen
			while ($text =~ /<!-- loesung -->((.|\n)*?)<!-- endloesung -->/) {
				$count++;
				#erstelle Loesung-Seite
				$lsg = SolutionPage->new($p->{LOGFILE});
				$lsg->{TITLE}=$p->{TITLE} . " - L&#246;sung zu " . $aufgabentitle;
				#erzeuge Link
				$linkname = $p->secpath() . "-ex$count";
				#speichere Text der Loesungsseite mit Link zur Aufgabe
				$linkback = "<p><a class=\"MINTERLINK\" href=\"#$linkname\">" . $config{strings}{module_solutionback} . "</a></p>";
				$lsg->{TEXT} = "<h2>" . $config{strings}{module_solution} . "</h2>\n$linkback$1$linkback";
				$lsg->{POS} = $count;
				$link = $p->{LINK} . "_$count";
				$lsg->{LINK} = $link;

				#Seite anhaengen
				$p->addpage($lsg);
				$lsg->{XCONTENT} = 3;
				$lsg->{BACK} = $p;

				#Loesung entfernen und durch Link auf Loesungs-Seite ersetzen
				$link = $p->linkpath() . $link;
                $text =~ s/<!-- loesung -->(.|\n)*?<!-- endloesung -->/<a class="MINTERLINK" name="$linkname"><\/a><a href="$link.{EXT}">" . $config{strings}{module_solutionlink} . "<\/a>/;
				$alte_aufgabe =~ s/<!-- loesung -->(.|\n)*?<!-- endloesung -->/<a class="MINTERLINK" name="$linkname"><\/a><a class="MINTERLINK" href="$link.{EXT}">" . $config{strings}{module_solutionlink} . "<\/a>/;

				if ($alte_aufgabe !~ /<!-- loesung -->(.|\n)*?<!-- endloesung -->/) {
					$text =~ s/<div class="(aufgabe|aufgaberahmen)">(\n)?<b>/<div class="$1 n"><b>/;
					$text =~ /<div class="(aufgabe|aufgaberahmen)">(\n)?<b>((.|\n)*?)<\/b>/;
					$aufgabentitle=$3;
					$hilf=$';
                    if ($hilf =~ /<div class="(aufgabe|aufgaberahmen)">(\n)?<b>((.|\n)*?)<\/b>/) {
						$alte_aufgabe=$`;
					} else {
						$alte_aufgabe=$hilf;
					}
				}
			}
            $text =~ s/<div class="aufgaberahmen n">/<div class="aufgaberahmen">/g;
            $text =~ s/<div class="aufgabe n">/<div class="aufgabe">/g;
			$text =~ s/<div class="fehler n">/<div class="fehler">/g;
			$p->{TEXT} = $text;
			if ($count >0) {
				$p->logtext("$count Loesungen extrahiert");
			}
		}
	} else {
		#Rekursion auf Unterseiten
		for ( $i=0; $i <=$#subpages; $i++ ) {
			aufgabenloesungen($subpages[$i]);
		}
	}

}


# --------------------------------------------- Objektdefinitionen ---------------------------------------------------------------------------------------------------------------------

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
# Die Funktion gettext wird fuer die Startseiten ueberschrieben, um die Modul-Start-Navigation
# zu erstellen

# Die Parameter stimmen mit denen im Page-Objekt ueberein und werden hier nicht
# nochmal kommentiert
{
	package ModulPage;
	use base 'Page';

	# sub new()
	# Konstruktor
	sub new {
		my ($package, $logfile) = @_;
		my $self = Page->new($logfile);
		# ISMODUL gibt an, ob dies ein Modul ist
		# diese Eigenschaft wird durch die split Funktion gesetzt
		$self->{ISMODUL} = 0;
		$self->{SWITCHDE} = "";
		$self->{SWITCHEN} = "";
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
			$lastobj = $self->SUPER::split(@args);
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

      # print "DEBUGTEXT:\n\n$text\n\n";

			if ($text =~ /$searchstring/) {
				$self->logtext("Modulunterteilung");
				# Modulunterteilung starten
				#print "split " . $self->{NR} . " in Modulteile\n";
				$self->{ISMODUL} = 1;
				$self->{DISPLAY} = 0;
				$self->{TEXT} = "";


                                # Labels in den ersten folgenden xcontent verschieben
                                my $sslabels = "";
                                if ($self->{LEVEL} eq 3) {
                                  # print "SUBSECTION mit Inhalt \n$text\n\n";

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

                                # if ($sslabels ne "") { print "DEBUG: SSLABELS =  $sslabels\n"; }

                                # print "TEXT: \n$text\n\n";

                                # Die xcontent-Abschnitte werden iteriert und in die Navigationsschleife eingehÃ¤ngt
                     	        my $mp1, $mp2, $mp3;
                                while ($text =~ /<!-- xcontent;-;$i;-;(.*);-;(.*);-;(.*) \/\/-->/) {
                            	    $mp1 = $1; $mp2 = $2; $mp3 = $3;
				    $markera = "<!-- xcontent;-;$i;-;$1;-;$2;-;$3 \/\/-->";
				    $markerb = "<!-- endxcontent;;$i \/\/-->";
				    $tpa = index($text,$markera);
				    $tpb = index($text,$markerb);

				    if (($tpa ne -1) and ($tpb ne -1)) {

				    $tpcontent = substr($text,$tpa+length($markera),($tpb - $tpa) - length($markera));

                                    my $p;

                                    $p = ModulPage->new($self->{LOGFILE});
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
					print "ERROR: Zaehlerueberlauf testpage=$testpage\n";
                                      }
                                      
                                      $p->{TESTSITE} = $5;
                                      
                                      if ($i eq 0) {
                                        $p->{PARENT}->{NR} = "$sec.$ssec";
                                        $p->{PARENT}->{PARENT}->{NR} = "$sec";
                                      }

				      # print "DEBUG: xcontent \"$p->{TITLE}\" hat Nummern $sec.$ssec.$sssec\n";
				      # <title> der HTML-Seite erweitern

				      $p->{TITLE} = $config{moduleprefix} . " Abschnitt $sec.$ssec.$sssec " . $p->{TITLE};
				      # Fehler im ttm korrigieren: subsubsection-Titel werden ohne Nummernprefix ausgegeben
				      # {XONTENTPREFIX} wird in split.pm (sub printpages) durch die captions der vorgaenger ersetzt, diese
                                      # sind zum jetzigen Zeitpunkt noch nicht gesetzt
                                      my $pref = "";
                                      if ($printnr == 1) { $pref = "$sec.$ssec.$sssec "; }
				      if ($tpcontent =~ s/<h4>(.*?)<\/h4><!-- sectioninfo;;$sec;;$ssec;;$sssec;;$printnr;;$testpage; \/\/-->/<h4>{XCONTENTPREFIX}<\/h4><br \/><h4>$pref$1<\/h4>/ ) {
				      } else {
					print "ERROR: Konnte in xcontent \"$p->{TITLE}\" nicht replacen\n";
				      }
				      
				    } else {
				      print "ERROR: Konnte Sectionnumbers nicht extrahieren in xcontent: $p->{TITLE}\n";
				    }

                                    # MSubsubsections im MXContent mit Nummern versehen
                                    $tpcontent =~ s/<h4>(.+?)<\/h4><!-- sectioninfo;;(\w+?);;(\w+?);;(\w+?);;1;;([01]); \/\/-->/<h4>$2.$3.$4 $1<\/h4>/g ;


                                    # print "XContent $i: $1 ($2), id = $p->{MODULID}, Laenge ist " . ($tpb-$tpa) . ", sslabels = $sslabels\n";

                                    $p->{TEXT} = $sslabels . "\n" . $tpcontent;
                                    $sslabels = "";

                                    $p->{NEXT} = 0;

                                    $pos = $pos + 1;
                                    $lastpage = $p;

				    } else {
                                      print "ERROR: Found xcontent $i but could not process it: \$1=$mp1, \$2=$mp2, \$3=$mp3";
                                      if ($tpa ne -1) {
                                        print " (eof problem, ttm stopped processing here)\n";
                                      } else {
                                        print "\nFile content:\n$text\n";
                                      }
				    }

                                    $i = $i + 1;

                                }

                                # Die scontent-Abschnitte werden iteriert aber nicht in die Navigationsschleife eingehÃ¤ngt
                                $i = 0;
                                while ($text =~ /<!-- scontent;-;$i;-;(.*);-;(.*);-;(.*) \/\/-->/) {
                            	    $mp1 = $1; $mp2 = $2; $mp3 = $3;
				    $markera = "<!-- scontent;-;$i;-;$1;-;$2;-;$3 \/\/-->";
				    $markerb = "<!-- endscontent;;$i \/\/-->";
				    $tpa = index($text,$markera);
				    $tpb = index($text,$markerb);

				    if (($tpa ne -1) and ($tpb ne -1)) {

				    $tpcontent = substr($text,$tpa+length($markera),($tpb - $tpa) - length($markera));
                                    my $p;

                                    $p = ModulPage->new($self->{LOGFILE});
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


                                    # print "SContent $i: $1 ($2), id = $p->{MODULID}, Laenge ist " . ($tpb-$tpa) . "\n";

                                    $pos = $pos + 1;

				    } else {
                                      print "ERROR: Found scontent $i but could not process it: \$1=$mp1, \$2=$mp2, \$3=$mp3";
                                      if ($tpa ne -1) {
                                        print " (eof problem, ttm stopped processing here)\n";
                                      } else {
                                        print "\nFile content:\n$text\n";
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
				#print "Modultyp der Seite " . $subpages[$i]->secpath() . " auf Modul setzen\n";
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

	# sub fullmenu()
	# Verhalten wie Page-Klasse
	sub fullmenu {
		my ($self, @args) = @_;
		return $self->SUPER::fullmenu(@args);
	}

	# sub menu()
	# Falls der Level=3 ist, wird einfach der Menu-Eintrag gezeichnet. Dabei
	# ist es egal ob es weitere Unterseiten gibt, diese werden nicht beachtet.
	# Ansonsten Verhalten wie Page-Klasse
	sub menu {
		my ($self, $curpage, $menuauswahllevel) = @_ ;
		my $level = $self->{LEVEL};
		my $secpath = $curpage->secpath();
		#print "menu " . $curpage->secpath() . " Elem " . $self->secpath();
		my @secpath = split(/\./, $secpath);
		pop @secpath;
		$secpath = join('.', @secpath);
		#print " vergleiche $secpath\n";

		if ($self->{ISMODUL} && $secpath eq $self->secpath() && $#subpages < 0) {
		  # DH 2011: Alle EintrÃ¤ge anklickbar, auch wenn Sie auf die gerade aktive Seite zeigen
		  my $linktext = "<li class='level$level" . "selected" . "'><a href='";
		  $linktext .= $curpage->linkpath() . $self->link() . ".{EXT}' class=\"MINTERLINK\">" . $self->{TITLE} . "</a></li>\n";
		  return $linktext;
		  #return "<li class='level" . $level ."selected'>" . $self->{TITLE} . "</li>\n";
		} else {
			return $self->SUPER::menu($curpage, $menuauswahllevel);
		}

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

	# sub gettext()
	# Bei Modulstartseiten wird die Modulnavigation angehaengt.
	# Verhalten wie Page-Klasse bei allen anderen Seiten.
	sub gettext {
		my ($self, @args) = @_;
		my ($link, $text, $p);

 		if ($self->{ISMODUL} && $self->{MODULID} eq "start") {
			$text = $self->{TEXT} . "\n" . $text . "\n";
			return $text;
		} else {
			return $self->SUPER::gettext(@args);
		}
	}

	# sub logtext()
	# Verhalten wie Page-Klasse
	sub logtext {
		my ($self, @args) = @_;
		return $self->SUPER::logtext(@args);
	}
}



{
	package SolutionPage;
	use base 'Page';

	# sub new()
	# Konstruktor
	sub new {
		my ($package, $logfile) = @_;
		my $self = Page->new($logfile);
		$self->{DISPLAY} =1;
		$self->{MENUITEM} =0;
		bless $self;
		return $self;
	}

	# nichts tun
	sub split {
	}

	# sub link()
	# Verhalten wie Page-Klasse
	sub link {
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

	# sub fullmenu()
	# Verhalten wie ueberheordnetes Objekt
	# Dadurch erhaelt die Seite das Menu der uebergeordneten Seite
	sub fullmenu {
		my ($self, @args) = @_;
		return $self->{PARENT}->fullmenu(@args);
	}

	# sub menu()
	# hat kein Menu-Item
	sub menu {
		my ($self, $curpage, $menuauswahllevel) = @_ ;
		return "";
	}

	# sub navprev()
	# Verhalten wie ueberheordnetes Objekt
	# Dadurch erhaelt die Seite die Navigation der uebergeordneten Seite
	sub navprev {
		my ($self) = @_;
		return $self->{PARENT}->navprev();
	}

	# sub navnext()
	# Verhalten wie ueberheordnetes Objekt
	# Dadurch erhaelt die Seite die Navigation der uebergeordneten Seite
	sub navnext {
		my ($self, @args) = @_;
		return $self->{PARENT}->navnext(@args);
	}

	# sub subpagelist()
	# Verhalten wie uebergeordnetes Objekt
	sub subpagelist {
		my ($self, @args) = @_;
		return $self->{PARENT}->subpagelist(@args);
	}

	# sub gettext()
	# Verhalten wie Page-Klasse
	sub gettext {
		my ($self, @args) = @_;

		return $self->SUPER::gettext(@args);
	}

	# sub logtext()
	# Verhalten wie Page-Klasse
	sub logtext {
		my ($self, @args) = @_;
		return $self->SUPER::logtext(@args);
	}
}

# --------------------------------------------- Das Hauptprogramm ----------------------------------------------------------------------------------------------------------------------

sub main {

#Log-Datei initialisieren
$rw = open(OUTPUT, "> $logfile") or die "Fehler beim Erstellen der Logdatei.\n";
close(OUTPUT);

#Versionsanzeige
$fh = File::Data->new($logfile);
$fh->write("conv.pl $version (MINT-Modifikation $dokversion)\nVersionen: deutsch $verde, englisch $veren\n"); #"final: " . ($paramfinal ? "ja" : "nein") . "\n");
undef $fh;
print "conv.pl $version (MINT-Modifikation $dokversion)\nVersionen: deutsch $verde, englisch $veren\n";
#print "final: " . ($paramfinal ? "ja" : "nein") . "\n";


print "Es wurden " . ($#ARGV+1) . " Parameter übergeben\n";

# Parameter der Kommandozeile holen
for ($i=0; $i<=$#ARGV; $i++) {
  if (($ARGV[$i] eq "--help") or ($ARGV[$i] eq "-help") or ($ARGV[$i] eq "-h")) {
    die "FATAL: This program should not be started from command line!\n";
  }
}

#Zeit speichern und Startzeit anzeigen
$time = time;
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
print (($year+1900 ) . "-" . ($mon+1) . "-$mday $hour:$min:$sec\n\n");
logtext("Starting conversion: " . ($year+1900 ) . "-" . ($mon+1) . "-$mday um $hour:$min:$sec Uhr");

#Alte Daten loeschen
print "Copying files into " . $config{outtmp} . "\n";
system "rm -rf " . $config{outtmp};
system "mkdir -p " . $config{outtmp};
system "cp -R files/* " . $config{outtmp};
print " ok.\n\n";


# DirectHTML-Datei einlesen
my $direct_all = read_file('directhtml.txt') or die("FATAL: Could not read directhtml.txt");
my $k = 0;
while ($direct_all =~ m/<!-- startfilehtml;$k; \/\/-->/s ) {
  $direct_all =~ s/<!-- startfilehtml;$k; \/\/-->(.*)<!-- stopfilehtml;$k; \/\/-->//s ;
  push @DirectHTML, $1;
  $k++;
}
print "$k DirectHTML-Statements verwendet\n";


print "Starte TtM\n\n";
system "./ttm-src/ttm -p./tex < tex/vorkursxml.tex >$xmlfile";
print "\n";
$text = loadfile($xmlfile);

# Debug-Meldungen ausgeben
while ($text =~ s/<!-- debugprint;;(.+?); \/\/-->/<!-- debug;;$1; \/\/-->/s ) { print "$1\n"; }

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

print "\n";

while ($text =~ s/<!-- mdeclarepoints;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);; \/\/-->//s ) { 
  # print "POINTS: Module $1, id $2, points $3, intest $4, chapter $5\n"; 
  if ($5 eq 1) {
    my $l = $1 - 1;
    $expoints[$l] += $3;
    # print "expoints $l now at " . $expoints[$l] . "\n";
    if ($4 == "1") {
      $testpoints[$l] += $3;
      # print "testpoints $l now at " . $testpoints[$l] . "\n";
    }
  }
}

while ($text =~ s/<!-- mdeclareuxid;;(.+?);;(.+?);;(.+?);; \/\/-->//s ) { 
  # print "uxid: $1, $2, $3\n"; 
  push @uxids, [$1, $2, $3];
}

while ($text =~ s/<!-- mdeclaresiteuxid;;(.+?);;(.+?);;(.+?);; \/\/-->/<!-- mdeclaresiteuxidpost;;$1;; \/\/-->/s ) { 
  # print "siteuxid: $1 in chapter $2 and section $3\n"; 
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
  print("Punkte in section " . ($i+1) . ": " . $expoints[$i] . ", davon " . $testpoints[$i] . " von Tests.\n");
  print("Sites in section " . ($i+1) . ": " . $sitepoints[$i] . "\n");
}

if ($text =~ s/<!-- mlocation;;(.+?);;(.+?);;(.+?);; \/\/-->//s ) {
  $locationicon = $1;
  $locationlong = $2;
  $locationshort = $3;
  $locationsite = "location.html";
  print "Verwende Standort-Deklaration für $locationlong\n";
} else {
  $locationsite = "";
  push @converrors, "Keine Standort-Deklaration gefunden, Standortbutton erscheint nicht im Kurs.";
}

if ($text =~ m/<!-- mglobalbetatag -->/s ) { # hier nicht ausschneiden, da globaltag und nicht locationtag
  push @converrors, "BETA-Deklaration gefunden, erstelle Beta-Button!";
} else {
  $isBeta = 0;
}


# =========================
# = Vorkurs-Einstellugnen =
# =========================

# Alles ab 'File translated...' entfernen
$text =~ s/<hr \/><small>File translated from.*<\/body>.*//s;

$paramversion = "all";

# =================
# = Konvertierung =
# =================
# Schritt 1: Initialisierung
# ==========================

$templateheader = generate_scriptheaders() . $templateheader . "\n";

if ($config{parameter}{feedback_service} ne "") {
  print("FeedbackServer deklariert: " . $config{parameter}{feedback_service} . "\n");
} else {
  push @converrors, "Kein FeedbackServer deklariert, es wird kein Feedback verschickt.";
}
if ($config{parameter}{data_server} ne "") {
  print("DataServer deklariert: " . $config{parameter}{data_server} . "\n");
  print("Description: " . $config{parameter}{data_server_description} . "\n");
} else {
  push @converrors, "Kein DataServer in Konfigurationsdatei deklariert (Parameter data_server)!";
}

if ($config{parameter}{exercise_server} ne "") {
  print("ExerciseServer deklariert: " . $config{parameter}{execise_server} . "\n");
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

print "     main: " . $config{parameter}{signature_main} . "\n";
print "  version: " . $config{parameter}{signature_version} . "\n";
print "   locale: " . $config{parameter}{signature_localization} . "\n";
print "timestamp: " . $config{parameter}{signature_timestamp} . "\n";
print "conv-user: " . $config{parameter}{signature_convuser} . "\n";
print "c-machine: " . $config{parameter}{signature_convmachine} . "\n";
print "      CID: " . $config{parameter}{signature_CID} . "\n";
print "Diese Informationen werden im HTML-Baum hinterlegt.\n\n";

# Wir befinden uns gerade im zu erzeugenden Baum, in dem perl ein Unverzeichnis ist, das Kopieren der Dateien von perl/files nach .. wurde schon durchgefuehrt
$mints_open = open(MINTS, "> " . $config{outtmp} . "/convinfo.js") or die "FATAL: Could not create convinfo.js.\n";
print MINTS "// Automatically generated by conv.pl, will be included by the standard template\n";
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
while (($ckey, $cval) = each($config{'parameter'})) {
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


if ($config{parameter}{do_export} eq "1") { print "----------------------- EXPORTVERSION WILL BE GENERATED ----------------------------\n";  }
if ($config{parameter}{do_feedback} eq "1") { print "----------------------- FEEDBACKVERSION WILL BE GENERATED ----------------------------\n";  }

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
  # print "Stichwort $1\n";
  $i++;
}

# Sortieren mit IdiotSort FUNKTIONIERT NICHT MIT UMLAUTEN
my $swap = 1;
print "Sortiere " . ($#wordindexlist-1) . " Stichwoerter:\n"; 
while ($swap==1) {
  $swap = 0;
  for ($i=0; $i <= $#wordindexlist; $i++ ) {
    for ($j=$i+1; $j <= $#wordindexlist; $j++ ) {
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


# # In Datei Ausgeben
# print "EntryCollection wird in $outputfolder"."entrycollection.tex geschrieben\n";
# my $mints_open = open(MINTS, "> $outputfolder"."entrycollection.tex") or die "Fehler beim Erstellen der EntryCollection-Datei.\n";
# print MINTS "\%---------- Von conv.pl generierte Datei ------------\n";
# for ($i = 0; $i <= $#wordindexlist; $i++) {
#   print MINTS "Stichwort \\special{html:$wordindexlist[$i]}, Link ist \\special{html:<a href=\"$wordindexlinklist[$i]\">hier</a>}\\ \\\\\n";
# }
# close(MINTS);



# print "\nSTICHWORTLISTE:\n";
# for ( $i=0; $i <= $#wordindexlist; $i++ ) {
#   print "$wordindexlist[$i]\n$wordindexlinklist[$i]\n---------------------------\n";
# }
# 
# print "\n";


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


print "\n\nErmittele Kapitelstruktur . . .  \n";

logtext("\nErmittele Kapitelstruktur");

$root = ModulPage->new($logfile);
$root->{TITLE} = "ROOT";
$root->split($text, $paramsplitlevel);
$root->{DISPLAY} = 0;

verarbeitung($root);

@LabelStorage = ();

my $outfinal = "";
storelabels($root);
$outfinal = $config{outtmp};
print "Writing output to $outfinal\n";
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
  print "Exportfile for contained collections is generated: ";
  my $nco = $#colexports + 1;
  if ($nco le 0) {
    print "No exports found!\n";
  } else {
    print("Exporting $nco collections\n");
    my $colexportfile = open(MINTS, "> collectionexport.json") or die "FATAL: Cannot write collectionexport.json";
    print MINTS "{ \"comment\": \"Automatisch generierte JSON-Datei basierend auf Kurs-ID $signature_CID\",\n \"collections\": [";
    my $k;
    for ($k = 0; $k <= $#colexports; $k++) {
    print MINTS "  ";
      if ($k ge 1) { print MINTS ","; }
      print MINTS "{ \"id\": \"" . $colexports[$k][0] . "\", \"exercises\": " . $colexports[$k][2] . "}";
    }
    
    
    print MINTS "]}\n";
    close(MINTS);
  }
}




#Rechte setzen
system "chmod -R 777 " . $config{outtmp};

#Rechenzeit anzeigen
$time2 = time;
$diff = $time2 - $time;
print "\nDone: Computation took $diff seconds.\n\n";

if ($#converrors ge 0) {
  print "----------------------- COMPILATION ERRORS ---------------------------------\n";
  my $yi = 0;
  for ($yi = 0; $yi <= $#converrors; $yi++) {
    print("  " . $converrors[$yi]);
    print("\n");
  }
} else {
  print "No compilation errors occurred.\n";
}

}


# ---------------------------------------------- Das eigentliche Hauptprogramm -----------------------------------------------

main();
