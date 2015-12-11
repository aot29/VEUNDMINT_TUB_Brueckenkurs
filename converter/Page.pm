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

# DH 2011:
# MODULID		string, bezeichnet Modultyp (z.B. "xcontent" oder "start" für den ersten Content eines Ordners)
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
# navprev		liefert das in der Struktur folgende Objekt, das ausgegeben wird
# navnext		liefert das in der Struktur vorhergehende Objekt, das ausgegeben wird
# subpagelist	liefert eine Liste der untergeordneten Seiten

# DH 2011
# idprint		gibt über print die IDs der im Teilbaum enthaltenen Pages aus

package Page;
# Exportieren der oeffentlichen Funktionen
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(new split link linkpath addpage secpath titlepath menu navprev navnext subpagelist idprint);
@EXPORT_OK = qw();

# File::Data enthaelt einige Datei-verarbeitende Funktionen
use converter::File::Data;


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
	if (($#subpages >0 && substr($self->secpath(),,6,6)!=1) and ($main::doconctitles eq 1)) {
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

# Bei PERL-Modules wird ein true-value als Ausgabe erwartet
1;
