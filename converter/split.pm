# alles latin1-codiert !

package split;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(printpages linkupdate hidepageswotext createlinks createtocs relocatehelpsection mathmloptimize loadfile writefile loadtemplates logtext postprocess storelabels);
@EXPORT_OK = qw($logfile);

use Switch;
use File::Path;  #mkpath($path);
use MIME::Base64 qw(encode_base64);

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
  if ( $outputfile =~ m/(.+)\/(.+)/ ) {
    $outputfolder = $1;
  } else {
    $outputfolder = $outputfile;
  }

  # Pull-Seiten aktivieren, JS-Variablen anpassen (geschieht normalerweise in conv.pl bei xcontents, aber HELPSITE-Sectionstart ist keiner?)
  if ($text =~ m/<!-- pullsite \/\/-->/s ) {
    $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_PULL = 1;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
    print "User-Pull on Site: " . $orgpage->{TITLE} . "\n";
  } else {
    $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_PULL = 0;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
  }
  
  # br-Tags entfernen, die nebeneinander gestellte tabulars zerreissen
  # Das ist unsauber, weil nicht klar ist, warum ttm diese Tags prinzipiell zwischen Tabellen setzt
  # Erkennungsmerkmal ist die Tagkombination <!--hbox--><br clear="all" /> und danach direkt ein table-Tag
  $text =~ s/<!--hbox--><br clear=\"all\" \/> *<table/<!--hbox--> <table/g;    # Sternchen vor <table> ein Tippfehler?

  
  # In start-stop-align-Bloecken die td-Tags anpassen

    # $text =~ s/[\n\r]*//g ;

    $pref = "xxx"; # Prefix wird vor modifizierte td's gesetzt um sie zu markieren

    $rpr = "CRLF";
    while ($text =~ /$rpr/i ) { $rpr = $rpr . "y" };
    # print "Using CRLF-Prefix: $rpr\n";
    $text =~ s/\n/$rpr A/g;
    $text =~ s/\r/$rpr B/g;



#     while ($text =~ /<!-- minimarker;;(.+?);;(.+?); \/\/-->/ ) {
#       my $i = $1;
#       my $width = $2;
#       my $perc = $width*100;
#       my $orgs = "<!-- minimarker;;$i;;$width; \/\/-->";
#   
#       if ($text =~ s/<table(.*?)>(.*?)$orgs/<$pref table width=\"$perc\%\"$1>$2/ ) {
# 	print "MiniMarker eingesetzt\n";
#       } else {
# 	print "ERROR: Konnte minimarker nicht matchen: $orgs\n";
# 	print "ORG:\n$text\n\n";
# 	$text =~ s/$orgs// ;
#       }
#     }
# 
#     $text =~ s/<$pref table/<table/g;


    while ($text =~ /<!-- startalign;;(.+?);;(.+?); \/\/-->/ ) {
      my $i = $1;
      my $al = $2;
      # print "Align-environment $i with align=\"$al\":\n";

      while ($text =~ /<!-- startalign;;$i;;$al; \/\/-->(.*?)<td(.*?)>(.*)<!-- stopalign;;$i; \/\/-->/  ) {
	$x1 = $1;
	$x2 = $2;
	$xrep = $x2;
	$x3 = $3;
      
	if ($xrep =~ s/align=[\"'](.*?)[\"']/align=\"$al\"/ ) {
	  # direct align replace happened
	} else {
	  # concatenate alignment
	  $xrep = $xrep . " align=\"$al\"";
	}
	
	if ($text =~ s/<!-- startalign;;$i;;$al; \/\/-->$x1<td$x2>$x3<!-- stopalign;;$i; \/\/-->/<!-- startalign;;$i;;$al; \/\/-->$x1<$pref td$xrep>$x3<!-- stopalign;;$i; \/\/-->/ ) {
	  # print "  TD corrected, attributes $x2 changed to $xrep\n";
	} else {
	  # print "WARNING: Could not translate a td in align-block $i, removing blockmarkers\n";
#           $ret = $text;
# 	  $ret =~ s/$rpr A/\n/g;
#           $ret =~ s/$rpr B/\r/g;
# 
# 	  print "ORG:\n$ret\n\n";
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
  # print "Copying local files, outputfolder=$outputfolder, outputfile=$outputfile\n";
  my $nf = 0;
  # print "ORG:\n$text";
  while ($text =~ /<!-- registerfile;;(.+?);;(.+?);;(.+?); \/\/-->/) {
    $nf++;
    my $fileid = $3;
    my $includedir = $2;
    my $fname = $1;
    my $fnameorg = $fname;

    # print "Processing includedir=$includedir and fname=$fname, id = $fileid\n";

    # Ist die Dateierweiterung mit angegeben?
    my $dobase64 = 0;
    my $fext = "";
    if ($fname =~ m/\.(.+)/ ) {
      $fext = "." . $1;
      $fname =~ s/$fext//;
      # print "File extension is $fext\n";
      if ($fext eq ".png") { $dobase64 = 1; } else { $dobase64 = 0; print "   kein .png sondern " . $fext . "\n";}
      if ($fext eq ".PNG") { print "FEHLER: png-Datei mit Dateierweiterung PNG gefunden, wird nicht erkannt!\n"; }
      
    } else {
      # print "No file extension given, guessing graphics extensions";
      # Simuliere DeclareGraphicsExtension{png,jpg,gif}
      my $filerump = "tex/" . $includedir . "/" . $fname;
      my $filelist = `ls -l $filerump.*`;
      # print "filelist=$filelist\n";
      my $filerump2 = noregex($filerump);

      if ($filelist =~ m/$filerump2\.(png)/i) {
        $fext = ".$1";
        $dobase64 = 1;
      } else {
        if ($filelist =~ m/$filerump2\.(jpg)/i) {
        $fext = ".$1";
        # print "...found a jpg\n";
      } else {
        if ($filelist =~ m/$filerump2\.(gif)/i) {
          $fext = ".$1";
          # print "...found a gif\n";
        } else {
          print "\nERROR: Could not find suitable graphics extension for $fname, rump is $filerump, rump2 is $filerump2, filelist is\n$filelist\n\n";
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

      # print "fileid $fileid wird expandiert zu $fname, liegt in Ordner $outputfolder\n";

      # Register-Tag aus Quelltext entfernen
      my $fnameorg2 = noregex($fnameorg);
      $text =~ s/<!-- registerfile;;$fnameorg2;;$includedir;;$fileid; \/\/-->// ;
      # oberste Verzeichnisebene aus $fname entfernen, denn die include-Verzeichnisse fuer die Module werden im HTML-Baum nicht reproduziert
      if ($includedir ne ".") { $fname =~ s/$includedir\///; }
      $fi = "tex/" . $includedir . "/" . $fname;
      
      if ($dobase64 eq 1) {
        my $sc = -s $fi;
        print "   generating base64-Inlinestring for $fi of size $sc\n";
        open PNGFILE, '<', $fi;
        binmode PNGFILE;
        my $buf; $c64 = "";
        if (read( INFILE, $buf, $sc )) {
          $c64 = encode_base64($buf);
        } else {
          print "   file not readable\n";
        }
        close PNGFILE;
        print "   OUTPUT = \n" . $c64 . "\n\n";
      }
      
      $fi2 = $outputfolder . "/" . $fname;
      print "     Copying $fi to $fi2\n";
      $fi2 =~ /(.*)\/[^\/]*?$/;
      # print "New folder $1\n";
      mkpath($1);
      my $call = "cp -rf $fi $1/.";
      
      
      
      
      # print "DEBUG: call = $call\n";
      system($call);
    }
  }
  # if ($nf>0) { print "$nf local files copied.\n"; }


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

  # print "POST:\n$text";

  # modulgheader und footer abfangen und grafische Darstellung einsetzen
  if (($p->{TESTSITE} ne 1) and ($p->{HELPSITE} ne 1)) {
    my $ghrep = "";
    # $ghrep = "<b>" . $orgpage->{NR} . " / " . ($#{$orgpage->{PARENT}->{SUBPAGES}} + 1) . "</b>\n";
    while ($text =~ m/<!-- modulgheader \/\/-->/s ) {
      $text =~ s/<!-- modulgheader \/\/-->/$ghrep/s ;
      print("Grafischen Modulheader fuer Modul " . $orgpage->{NR} . " (" . $orgpage->{TITLE} . ") erzeugt\n");
    }
    $ghrep = "<p><center><b>Stichworte in diesem Modul</b></center>";
    
    while ($text =~ m/<!-- modulgfooter \/\/-->/s ) {
      $text =~ s/<!-- modulgfooter \/\/-->/$ghrep/s ;
      print("Grafischen Modulfooter fuer Modul " . $orgpage->{NR} . " (" . $orgpage->{TITLE} . ") erzeugt\n");
    }
  }
  

  # WTabular-Umgebungen parsen
  while ($text =~ m/<!-- wtab-start;;(.+?);;(.+?); \/\/-->/) {
    # print "Found wtab $1 with parameters $2\n";
    my $wtn = $1;
    my $wtp = $2;
    my $liner = $wtp;
    # LaTeX-Tabular-Beschreibung decodieren
    $liner =~ s/ - /1/g;

    # print "tabularcode = $liner\n";

    $liner =~ s/{(.)}/$1/g;
#     while ($liner =~ m/\*([0123456789]+)/ ) {
#       $c = $1;
#       $d = "";
#       for ($i=0; $i < $c; $i++) {
#         $d = $d . "c";
#       }
#       print "Replacing \*$c with $d in tabular\n";
#       $liner =~ s/\*$c/$d/g; 
#     }

    $liner =~ s/[lrc]/0/g;
    


    # print "Ruling = $liner\n";

    # Coding: A -> keine Raender
    #         B -> Rand nur links
    #         C -> Rand nur rechts
    #         D -> Rand an beiden Seiten

    $liner =~ s/10/B/g;
    $liner =~ s/B1/D/g;
    $liner =~ s/01/C/g;
    $liner =~ s/1C/D/g;
    $liner =~ s/0/A/g;

    # print "RuleCode = $liner\n";


    $markera = "<!-- wtab-start;;$wtn;;$wtp; \/\/-->";
    $markerb = "<!-- wtab-end;;$wtn; \/\/-->";
    $tpa = index($text,$markera);
    $tpb = index($text,$markerb);
    if (($tpa ne -1) and ($tpb ne -1)) {
        $wtab = substr($text,$tpa,($tpb - $tpa) + length($markerb));
       
        #print "FOUND wtab $wtn\n";
        #print "ORG = \n$wtab\n";


        # Tags entfernen
        $wtab =~ s/$markera// ; 
        $wtab =~ s/$markerb// ; 


        # Newlines entfernen
        $wtab =~ s/\n//g;

        $wtab =~ s/<table(.*?)>/<table class=\"wtabular\"$1>/ ;

        $wtab =~ s/<td(.*?)>(.*?)<\/td>/<txd$1>$2<\/txd>/g;
        $wtab =~ s/<tr(.*?)>(.*?)<\/tr>/<txr$1>$2<\/txr>/g;


        $row = 0;
        while ($wtab =~ m/<txr(.*?)>(.*?)<\/txr>/ ) {
          $p1 = $1;
          $p2 = $2;
          $pn = $p2;
  
          # Modifiziere Zeile $row in der der Tabelle
          $col = 0;
          # print "PN = $pn\n";
          while ($pn =~ m/<txd(.*?)>(.*?)<\/txd>/ ) {
            $cp1 = $1;
            $cp2 = $2;
	    # print " --> cp2 = $cp2\n";
            $cpn = $cp2;

            # Modifiziere Spalte $col in Zeile $row in der der Tabelle
            $lcode = substr($liner,$col,1);
            $cla = "class=\"wtabular_$lcode";
            if ($row eq 0) { $cla = $cla . "U"; }
            $cla = $cla . "\"";

	    # Verhindere Klammern, die von PERL geparst werden
	    $cp1x = $cp1;
            # Beseitige herkoemmliche Rahmendefinition
	    $cp1x =~ s/class=[\"']rahmen[\"']/ / ;
	    $cp1x =~ s/\(/\\\(/g;
	    $cp1x =~ s/\)/\\\)/g;
	    $cp2x = $cp2;
	    $cp2x =~ s/\(/\\\(/g;
	    $cp2x =~ s/\)/\\\)/g;

            $cp1x =~ s/\+/\\\+/g;
            $cp1x =~ s/\[/\\\[/g;
            $cp1x =~ s/\]/\\\]/g;
            $cp2x =~ s/\+/\\\+/g;
            $cp2x =~ s/\[/\\\[/g;
            $cp2x =~ s/\]/\\\]/g;

            $pn =~ s/<txd$cp1x>$cp2x<\/txd>/  <td $cla$cp1>$cpn<\/td>\n/ ;
            # print "<txd$cp1x>$cp2x<\/txd>/  <td $cla$cp1>$cpn<\/td>\n\n";
	          #print "Repl:   col=$col\n";
            $col = $col + 1;
          }
          
          # Verhindere Klammern, die von PERL geparst werden
	  $p1x = $p1;
	  $p1x =~ s/\(/\\\(/g;
	  $p1x =~ s/\)/\\\)/g;
	  $p1x =~ s/\[/\\\[/g;
	  $p1x =~ s/\]/\\\]/g;
	  $p1x =~ s/\+/\\\+/g;
	  $p2x = $p2;
	  $p2x =~ s/\(/\\\(/g;
	  $p2x =~ s/\)/\\\)/g;
	  $p2x =~ s/\[/\\\[/g;
	  $p2x =~ s/\]/\\\]/g;
	  $p2x =~ s/\+/\\\+/g;


          $wtab =~ s/<txr$p1x>$p2x<\/txr>/<tr$p1>\n$pn<\/tr>\n/ ;
          # print "Repl: row=$row\n";
          $row = $row + 1;
        }

        $wtab =~ s/<table(.*?)>/\n<table$1>\n/ ;
        

        substr($text,$tpa,($tpb - $tpa) + length($markerb)) = $wtab;
        # print "NEW:\n$wtab\n";
    } else
    {
      print "ERROR: Konnte wtab $wtn nicht extrahieren\n";
    }
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

  # mfeedbackbutton ersetzen
  while ($text =~ m/<!-- mfeedbackbutton;(.+?);(.*?);(.*?); \/\/-->/s ) {
    my $type = $1;
    my $testsite = $2;
    my $exid = $3;
    my $j;
    my $ibt = "\n<br />";
    # Ehemalige Buttons fuer Studentenfeedback:
    # for ($j=1; $j<=5; $j++) {
    #   my $bid = "FEEDBACK$j\_$exid";
    #   my $tip = "Feedback zu " . $type . " " . $exid . ":<br /><b>" . $main::feedbacktitles[$j-1] . "</b>";
    #   $ibt .= "<button style=\"background-color: #FFFFFF; border: 0px\" ttip=\"1\" tiptitle=\"$tip\" name=\"Name_FEEDBACK$j\_$exid\" id=\"$bid\" type=\"button\" onclick=\"feedback_button($j,\'$exid\',\'$bid\',\'$type $exid\');\">";
    #   $ibt .= "<img alt=\"Feedbackbutton$j\" style=\"width:32px\" src=\"" . $orgpage->linkpath() . "../images/face$j.png\">";
    #   $ibt .= "</button>";
    # }
    # $ibt .= "<br />\n";

    my $bid = "FEEDBACK$j\_$exid";
    my $tip = "Feedback zu " . $type . " " . $exid . ":<br /><b>Meldung abschicken</b>";
    $ibt .= "<button type=\"button\" style=\"background-color: #E0C0C0; border: 2px\" ttip=\"1\" tiptitle=\"$tip\" name=\"Name_FEEDBACK$j\_$exid\" id=\"$bid\" type=\"button\" onclick=\"internal_feedback(\'$exid\',\'$bid\',\'$type $exid\');\">";
    $ibt .= "Meldung abschicken";
    $ibt .= "</button><br />\n";
    
    # Feedbackbuttons nur, (ehemals falls keine Testumgebung und) falls nicht global abgeschaltet
    if ($main::config{parameter}{do_feedback} eq "1") {
      $text =~ s/<!-- mfeedbackbutton;$type;$testsite;$exid; \/\/-->/$ibt/s ;
    } else {
      $text =~ s/<!-- mfeedbackbutton;$type;$testsite;$exid; \/\/-->//s ;
    }
  }

  # DirectHTML-Statements einsetzen
  while ($text =~ m/<!-- directhtml;;(.*?); \/\/-->/s ) {
    my $pos = $1;
    my $rep = $main::DirectHTML[$pos];
    $text =~ s/<!-- directhtml;;$pos; \/\/-->/$rep/s ;
  }
  
  # qexports erfassen
  # Beachte: qpos = Eindeutiger Exportindex pro tex-Datei (wird im PreParsing erstellt, unabh‰ngig von section oder xcontent)
  # pos = Eindeutiger Exportindex pro page bzw. html-Datei (wird im Postprocessing erstellt), Dateiname des exports ist pagename plus pos plus extension
  while ($text =~ m/<!-- qexportstart;(.*?); \/\/-->(.*?)<!-- qexportend;(.*?); \/\/-->/s ) {
    my $qpos = $1;
    my $expt = $2;
    if ($qpos == $3) {
      my $rep = "";
      if ($main::config{parameter}{do_export} eq "1") {
        my $exprefix = "\% Export Nr. $qpos aus " . $orgpage->{TITLE} . "\n";
        $exprefix .= "\% Dieser Quellcode steht unter CCL BY-SA, entnommen aus dem VE\&MINT-Kurs " . $main::signature_CID . ",\n";
        $exprefix .= "\% Inhalte und Quellcode des Kurses d¸rfen gem‰ﬂ den Bestimmungen der Creative Common Lincense frei weiterverwendet werden.\n";
        $exprefix .= "\% F¸r den Einsatz dieses Codes wird das Makropaket mintmod.tex benˆtigt.\n";
        my $pos = 0 + @{$orgpage->{EXPORTS}};
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
      print "ERROR: Inkongruentes qexportpaar gefunden: $qpos (im Seitenarray an Position $pos$)\n";
    }
  }
 
  # exercisecollections erfassen
  if ($main::config{docollections} eq 1) {
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
        print "    Aufgabe extrahiert\n";
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
      push @main::colexports, ["$ecid1", "$ecopt" , $arraystring];
    }
    if ($collc > 0) { print "  $collc collections mit insgesamt $colla Aufgaben exportiert\n"; }
  }

  return $text;
}

# ENDE sub postprocess

# Parameter: $id, die eindeutige Collection-ID, $opt:   Die Optionen fuer die Collection
sub generatecollectionmark {
  $id = $_[0];
  $opt = $_[1];
 
  my $s = "<!-- collectionplaceholder: $id, $opt //-->";
  return $s;
}


# sub getstyleimporttags()
# Erzeugt die tags zur Einbindung der Stylesheets
# Parameter: $lp:   Der Linkpath
sub getstyleimporttags {
   my ($lp) = @_;
  
   my $itags = "";


    print "Using these stylesheets: ";
    my $i;
    for ($i = 0; $i <= $#{$main::config{stylesheets}}; $i++) {
      my $cs = $main::config{stylesheets}[$i];
      $itags = $itags . "<link rel=\"stylesheet\" type=\"text\/css\" href=\"$lp$cs\"\/>\n";
      print "$cs "; 
    }
    
    print "\n";

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
               "<div id=\"footerright\">" . $main::config{parameter}{footer_right} . "</div>" .
               "<div id=\"footermiddle\">" . $main::config{parameter}{footer_middle} . "</div>\n";
  return $footer;
}


# Uebersetzt die alten (VEMA) Iconnamen in die neuen Dateiprefixe, im alten Design geschieht diese Uebersetzung im default.css
# Parameter: Der Iconstring
sub translateoldicons {
  ($icon) = @_;
  
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
  ($icon, $anchor) = @_;
  
  return "<div class=\"$icon\">" . $anchor . "</div>\n";
}

# Erzeugt das navigations-div fuer die html-Seiten
# Parameter: Das Seitenobjekt
sub getnavi {
  ($site) = @_;

  my $p;
  my $navi = "";
  $navi .= "<!--ZOOMSTOP-->\n";

  # Link auf die vorherige Seite
  $p = $site->navprev();
  my $ac = $main::config{strings}{button_previous};
  my $icon = "nprev";
  if (($site->{XCONTENT} == 1) and (!($p))) {
    if ($site->{XPREV} != -1) {
      $p = $site->{XPREV};
      $icon = "xnprev";
    }
  }
  my $anchor;
  if (($p) and ($site->{LEVEL}==$main::contentlevel)) {
    $anchor = "<a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $p->link() . ".{EXT}\">$ac</a>";
  } else {
    $icon = $icon . "g";
    $anchor = $ac;
  }
  $navi .= "<div class=\"$icon\">" . $anchor . "</div>\n";

  # Link auf die naechste Seite
  $p = $site->navnext();
  $ac = $main::config{strings}{button_next};
  $icon = "nnext";
  if (($site->{XCONTENT} == 1) and (!($p))) {
    if ($site->{XNEXT} != -1) {
      $p = $site->{XNEXT};
      $icon = "xnnext";
    }
  }
  if (($site->{LEVEL} == ($main::contentlevel-2)) and ($site->{XNEXT} ne -1)) {
    # Von Modulhauptseite kommt man mit "Weiter" auf die erste contentseite
    $p = $site->{XNEXT};
    $icon = "xnnext";
  }
  if (($site->{LEVEL} == ($main::contentlevel-3)) and ($site->{XNEXT} ne -1)) {
    # Von FB-Hauptseite kommt man mit "Weiter" auf die erste Modulhauptseite
    $p = $site->{XNEXT};
    $icon = "xnnext";
  }

  if (($p) and (($site->{LEVEL}==$main::contentlevel) or ($site->{LEVEL}==($main::contentlevel-2)) or ($site->{LEVEL}==($main::contentlevel-3)))) {
    $anchor = "<a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $p->link() . ".{EXT}\">$ac</a>";
  } else {
    $icon = $icon . "g";
    $anchor = $ac;
  }
  $navi .= createTocButton($icon, $anchor);

  # Links auf die subsubsections im gleichen Teilbaum
  $navi .= "<ul>\n";

    if ($site->{LEVEL}!=$main::contentlevel) {
      if ($site->{XCONTENT}==3) {
        # Link auf Aufgabenstellung bei Loesungsseiten
	$navi .= "  <li class=\"inormalbutton_book\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $site->{BACK}->link() . ".{EXT}\">" . "Zum Modul" . "</a></li>\n";
      } else {
        # Link auf Modulstart setzen bei hoeheren Ebenen
	$pp = $site;
	if ($pp->{LEVEL}!=$main::contentlevel) {
	  my @sp = @{$pp->{SUBPAGES}};
	  $pp = $sp[0];
	}
	if ($pp->{HELPSITE} eq 0) {
	  $navi .= "  <li class=\"inormalbutton_book\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $pp->link() . ".{EXT}\">" . $main::config{strings}{module_starttext} . "</a></li>\n";
	} else {
	  $navi .= "  <li class=\"inormalbutton_book\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . $pp->link() . ".{EXT}\">" . "Mehr Informationen" . "</a></li>\n";
	}
      }
    }

    my $parent;
    if ($parent = $site->{PARENT}) {
      my @pages = @{$parent->{SUBPAGES}};
      for ( $i=0; $i <= $#pages; $i++ ) {
	$p = $pages[$i];
	$attr ="normal";
	if ($p->secpath() eq $site->secpath()) { $attr = "selected"; }
	$icon = $p->{ICON};
	if ($icon eq "STD") { $icon = "book"; }
	$icon = translateoldicons($icon);
	$cap = $p->{CAPTION};
	if ($icon ne "NONE") {
	  $icon = "button_" . $icon;
	  if (($p->{DISPLAY}) and ($site->{LEVEL}==$main::contentlevel)) {
	    # Knopf fuer Seite normal darstellen
	    $navi .= "  <li class=\"" . "i$attr$icon" . "\"><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p->link() . ".{EXT}\">" . $cap . "</a></li>\n";
	  } else {
	    if ($site->{LEVEL}!=$main::contentlevel) {
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
  ($p) = @_;
  
  my $r = "";
  
  if ($main::logofile eq "") {
    if ($main::mainsiteline eq 1) { $r = "<a class=\"MINTERLINK\" href=\"" . $p->linkpath() . "../index.html\">Hauptseite</a>"; }
  } else {
    $r = "<img style=\"\" src=\"" . $p->linkpath() . "../images/$main::logofile\"><br /><br />";
    if ($main::mainsiteline eq 1) {  $r .= "<a class=\"MINTERLINK\" href=\"" . $p->linkpath() . "../index.html\">Hauptseite</a>"; }
  }

  return $r;
}

# Liefert das Eingabecheckfeld als HTML-String
# Parameter: Das Seitenobjekt
sub getinputfield {
  ($p) = @_;

  my $s = "<div id=\"NINPUTFIELD\" data-bind=\"evalmathjax: ifobs\"></div><br />";
  $s .= "<textarea name=\"NUSERMESSAGE\" id=\"UFIDM\" rows=\"4\" style=\"background-color:\#CFDFDF; width:200px; overflow:auto; resize:none\"></textarea><br /><br />";
  return "<br />";
}

# Erzeugt das toccaption-div fuer die html-Seiten
# Parameter: Das Seitenobjekt
sub gettoccaption {
  ($p) = @_;
  my $c = "";

  # Nummer des gerade aktuellen Fachbereichs ermitteln
  my $pp = $site;
  
  # $site->{LEVEL} == 1 fuer Fachbereichsseite
  
  my $fsubi = -1;
  while ($pp->{LEVEL}!=($main::contentlevel-3)) {
    if ($pp->{LEVEL}==$main::contentlevel-2) { $fsubi = $pp->{ID}; }
    $pp = $pp->{PARENT};
  }
  my $fbi = $pp->{ID};
  my $attr = "";
  my $root = $p->{ROOT};
  my @pages1 = @{$root->{SUBPAGES}};
  my $n1 = $#pages1 + 1;

  $c .= "<div class=\"toccaption\">" .  getlogolink($p) . "</div>\n";

  # Einleitende Liste mit den Fachbereichen ohne Teile, aber NUR falls es mehr als einen gibt
  if ($n1 > 1) {
    $c .= "<ul class=\"level1a\">\n";
    my $i1;
    for ( $i1=0; $i1 < $n1; $i1++ ) {
      my $p1 = $pages1[$i1];
      if ($fbi == $p1->{ID}) {
	$attr = " class=\"bselected\"";
      } else {
	$attr = " class=\"bnotselected\"";
      }
      my $ff = $i1 + 1;
      my $ti = $p1->{TITLE};
      $ti =~ s/([12345] )(.*)/$2/ ;
      # if ($p1->{HELPSITE} eq 0) { $ti = "Fachbereich " . $ti; }
      $c .= "<li$attr><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p1->link() . ".{EXT}\">" . $ti . "</a>\n";
    }
    $c .= "</ul><br clear=\"all\"><br clear=\"all\"><br clear=\"all\">\n";
  }


  # FACHBEREICHE (chapters) -> MODULE (sections) -> subsections, level der ul ist identisch mit {LEVEL} der Page-Objekts


  # print "TOC: lvl1 hat $n1 Eintr√§ge\n";
  $c .= "<ul class=\"level1b\">\n";
  for ( $i1=0; $i1 < $n1; $i1++ ) {
    $p1 = $pages1[$i1];
    if ($p1->{ID}==$site->{ID}) { $attr = " class=\"selected\""; } else { $attr = " class=\"notselected\""; }
    $ff = $i1 + 1;

    if ($fbi == $p1->{ID}) {
      # lvl1 (=Fachbereich) ist aktuelles Dokument, nur aktuellen Fachbereich hier listen
      # Fachbereiche ohne Nummern anzeigen
      $ti = $p1->{TITLE};
      $ti =~ s/([12345] )(.*)/$2/ ;
      $c .= "<li$attr><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p1->link() . ".{EXT}\">" . $ti . "</a>\n";

      my @pages2 = @{$p1->{SUBPAGES}};
      my $i2;
      my $n2 = $#pages2 + 1;
      # print "TOC:   lvl2 hat $n2 Eintraege\n";
      if ($n2 > 0) {
	$c .= "  <ul class=\"level2\">\n";
	for ( $i2=0; $i2 < $n2; $i2++ ) {
	  my $p2 = $pages2[$i2];
    $ti = $p2->{TITLE};
    $ti =~ s/([0123456789]+?)[\.]([0123456789]+)(.*)/$2\.$3/ ;
	  if ($p2->{ID}==$site->{ID}) { $attr = " class=\"selected\""; } else { $attr = " class=\"notselected\""; }
	  $c .= "  <li$attr><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p2->link() . ".{EXT}\">" . $ti . "</a>\n";
    if ($fsubi ne -1) {
      if ($fsubi == $p2->{ID}) {
        my @pages3 = @{$p2->{SUBPAGES}};
        my $i3;
        my $n3 = $#pages3 + 1;
        # print "TOC:     lvl3 hat $n3 Eintraege\n";
        if ($n3 > 0) {
          $c .= "    <ul class=\"level3\">\n";
          for ( $i3=0; $i3 < $n3; $i3++ ) {
            my $p3 = $pages3[$i3];
            if (($site->{LEVEL}==$main::contentlevel) and ($p3->{ID}==$site->{PARENT}->{ID})) { $attr = " class=\"selected\""; } else { $attr = " class=\"notselected\""; }
            $c .= "    <li$attr><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p3->link() . ".{EXT}\">" . $p3->{NR}.$p3->{TITLE} . "</a></li>\n";
          }
          $c .= "    </ul>\n"; # level3-ul
        }
      } # if subsection id ist aktuell
    } # if subsection notwendig
    $c .= "  </li>\n";
	}
	$c .= "  </ul>\n"; # level2-ul
      }
      $c .= "</li>\n";
      # PDF zum Fachbereich anbieten falls PDFs aktiviert sind und wir nicht im Hilfebereich sind
      if (($main::dopdf eq 1) and ($site->{HELPSITE} eq 0)) {
        $c .= "<center><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . "../tree$ff.pdf\" target=\"_new\"><img src=\"" . $site->linkpath() . "../images/docpdf.png\" width=\"48px\" height=\"48px\" style=\"border: none\"></a><br clear=\"all\"><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . "../tree$ff.pdf\" target=\"_new\">Download PDF</a></center>";
      }
      $c .= "<br clear='all'/>"; 
    }
  }
  $c .= "</ul>"; # level1-ul


  # print "DEBUG: toccaption fuer Seite $site->{CAPTION} ist \n$c\n\n";

  return $c;
}

# Erzeugt das toccaption-div fuer die html-Seiten im Menu-Style
# Parameter: Das Seitenobjekt
sub gettoccaption_menustyle {
  ($p) = @_;
  my $c = "";

  # Nummer des gerade aktuellen Fachbereichs ermitteln
  my $pp = $site;
  
  # $site->{LEVEL} == 1 fuer Fachbereichsseite
  
  my $fsubi = -1;
  while ($pp->{LEVEL}!=($main::contentlevel-3)) {
    if ($pp->{LEVEL}==$main::contentlevel-2) { $fsubi = $pp->{ID}; }
    $pp = $pp->{PARENT};
  }
  my $fbi = $pp->{ID};
  my $attr = "";
  my $root = $p->{ROOT};
  my @pages1 = @{$root->{SUBPAGES}};
  my $n1 = $#pages1 + 1;

  # $c .= "<div class=\"toccaption\">" .  getlogolink($p) . "</div>\n"; # Alte Version mit Logo
  $c .= "<div class=\"toccaption\"></div>\n"; # Neue Version ohne Logo


  # FACHBEREICHE (chapters) -> MODULE (sections) -> subsections, level der ul ist identisch mit {LEVEL} der Page-Objekts


  
#   # Einleitende Liste mit den Fachbereichen ohne Teile, aber NUR falls es mehr als einen gibt
#   if ($n1 > 1) {
#     my $i1;
#     for ($i1=0; $i1 < $n1; $i1++ ) {
#       my $p1 = $pages1[$i1];
#       if ($fbi == $p1->{ID}) {
# 	$attr = " class=\"bselected\"";
#       } else {
# 	$attr = " class=\"bnotselected\"";
#       }
#       $attr = "";
#       my $ff = $i1 + 1;
#       my $ti = $p1->{TITLE};
#       $ti =~ s/([12345] )(.*)/$2/ ;
#       # if ($p1->{HELPSITE} eq 0) { $ti = "Fachbereich " . $ti; }
#       $c .= "<li$attr><a class=\"MINTERLINK\" href=\"" . $p->linkpath() . $p1->link() . ".{EXT}\">" . $ti . "</a></li>\n";
#     }
#   }
# 
  
  
    # Duenner TU9-Layout mit einzelnen Aufklappunterpunkten
    $c .= "<tocnavsymb><ul>";
    $c .= "<li><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . "../$main::chaptersite\" target=\"_new\"><div class=\"tocmintitle\">Kursinhalt</div></a>";
    $c .= "<div><ul>\n";
   
    my $i1 = 0; # eigentlich for-schleife, aber hier nur Kursinhalt
    $p1 = $pages1[$i1];
    if ($p1->{ID}==$site->{ID}) { $attr = " class=\"selected\""; } else { $attr = " class=\"notselected\""; }
    $attr = "";
    $ff = $i1 + 1;

    # Fachbereiche ohne Nummern anzeigen
    $ti = $p1->{TITLE};
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
        my $test = $site;
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
  
  # PDF zum Fachbereich anbieten falls PDFs aktiviert sind und wir nicht im Hilfebereich sind
  if (($main::dopdf eq 1) and ($site->{HELPSITE} eq 0)) {
     $c .= "<br /><tocnav><ul><li><a href=\"" . $site->linkpath() . "../tree$ff.pdf\"><img src=\"" . $site->linkpath() . "../images/docpdf.png\" style=\"border: none\"> Download</a></li></ul></tocnav>";
  }

  
  if ($main::isBeta eq 1) {
    $c .= "<br /><tocnav><ul><li><a class=\"MINTERLINK\" href=\"" . $site->linkpath() . "../$main::betasite\" target=\"_new\"><img src=\"" . $site->linkpath() . "../images/betab.png\" style=\"border: none\"> Beta-Version</a></li></ul></tocnav>";
  }

  # print "DEBUG: toccaption fuer Seite $site->{CAPTION} ist \n$c\n\n";

  return $c;
}

# Erzeugt das content-div fuer die html-Seiten
# Parameter: Das Seitenobjekt
sub getcontent {
  ($p) = @_;
  my $content = "";
  $content .= "<hr />\n{CONTENT}";
  $content .= "<hr />\n"; # </div> entfernt !
  $contentx = $p->gettext();
  $content =~ s/{CONTENT}/$contentx/;
  
  return $content;	
}


sub storelabels {
	my ($p) = @_;
  
	my (@subpages, $i, $divcontent, $lab, $sub, $sec, $ssec, $sssec, $type, $pl, $linkpath, $link);
	@subpages = @{$p->{SUBPAGES}};

	# print "storelabels called with \" $p->{TITLE}\"\n";

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
                    push @main::LabelStorage, [ $lab, $sub, $sec, $ssec, $sssec, $type, $pl];
                    # print "Added label $lab in FB $sub with number $sec.$ssec.$sssec and type $type, pagelink = $pl\n";

                    if (($type eq 4) and (($fb eq 3) or ($fb eq 4))) {
                        print "WARNING: Infobox $lab hat ein Label, aber im Fachbereich $fb keine Nummer\n";
                    }
                    
                    # if ($type eq 13) { print "Entry: $1\n"; }
		}

		$p->{TEXT} = $divcontent;
	}


	# print "There are $#subpages subpages\n";
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
	
	if ($p->{LEVEL} eq ($main::contentlevel-2)) {
	  print "Verarbeite Modul $p->{TITLE}\n";
	}

	if ($p->{LEVEL} eq ($main::contentlevel-3)) {
	  print "Verarbeite Fachbereich $p->{TITLE}\n";
	}

	#hole Unterseiten
	@subpages = @{$p->{SUBPAGES}};
	
	#falls die Seite ausgegeben werden soll
	if ($p->{DISPLAY}) {

		$p->logtext("Schreibe Ausgabe");

		$linkpath = "../" . $p->linkpath();
		$link = "mpl/" . $p->link();
		

		my $divhead = updatelinks(getheader(),$linkpath);
		my $divfooter = updatelinks(getfooter(),$linkpath);
		# Kein update erforderlich da $p verwendet wird:
		my $divnavi = getnavi($p); 
		#my $divtoccaption = gettoccaption($p);
		my $divtoccaption = gettoccaption_menustyle($p);
		my $divcontent = getcontent($p);

		# Makro {XSECTIONPREFIX} expandieren
		$secprefix = "";
		$q = $p->{PARENT};
		while ($q) {
		  if (($q->{LEVEL} > 0) and ($q->{TITLE} ne "")) {
		    $ti = $q->{TITLE};
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
		while ($divcontent =~ /<!-- mmref;;(.+?);;(.+?); \/\/-->/ ) {
		  # Expandiere MRef
		  # print "Expandiere Link $1\n";
		  $lab = $1; # Labelstring
		  $prefi = $2; # 0 -> Nur Nummer, 1 -> Mit Wortprefix (z.B. "Abbildung 3")
		  $href = "";
		  my $objtype = 0;
		  my $found = 0;
		  for ($i=0; $i <= $#main::LabelStorage; $i++ ) {
		    if ($main::LabelStorage[$i][0] eq $lab) {
		      $found = 1;
		      $href = $linkpath . $main::LabelStorage[$i][6];
		      $sec = $main::LabelStorage[$i][2];
		      $ssec = $main::LabelStorage[$i][3];
		      $refindex = $main::LabelStorage[$i][4];
		      $objtype = $main::LabelStorage[$i][5];
		      $fb = $main::LabelStorage[$i][1];
		    }
		  }

		  if ($found eq 0) {
		    print "ERROR: Label $lab wurde nicht in interner Labelliste gefunden\n";
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
            print "ERROR: Verweis $lab auf eine Infobox im Fachbereich $fb ohne Infonummern\n";
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
          print "ERROR: MRef konnte Objekttyp $objtype aus Label $lab nicht verarbeiten\n";
          $reftext = "";
        }
      }

      my $nrl = noregex($lab);
      
      if ($reftext ne "" ) {
        if ($prefi == 1) { $reftext = $ptext . " " . $reftext; }
        $divcontent =~ s/<!-- mmref;;$nrl;;$prefi; \/\/-->/<a class="MINTERLINK" href=\"$href\">$reftext<\/a>/g ;
      } else {
		    push @main::converrors, "ERROR: Konnte Label $lab nicht aufloesen!\n";
		    $divcontent =~ s/<!-- mmref;;$nrl;;$prefi; \/\/-->/(Verweis?)/g ;
		  }
		}

		while ($divcontent =~ /<!-- msref;;(.+?);;(.+?); \/\/-->/ ) {
		  # Expandiere MSRef
		  # print "Expandiere Link $1\n";
 		  $lab = $1;
 		  $txt = $2;
                  $nrl = noregex($lab);
		  $href = "";
		  for ($i=0; $i <= $#main::LabelStorage; $i++ ) {
		    if ($main::LabelStorage[$i][0] eq $lab) {
		      $href = $linkpath . $main::LabelStorage[$i][6];
		    }
		  }
  
                  my $nrt = noregex($txt);

                    if ($href ne "") {
		    $divcontent =~ s/<!-- msref;;$nrl;;$nrt; \/\/-->/<a class="MINTERLINK" href=\"$href\">$txt<\/a>/g ;
		  } else {
		    push @main::converrors, "ERROR: Konnte Label $lab mit Text $txt nicht aufloesen!\n";
		    $divcontent =~ s/<!-- msref;;$lab;;$nrt; \/\/-->/(Verweis?)/g ;
		  }
		}

		#MathPlayer-Ersetzungen fuer die Math-Tags
# 		$divcontent =~ s/<m/<m:m/g;
# 		$divcontent =~ s/<\/m/<\/m:m/g;

		# Kopf der Seite erzeugen
		my $text = updatelinks($main::templatempl, $linkpath);

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
		$text .= $main::templatefooter;
	      

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
                while ($pp->{LEVEL} != ($main::contentlevel-4)) {
                    if ($pp->{LEVEL} == ($main::contentlevel-2)) { $ssn = $pp->{NR}; }
                    if ($idstr eq "") {
                      $idstr = $pp->{POS};
                    } else {
                      $idstr = $pp->{POS} . "." . $idstr;
                    }
                    $pp = $pp->{PARENT};
                }

                my $uxid = "(unknown)";
  	        if ($text =~ m/<!-- mdeclaresiteuxidpost;;(.+?);; \/\/-->/s ) {
  	          $uxid = $1;
  	        } else {
  	          print("Site hat keine uxid: " . $idstr . "\n");
  	        }
  	        
  	        
  	        # Eigenen Dateinamen und Pfade als JS-Variable verfuegbar machen
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_ID = \"$idstr\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SITE_UXID = \"$uxid\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/SECTION_ID = $ssn;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var docName = \"$dname\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var fullName = \"$docname\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var fullNamePath = \"$fullpath\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;
                $text =~ s/\/\/ <JSCRIPTPRELOADTAG>/var linkPath = \"$linkpath\";\n\/\/ <JSCRIPTPRELOADTAG>/s ;

		#Ausgabe
		writefile($fullpath, $text);

		# Separate Exportdateien erzeugen
		my $fc = 0+@{$p->{EXPORTS}};
		# if ($fc != 0) { print "Generiere $fc zusaetzliche Exportdateien\n"; }
  	        for ($i=0; $i < $fc; $i++ ) {
  	          my $fname = ${$p->{EXPORTS}}[$i][0];
  	          writefile("$outputfolder/$link$fname", ${$p->{EXPORTS}}[$i][1]);
  	       }
  	       
		
		# print "OUTPUT: $link.html\n";
		
	} else {
		# display == false
		# print "schreibe nicht " . $p->{NR} . "\n";
		# print "NODISPLAY fuer $p->{TITLE}\n";
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
		$p->logtext("$prepend2 vor alle Links haengen.");
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
      # print "DEBUG: Kombination ,$1 im Dokument gefunden, Kontext ist \n$text\n\n";
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
		$p->logtext("verstecken");
		$p->{DISPLAY} = 0;
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
  
  @subpages = @{$p->{SUBPAGES}};
  my $toc = "Inhalte:<br />";

  # Inhaltsverzeichnis enthaelt die DIREKTEN Unterseiten der aktuellen Seite

  for ($i = 0; $i <= $#subpages; $i++) {
    $lk = $subpages[$i]->link() . ".{EXT}";
    $toc = $toc . "<a class=\"MINTERLINK\" href='" . $lk ."'>" . $subpages[$i]->{TITLE} . "</a><br />";
  }

  $text = $p->{TEXT};
  if ($text =~ s/<!-- toc -->/$toc/g) { $p->{TEXT} = $text; }

  #Rekursion auf Unterseiten
  for ( $i=0; $i <=$#subpages; $i++ ) {
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
      print "Hilfesektion wird eingerichtet\n";
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
		my $text = $p->{TEXT};
		
		#Suche alle Link-Anker
		@pagelinks = ($text =~ /<a [^>]*?name=".*?".*?>.*?<\/a>/sg);
		#itteriere ueber das Array und speichere die Seite, auf dem
		#der Link-Anker steht in einem Hash
		for ( $i=0; $i <=$#pagelinks; $i++ ) {
			$pagelinks[$i] =~ /name="(.*?)"/;
			$links{$1} = $p->link();
			$p->logtext("Link-Anker $1 gefunden");
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
		my $text = $p->{TEXT};
		my $linkpath = $p->linkpath();
		
		#itteriere ueber die im Hash gespeicherten Link-Anker
		foreach $link (keys %links) {
			$page = $links{$link};
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
	$rep_tab = 0;
	$rep_tab = ($text =~ s/<table border=\"1\">((.|\s)*?)<\/table>/replacetd($1)/eg);
	
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
# sub loadfile()
# liefert den Inhalt der Datei als String (mit Ausgabe auf Konsole)
# Parameter
# 	$file	Dateiname
sub loadfile {
	my($file, $text, $zeile, $rw);
	$file = $_[0];
	$text = "";
	$rw = open(LDFILE,$file) or die "\nFehler beim √ñffnen der Datei \"$file\": $!\n";
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


# 
# sub loadtemplates()
# laedt die standard-Templates und MathJax (vor dem MathPlayer)
# Parameter
# 	keine
sub loadtemplates {
  if ($main::config{localjax} eq 1) {
    print "Binde MathJax lokal ein, das Verzeichnis MathJax wird im html-Baum erzeugt!\n";
    loadtemplates_local();
    print "MathJax wird lokal adressiert\n";
  } else {
    if ($main::config{localjax} eq 0) {
      print "Binde MathJax ueber NetService (cdn 2.4) ein\n";
      loadtemplates_netservice();
    print "MathJax wird ueber Netservice adressiert\n";
    } else {
      print "ERROR: Unbekannte MathJax-Quelle: " . $main::config{localjax} . "\n";
    }
  }
}


# Momentan wird nur templatempl benutzt

sub getdoctype_oldhtml4 {
    print "Erstelle HTML-Dokumente nach DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1\n";
    my $doctype = <<DENDE;
<!DOCTYPE html PUBLIC
"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN"
"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">
DENDE
    return $doctype;
}

sub getdoctype {
    print "Erstelle Standard-HTML5-Dokumente ohne spezialisierte DTD\n";
    my $doctype = "<!DOCTYPE html>\n";
    return $doctype;
}

# ImageFonts von MathJax werden abgeschaltet, um die Verzeichnisse klein zu halten (erstmal nicht weil IE streikt)    (  imageFont: null)

# expires=0 verbietet caching der Seiten, sollte nur in beta-Version benutzt werden!

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
    if ($main::config{doscorm} eq 1) {
      $scotext = $main::scoheader;
    }
    $main::templatempl = $dt . $s . $main::templateheader . $scotext;
    # print "DT = $dt\n";
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
    if ($main::config{doscorm} eq 1) {
      $scotext = $main::scoheader;
    }
    $main::templatempl = $dt . $s . $main::templateheader . $scotext;
    # print "DT = $dt\n";
}


# 
# sub logtext()
# Schreibt Text die log-Datei
# Parameter
# 	$text	Text, der geschrieben werden soll
sub logtext {
	my ($text) = @_;
	$fh = File::Data->new($main::logfile);
	$fh->append($text . "\n");
	undef $fh;
}

# Bei PERL-Modules wird ein true-value als Ausgabe erwartet
1;
