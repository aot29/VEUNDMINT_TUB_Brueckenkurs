
 /*Macros in scanner etc. */
#ifdef TTH_GOLD
#define TTH_NAME "Hgold"
#else
#define TTH_NAME "H"
#endif

#define TTH_SYMBOLN  (tth_unicode ? "" : "<span style=\"font-family:symbol\">\n")
#define TTH_SYMBOL   (tth_unicode ? "" : "<span style=\"font-family:symbol\">")
#define TTH_SYMEND   (tth_unicode ? "" : "</span>")
#define TTH_SYMENDN  (tth_unicode ? "" : "</span\n>")
#define TTH_SYMPT(chr) (tth_unicode ? tth_symbol_point(chr) : chr)

#define TTH_DISP1 ((tth_debug < 2) ? "\n<br clear=\"all\" /><table border=\"0\" width=\"%d%%\"><tr><td>\n<table align=\"center\" cellspacing=\"0\"  cellpadding=\"2\"><tr><td nowrap=\"nowrap\" align=\"center\">\n" : "\n<br clear=\"all\" /><table border=\"1\" width=\"%d%%\"><tr><td>\n<table border=\"1\" align=\"center\"><tr><td nowrap=\"nowrap\" align=\"center\">\n" ) 
/* DISPE for equalign etc. Old version.*/
#define TTH_DISPE ((tth_debug < 2) ? "\n<br clear=\"all\" /><table border=\"0\" width=\"%d%%\"><tr><td>\n" : "\n<br clear=\"all\" /><table border=\"1\" width=\"%d%%\"><tr><td>\n" ) 
 /* New broken version 
   #define TTH_DISPE ((tth_debug < 2) ? "\n<br clear=\"all\" /><table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" width=\"%d%%\">\n" : "\n<br clear=\"all\" /><table border=\"1\" width=\"%d%%\">\n" ) */

#define TTH_DISP2 "</td></tr></table>\n</td></tr></table>\n"
#define TTH_DISP3 "</td></tr></table>\n</td><td width=\"1%\">"
#define TTH_DISP4 "</td></tr></table>\n"
#define TTH_DISP5 "\n</td><td width=\"1%\">"
#define TTH_DISP6 "</td></tr></table>\n" /* Instead of DISP4*/
#define TTH_TSTY1 ((tth_debug <2) ? "<br clear=\"all\" /><table border=\"0\" align=\"left\" cellspacing=\"0\" cellpadding=\"0\"><tr><td nowrap=\"nowrap\">" : "<br clear=\"all\" /><table border=\"1\" align=\"left\"><tr><td>" )
#define TTH_TSTY2 "\n</td></tr></table><br />"
#define TTH_EQ1 ((tth_debug<2) ? "<table border=\"0\" align=\"left\" cellspacing=\"0\" cellpadding=\"0\"><tr><td nowrap=\"nowrap\" align=\"center\">\n" : "<table border=\"1\" align=\"left\"><tr><td nowrap=\"nowrap\" align=\"center\">\n")
#define TTH_EQ3 ((tth_debug<2) ? "<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\">" :  "<table border=\"1\">" )
#define TTH_EQ2 "</table>\n"
#define TTH_EQ4 "</td></tr></table>\n"
#define TTH_EQ5 ((tth_debug<2) ? "<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr><td nowrap=\"nowrap\" align=\"center\">\n" : "<table border=\"1\"><tr><td nowrap=\"nowrap\" align=\"center\">\n")
#define TTH_EQ6 ((tth_debug<2) ? "<tr><td width=\"50%\"></td><td nowrap=\"nowrap\" align=\"right\">\n" :  "<tr><td width=\"50%\"></td><td nowrap=\"nowrap\" align=\"right\">\n" )
#define TTH_EQ7 "\n <tr><td width=\"50%%\"></td><td nowrap=\"nowrap\" align=\"%s\" colspan=\"%d\">"
#define TTH_EQ8 "</td><td width=\"50%\"></td><td width=\"1\" align=\"right\">"
#define TTH_EQ9 "</td><td width=\"50%\">"
#define TTH_EQ10 "\n <tr><td nowrap=\"nowrap\" align=\"%s\" colspan=\"%d\">"
#define TTH_EQ11 ((tth_debug<2)?"<table><tr><td nowrap=\"nowrap\" align=\"%s\" colspan=\"%d\">":"<table border=\"1\"><tr><td nowrap=\"nowrap\" align=\"%s\" colspan=\"%d\">")
#define TTH_CELL1 ((eqclose > tth_flev) ? ((levdelim[eqclose][0]||levdelim[eqclose+1][0]) ? "" : "["): ((levdelim[eqclose][0]) ? "" :  "</td><td nowrap=\"nowrap\" align=\"center\">\n") )
#define TTH_CELL2 ((eqclose > tth_flev) ? ((levdelim[eqclose+1][0]||levdelim[eqclose][0]) ? "" : "]"): ((levdelim[eqclose+1][0]) ? "" : "</td><td nowrap=\"nowrap\" align=\"center\">\n") )
  /* CELL2 and CELL3 need to be identical apart from the test. */
#define TTH_CELL3 "</td><td nowrap=\"nowrap\" align=\"center\">\n"
#define TTH_CELL4 "</td><td align=\"right\">"
 /*#define TTH_CELL_L "</td><td align=\"left\">"*/
#define TTH_CELL_TAB (eqdepth ?"</td></tr></table></td>":"</td>")
#define TTH_CELL_L "</td><td align=\"left\" class=\"cl\">"
#define TTH_CELL_R "</td><td align=\"right\" class=\"cr\">"
#define TTH_CELL5 "</td><td nowrap=\"nowrap\">"
#define TTH_CELL_START "</td><td"
#define TTH_LEV1 ((eqclose > tth_flev) ? "(": ((tth_debug<2) ? "<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr><td nowrap=\"nowrap\" align=\"center\">\n": "<table border=\"1\"><tr><td nowrap=\"nowrap\" align=\"center\">\n") )
#define TTH_LEV2 ((eqclose > tth_flev) ? ")": "</td></tr></table>")

#define TTH_EQA1 ((tth_debug<2) ? ((eqalignlog) ? "<table border=\"0\" cellspacing=\"0\" cellpadding=\"2\"><tr><td nowrap=\"nowrap\" align=\"left\">\n":"<table border=\"0\" cellspacing=\"0\" cellpadding=\"2\"><tr><td nowrap=\"nowrap\" align=\"center\">\n") : ((eqalignlog) ? "<table border=\"1\"><tr><td nowrap=\"nowrap\" align=\"left\">\n":"<table border=\"1\"><tr><td nowrap=\"nowrap\" align=\"center\">\n"))
#define TTH_EQA2  "</td></tr></table>"
#define TTH_EQA3 ((eqalignlog) ? "</td><td nowrap=\"nowrap\" align=\"left\">\n" : "</td><td nowrap=\"nowrap\" align=\"center\">\n")
#define TTH_EQA4  ((eqalignlog) ? "</td><td nowrap=\"nowrap\" align=\"left\" colspan=" : "</td><td nowrap=\"nowrap\" align=\"center\" colspan=")
   /* The leading \n is vital in tth_istyle. */
#define TTH_DIV  ((eqclose > tth_flev) ? "/":(tth_istyle&1 ? "\n<div class=\"hrcomp\"><hr noshade=\"noshade\" size=\"1\"/></div>":"<hr noshade=\"noshade\" size=\"1\" />") )

#define TTH_ATOP  ((eqclose > tth_flev) ? " || ":"<br />\n" )
#define TTH_NULL_BOTTOM ((eqclose > tth_flev) ? "":"&nbsp;<br />" )
#define TTH_NOALIGN "<tr><td nowrap=\"nowrap\" colspan=6>"
#define TTH_BR "<br />"
#define TTH_BRN "<br />\n"
#define TTH_SUP1 "<sup>"
#define TTH_SUP2 "</sup>"
#define TTH_SUB1 "<sub>"
#define TTH_SUB2 "</sub>"
#define TTH_OINT     strcat(eqstr,"</td><td align=\"center\">");\
    strcat(eqstr,TTH_SYMBOL);chr1[0]=243;strcat(eqstr,TTH_SYMPT(chr1));\
    strcat(eqstr,"<br />(");chr1[0]=231;strcat(eqstr,TTH_SYMPT(chr1));\
    strcat(eqstr,")<br />");chr1[0]=245;strcat(eqstr,TTH_SYMPT(chr1));\
    strcat(eqstr,TTH_SYMEND);strcat(eqstr,"<br />");strcat(eqstr,"</td><td>");\
    if(levhgt[eqclose] == 1)levhgt[eqclose]=2;hgt=3;
 /* These ought to be a good way of closing up over/under braces etc
   but layout is too broken to give good vertical centering then
#define TTH_OBR (tth_istyle&1 ? "\n<div class=\"hrcomp\"><hr /></div>" : "<hr />")
#define TTH_OBRB (tth_istyle&1 ? "\n<div class=\"hrcomp\"><br /></div>" : "<br />")
 */
#define TTH_OBR "<hr />"
#define TTH_OBRB "<br />"
#define TTH_EM1 "<em>"
#define TTH_EM2 "</em>"
#define TTH_SMALLCAPS_FONT1 "<span style=\"font-size:x-small\">"
#define TTH_SMALLCAPS_FONT2 "</span>"
#define TTH_BOLDO "<b>"
#define TTH_BOLD1 "<b>"
#define TTH_BOLDC "</b>"
#define TTH_BOLD2 "</b>"
#define TTH_BLDITO "<b><i>"
#define TTH_BLDIT1 "<b><i>"
#define TTH_BLDITC "</i></b>"
#define TTH_BLDIT2 "</i></b>"
#define TTH_ITAL1 "<i>"
#define TTH_ITAL2 "</i>"
#define TTH_ITALO "<i>"
#define TTH_ITALC "</i>"
#define TTH_TT1 "<tt>"
#define TTH_TT2 "</tt>"
#define TTH_TTO "<tt>"
#define TTH_TTC "</tt>"
#define TTH_UNDL1 "<u>"
#define TTH_UNDL2 "</u>"
#define TTH_NORM1 (tth_istyle&1 ? "<span class=\"roman\">" : "")
#define TTH_NORM2 (tth_istyle&1 ? "</span>" : "")
#define TTH_HELV1 "<span style=\"font-family:helvetica\">"
#define TTH_HELV2 "</span>"
/* #define TTH_FONTCANCEL "</i></b></tt>" Trying a less drastic approach */
#define TTH_FONTCANCEL "</b>"
#define TTH_DAG "&#8224;"
#define TTH_DDAG "&#8225;"

#define TTH_OA1 (tth_istyle&1 ? "<div class=\"comp\">" : "")
#define TTH_OA2 (tth_istyle&1 ? "<br /></div>\n<div class=\"norm\">" : "<br />")
/* The comb bottom style is messed up by differences between NS and gecko.
   The margin bottom does not seem to matter. Even uncompressed accents
   are misaligned in Gecko. This is a font scaling problem.*/
#define TTH_OA3 (tth_istyle&1 ? "</div>\n<div class=\"comb\">&nbsp;</div>\n" : "&nbsp;<br />")
#define TTH_OA4 (tth_istyle&1 ? "\n<div class=\"comb\">&nbsp;</div>\n" :"&nbsp;<br />")
#define TTH_OA5 (tth_istyle&1 ? "\n<div class=\"norm\">" : "")
#define TTH_STYLE ((tth_debug&2) ? " <style type=\"text/css\"><!--\n\
 td div.comp { margin-top: -0.6ex; margin-bottom: -1ex; background: yellow;}\n\
 td div.comb { margin-top: -0.7ex; margin-bottom: -.6ex; background: yellow;}\n\
 td div.hrcomp { line-height: 0.9; margin-top: -0.8ex; margin-bottom: -1ex; background: yellow;}\n\
 td div.norm {line-height:normal; background: cyan;} \n\
 span.roman {font-family: serif; font-style: normal; font-weight: normal;} \n\
 span.overacc2 {position: relative;  left: .8em; top: -1.2ex;}\n\
 span.overacc1 {position: relative;  left: .6em; top: -1.2ex;}  --></style>\n"\
 : " <style type=\"text/css\"><!--\n\
 td div.comp { margin-top: -0.6ex; margin-bottom: -1ex;}\n\
 td div.comb { margin-top: -0.6ex; margin-bottom: -.6ex;}\n\
 td div.hrcomp { line-height: 0.9; margin-top: -0.8ex; margin-bottom: -1ex;}\n\
 td div.norm {line-height:normal;}\n\
 span.roman {font-family: serif; font-style: normal; font-weight: normal;} \n\
 span.overacc2 {position: relative;  left: .8em; top: -1.2ex;}\n\
 span.overacc1 {position: relative;  left: .6em; top: -1.2ex;} --></style>\n")

#define TTH_SIZESTYLE " <style type=\"text/css\"><!--\n\
 .tiny {font-size:30%;}\n\
 .scriptsize {font-size:xx-small;}\n\
 .footnotesize {font-size:x-small;}\n\
 .smaller {font-size:smaller;}\n\
 .small {font-size:small;}\n\
 .normalsize {font-size:medium;}\n\
 .large {font-size:large;}\n\
 .larger {font-size:x-large;}\n\
 .largerstill {font-size:xx-large;}\n\
 .huge {font-size:300%;}\n\
 --></style>\n"


#define TTH_MATHS(chr) strcat(eqstr,TTH_SYMBOL);\
 strcat(eqstr,TTH_SYMPT(chr));   strcat(eqstr,TTH_SYMENDN); 
#define TTH_MATHI(icr) chr1[0]=icr;TTH_MATHS(chr1);
#define TTH_MATHC(chr) strcat(eqstr,chr);
#define TTH_COMPLEX ( (strcspn(eqstr,"&+-/") < strlen(eqstr)) || (strstr(eqstr,"\\pm") != NULL) || (strstr(eqstr,"\\mp") != NULL))
 /*
#define TTH_P_STYLE " <style type=\"text/css\"><!-- div.p { margin-top: 7pt;}--></style>\n"
 */
#define TTH_P_STYLE " <style type=\"text/css\"> div.p { margin-top: 7pt;}</style>\n"
/*  #define TTH_PAR_ACTION if(tth_htmlstyle&2){\ */
/*   TTH_OUTPUT("\n<div class=\"p\"></div>\n");}\ */
/*   else{TTH_OUTPUT("\n<p>\n");}horizmode=0; */
/* The comment is to fool tidy into thinking it's not empty*/
#define TTH_PAR_ACTION TTH_OUTPUT("\n<div class=\"p\"><!----></div>\n");horizmode=0;

#define TTH_CLEAR "<br clear=\"all\" />"
#define TTH_LIMITOP(icr) chr1[0]=icr;if(eqclose >tth_flev-1){TTH_MATHI(icr);}else{\
   oa_removes=0;\
   strcat(eqstr,TTH_CELL3);\
   strcpy(eqlimited,chr1);\
   if(levhgt[eqclose] == 1)levhgt[eqclose]=2;\
   if(bracecount){\
    fprintf(stderr,"****Internal Error! Bracecount nonzero in limitop.\n");\
    bracecount=0;}\
   yy_push_state(getsubp);}
#define TTH_OUTPUT(chr) if(eqdepth){strcat(eqstr,chr);}else{fprintf(tth_fdout,"%s",chr);}
#define TTH_OUTPUTH(chr) if(eqdepth){strcat(eqstr,chr);}else{fprintf(tth_fdout,"%s",chr);}horizmode=1;
#define TTH_CLOSEGROUP TTH_OUTPUT(closing)
#define TTH_HGT 12
#define TTH_BOXCODE "<span style=\"font-size:x-small\"><sup>[<u>&#175;</u>]</sup></span>"
#define TTH_HBAR "&#295;"
#define TTH_TEXTBOX1 ""
#define TTH_TEXTBOX2 ""
 /* Tabular variable markup */
#define TTH_TRO "\n<tr>"
#define TTH_TRC "</tr>"
#define TTH_TABC "</table>\n"
#define TTH_TABB "<table border=\"1\">"
#define TTH_TABO "<table>"
#define TTH_TRTD "<tr><td></td></tr>"
#define TTH_MULSTART "<td colspan=\"%d\"%s>"
#define TTH_TABNOAL "\n<tr><td colspan=\"%d\">"
#define TTH_TABNOAL2 "\n</tr></td>"
#define TTH_MULSPAN "<td align=\"center\" colspan=\"%d\">"
#define TTH_TDVAR "<td%s>"
#define TTH_TABRT " align=\"right\""
#define TTH_TABLT " align=\"left\""
#define TTH_TABCT " align=\"center\""

 /* This was the old doctype. Reports are that on Windows gecko recognizes
    symbol fonts for a doctype of 40 but not 401. So keep to 40*/
#define TTH_DOCTYPE4 "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"\n           \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<html>" 
#define TTH_DOCTYPE41 "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n        \"http://www.w3.org/TR/html4/loose.dtd\">\n<html>"
#define TTH_DOCXML "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n           \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">"
#define TTH_DOCTYPE (tth_htmlstyle&2 ? TTH_DOCXML : TTH_DOCTYPE4 )
#define TTH_GENERATOR (!(tth_htmlstyle&3) ? "\n<meta name=\"GENERATOR\" content=\"Tt%s %s\">\n" : ( tth_htmlstyle&2 ? "\n<head>\n<meta name=\"GENERATOR\" content=\"Tt%s %s\" />\n" : "\n<head>\n<meta name=\"GENERATOR\" content=\"Tt%s %s\">\n") )
#define TTH_ENCODING (!tth_unicode ? (tth_htmlstyle&2 ?"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\" />\n":"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">\n") : "")



#define TTH_MIME_HEAD "MIME-Version: 1.0\nContent-Type: MULTIPART/MIXED; BOUNDARY=\"1293058819-1213484446-873576042\"\n\n--1293058819-1213484446-873576042\nContent-Type: TEXT/HTML; charset=iso-8859-1; name=\"index.html\"\n\n" /*sf*/
#define TTH_MIME_DIVIDE "\n--1293058819-1213484446-873576042\nContent-Type: TEXT/HTML; charset=iso-8859-1; name=\"%s\"\n\n" /*sf*/

