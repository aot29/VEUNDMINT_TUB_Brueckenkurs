# 
# Die Klasse Page enhaelt alle zu einer Seite gehoerenden Funktionen
#  

# Eigenschaften
# =============
# SUBPAGES		array, Liste der subsections
# LEVEL			integer, Nummer der Ebene
# ISCHAPTER		boolean, Kapitel oder Section
# PARENT		obj, Referenz auf übergeordnetes Objekt, 0 falls Wurzel
# ROOT			obj, Referenz auf oberstes Objekt
# NEXT			obj, Referenz auf naechtes Objekt
# PREV			obj, Referenz auf vorheriges Objekt
# NR			string, Nummer des Abschnitts
# POS			integer, Position in der Objektstruktur auf der aktuellen Ebene
# TITLE			string, Titel
# TEXT			string, Text
# LINK			string, Dateiname auf den verlinkt wird und in dem gespeichert wird
# SAVEPAGE		boolean, Text abspeichern
# MENUITEM		boolean, Seite taucht im Menu auf
# DISPLAY		boolean, Seite wird gespeichert
# LOGFILE		string, Datei in die log-text geschrieben wird

# DH 2011:
# MODULID		integer, index in das Feld der Modulid's in vorkurs.pl bzw. direkter Strings
# DOCNAME		string, Dateiname des zu produzierenden Dokuments ohne Pfad und ohne Endung (z.B. "xcontent3")
# ICON                  string, Bezeichner des Icons das in der Navigation verwendet wird. Falls "STD" steht wird das Icon nach der ModulID gewaehlt, bei NONE erscheint der Abschnitt nicht in der Navigation
# TOCSYMB               string, HTML-Content der im minitoc fuer die section angezeigt wird
# ID   			integer, eindeutige ID für jedes einzelne Page-Objekt
# XCONTENT		integer, gibt den content-typ an: 2 = SCONTENT, 1 = XCONTENT, 0 = Unbekannt
# XPREV			obj, Referenz auf vorhergehende xcontent-subsubsection (nur falls XCONTENT = 1)
# XNEXT			obj, Referenz auf nachfolgende xcontent-subsubsection (nur falls XCONTENT = 1)
# HELPSITE              0: Ist normaler Modulinhalt, 1: gehoert zur Hilfe/Bedienungs-Sektion
# TESTSITE              0: Ist normaler Modulinhalt, 1: ist eine Testseite fuer die Punktedaten eingeblendet
# EXPORTS               Array aus Paaren aus Dateinamen und Strings, die in separate Dateien geschrieben werden
#
#
#
# Funktionen
# ==========
# new			Konstruktor
# split			Zerteilung von Text, Erstellung der Objektstruktur
# link			liefert den Dateipfad, wo diese Seite gespeichert wird
# linkpath		liefert zum link passende Anzahl von "../"
# addpage		erweitert das Array SUBPAGES um das abgegebene Objekt und setzt die
#				Eigenschaften PARENT und ROOT
# secpath		liefert eine eindeutige Position des Objekts innerhalb der Objektstruktur
# titlepath		liefert Titel des Kapitels und der aktuellen Seite
# menu			liefert menu-Eintrag dieser Seite und der untergeordneten Seiten
#				in Abhaengigkeit der angegebenen Seite
# fullmenu		liefert das Menu dieser Seite
# navprev		liefert das in der Struktur folgende Objekt, das ausgegeben wird
# navnext		liefert das in der Struktur vorhergehende Objekt, das ausgegeben wird
# subpagelist	liefert eine Liste der untergeordneten Seiten
# gettext		liefert den Text dieser Seite
# logtext		schreibt log-Text in die Datei LOGFILE

# DH 2011
# idprint		gibt über print die IDs der im Teilbaum enthaltenen Pages aus

package Page;
# Exportieren der oeffentlichen Funktionen
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(new split link linkpath addpage secpath titlepath menu fullmenu navprev navnext subpagelist gettext logtext idprint);
@EXPORT_OK = qw();

# File::Data enthaelt einige Datei-verarbeitende Funktionen
use converter::File::Data;


# sub new()
# Konstruktor der Klasse
# Parameter
#	$logfile	Pfad der Textdatei in der geloggt werden soll
#
sub new {
	my ($package, $logfile) = @_;
	
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
		LOGFILE   => $logfile,
		EXPORTS   => (),
		DOCNAME   => ""
	};
	$self->{ID} = $main::PageIDCounter;
	$main::PageIDCounter++;
	#Initialisierung der root-Eigenschaft
	$self->{ROOT} = $self;
	#Variablentyp auf die Klasse stellen
	bless $self, $package;
	#$self->logtext("new page");
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
		$self->logtext("Keine weitere Unterteilung");
		if ($level>$splitlevel) {
		$self->{TITLE}="Test";
		}	
	} else {
		#Teilung in Unterabschnitte
		$self->logtext("Teilung in Unterabschnitte");
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
			$p = Page->new($self->{LOGFILE});
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
	if (($#subpages >0 && substr($self->secpath(),,6,6)!=1) and ($main::doconctitles eq 1)) {
		$path=$subpages[0]->{TITLE} ." - " . $self->{TITLE};
	} else {
		$path=$self->{TITLE};
	}
#        $path = substr($self->secpath(),0,5) . " " . $self->{TITLE}; 
        return $path;
}


# 
# sub fullmenu()
# liefert das Menu dieser Seite
# Parameter
# 	$menuauswahllevel	Parameter fuer die Sichtbarkeit der Menu-Abschnitte
sub fullmenu {
	my ($self, $menuauswahllevel) = @_;
	my ($text);
	#hole das Menu vom root-Objekt und gebe diesem einen Verweis auf das aktuelle Objekt
	#die menu-Funktion iteriert dann rekursiv durch die Objektstruktur und erstellt 
	#die Menu-Eintrag
	$text = "<!--ZOOMSTOP-->\n";
	$text .= $self->{ROOT}->menu($self, $menuauswahllevel);

# 	$text .= "<center>\n";
# 	$text .= "<form method=\"get\" action=\"../search/search.html\" target=\"_blank\">\n";
# 	$text .= "<input type=\"text\" name=\"zoom_query\" size=\"15\" />\n";
# 	$text .= "<input type=\"submit\" value=\"Suche\" />";
# 	$text .= "</form>\n";
# 	$text .= "</center>\n";
	$text .= "<!--ZOOMRESTART-->";

	return $text;
}


# 
# sub menu()
# liefert menu-Eintrag dieser Seite und der untergeordneten Seiten
# in Abhaengigkeit der angegebenen Seite
# Parameter
# 	$curpage			Seite fuer die das Menu erstellt wird
#	$menuauswahllevel	Parameter fuer die Sichtbarkeit der Menu-Abschnitte
#
# Die Seite $curpage fuer die das Menu ausgegeben wird, wird Menu-Seite genannt.
# Die Seite $self fuer die gerade das Menu-Element ausgegeben wird, wird aktuelle Seite
# oder aktuelles Objekt genannt.
#
# Falls das aktuelle Objekt nicht das root Objekt ist, wird in jedem Fall ein
# Menu-Eintrag fuer diese Seite erstellt.
# Die Rekursion wird bei den Unterseiten angewandt, falls diese ausgegeben 
# werden sollen
# 
# Das Menu hat folgende Eigenschaften:
# - Die Eintraege auf der ersten Ebene (also die Links zu den Kapiteln) werden
#   immer angezeigt.
# - Von einem Menu-Eintrag werden entweder alle oder keine untergeordneten Seiten
#	angezeigt
# - Durch den Parameter menuauswahllevel laest sich einstellen, welcher Bereich
#	des Inhaltsverzeichnis immer komplett zu sehen ist. Wenn die Menu-Seite auf dem
#	Level menuauswahllevel oder hoeher liegt, wird fuer den gesamten Teil der
#	Objektstruktur die darunter liegt ein Menu-Element ausgegeben
#	Beispiele:
#		Ist menuauswahllevel=0, so wird immer das gesamte Inhaltsverzeichnis
#		ausgegeben.
#		Ist menuauswahllevel=1, so ist immer der Inhalt eines Kapitels zu sehen.
#		Ist menuauswahllevel=2 und die Menu-Seite auf Level 1, so sind nur alle 
#		Unterseiten der Menu-Seite zu sehen. Ist die Menu-Seite auf Level 2, so
#		ist der Inhalt dieses Abschnitts komplett zu sehen.
#
# Die Ueberpruefungen finden anhand der Position in der Objektstruktur statt,
# die durch die Funktion secpath() geliefert wird.
#
sub menu {
	my ($self, $curpage, $menuauswahllevel) = @_ ;
	my ($level, @acurpos, $rek, $selected);
	my ($text, $subtext, $nextlevel, @subpages, $i);
	# Position der Menu-Seite
	my $curpos = $curpage->secpath();
	# Array der Position der Menu-Seite
	@acurpos = split(/\./, $curpos);
	# Level der aktuellen Seite
	$level = $self->{LEVEL};
	
	# die boolsche Variable rek gibt an, ob die Rekursion
	# auf die Unterseiten angewandt wird
	$rek = 0;
	
	# level=0 ist root und wird ausgeschlossen
	# ausserdem muss die Eigenschaft MENUITEM gesetzt sein
	if ($level != 0 && $self->{MENUITEM}==1) {
		#bei 0 ist Rekursionsstart
		if ($level == 1) {
			#Ausgabe des ersten Levels
			#Rekursion aufrufen, wenn 
			# menuauswahllevel=0, d.h. alle Menu-Eintraege werden immer gezeichnet
			# oder die Position der aktuellen Seite ist in curpos enthalten, d.h. das 
			# die aktuelle Seite ist übergeordnetes Element der Menu-Seite
			$rek = ($menuauswahllevel == 0 || $self->{POS} == $acurpos[0]);
			if ($self->{POS} == $curpos) {
				$selected = 1;
			}
		} elsif ($level < ($#acurpos+1)) {
			#Die aktuelle Seite liegt in eienr hoeheren Ebene als die Menu-Siete
			#Rekursion aufrufen, wenn
			# level > menuauswahllevel, d.h. das Element liegt unterhalb des Levels 'menuauswahllevel'
			# und wird immer angezeigt
			# oder die Position der aktuellen Seite ist in curpos enthalten, s.o.
			if ($level > $menuauswahllevel || $acurpos[$level-1] == $self->{POS}) {
				$rek = 1;
			}
		} elsif ($level == $#acurpos+1) {
			#auf der Ebene der Menu-Seite
			#Rekursion aufrufen, wenn
			# level > menuauswahllevel, s.o
			# oder in curpos enthalten, s.o.
			if ($level > $menuauswahllevel || $acurpos[$level-1] == $self->{POS}) {
				$rek = 1;
			}
			#Wenn die aktuelle Seite und die Menu-Siete die gleichen sind, wird der
			#Menu-Eintrag markiert
			if ($self->secpath() eq $curpos) {
				$selected = 1;
			}
		} elsif ($level > ($#acursite+1)) {
			#Die aktuelle Seite liegt unterhalb der Menu-Seite
			#Die Rekursion wird fortgefuehrt, wenn
			# level > menuauswahllevel, s.o.
			if ($level > $menuauswahllevel) {
				$rek = 1;
			}
		} else {
			#hier solte der Algorithmus nicht landen
			die "Menu-Element konnte nicht zugeordnet werden Level $level bei $curpos.";
		}

		#print "$arrid fuer $cursite mit l $level, pm $menuauswahllevel: $rek";
		
		#aktuelles Menueelement zeichnen
		#print "Zeichne $arrid fuer $cursite\n";
		if ($selected) {
			$text = "<li class='level" . $level ."selected'>" . $self->{TITLE} . "\n";
			#($paramnummenu >= $level ? $self->{NR} . " " : "") . 
		} else {
			$text = "<li class='level$level'><a class=\"MINTERLINK\" href='";
			# wenn der Link der aktuellen Seite in ein Unterverzeichnis fuert,
			# muss zusaetzlich ../ eingefuegt werden
			$text .= $curpage->linkpath() . $self->link() . ".{EXT}'>" . $self->{TITLE} . "</a>\n";
			#$text .= $self->link() . ".{EXT}'>" . $self->{TITLE} . "</a>\n";
			#($paramnummenu >= $level ? $self->{NR} . " " : "") . $self->{TITLE} . "</a>\n";
		}
	}
	
	#Rekursion aufrufen
	if ($rek || $level == 0) {
		#level hochzaehlen
		$nextlevel = $level+1;
		#Unterseiten holen
		@subpages = @{$self->{SUBPAGES}};
		
		if ($#subpages >=0) {
			#Menu der untergeordneten Elemente aneinanderhaengen
			$subtext = "";
			for ($i = 0; $i<=$#subpages;$i++) {
				$subtext .= $subpages[$i]->menu($curpage, $menuauswahllevel);
			}
			#Falls der Text nicht leer ist, dann werden die Liste-Eintraege <li>
			#in eine List <ul> gepackt
			if ($subtext ne "") {
				#Liste starten
				if ($level != 0) {
					$text .= "<ul class='level$nextlevel'>\n";
				} else {
					$text = "<ul class='level1'>\n";
				}
				# Liste zeichen
				$text .=$subtext;
				#und die Liste beenden
				$text .= "</ul>\n";
			}
		}
	}
	
	#Es wurde der Eintrag fuer die aktuelle Seite und eine Liste
	#der Untereintraege gezeichnet
	#Der Menu-Eintrag fuer die aktuelle Seite muss nun noch abgeschlossen werden
	if ($level != 0 && $self->{MENUITEM} == 1) {
		$text .="</li>\n";
	}

	return($text);
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
# sub gettext()
# liefert den Text dieser Seite
# Parameter
# 	keine
sub gettext {
	my ($self) = @_;
	return $self->{TEXT};
}


# 
# sub logtext()
# schreibt log-Text in die Datei LOGFILE
# Parameter
# 	$text	Text, der in die Datei geschrieben wird
sub logtext {
	my ($self, $text) = @_;
	#Falls es eine log-Datei gibt
	if ($self->{LOGFILE}) {
		#wird diese geoeffnet
		$fh = File::Data->new($self->{LOGFILE});
		#und eine Zeile mit der Seite-Position und dem Text angehaengt
		$fh->append($self->secpath() . "\t" . $text . "\n");
		undef $fh;
	}
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

# Bei PERL-Modules wird ein true-value als Ausgabe erwartet
1;
