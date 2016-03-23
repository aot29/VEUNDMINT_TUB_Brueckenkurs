 /* Macros in scanner etc. */

#ifdef TTH_GOLD
#define TTH_NAME "M"
#else
#define TTH_NAME "M Unregistered"
#endif
#define TTM_LAPSED "\nThe trial period of this unregistered copy of TtM is expired.\nPlease obtain a registered copy by following the links found at\nhttp://hutchinson.belmont.ma.us/tth/mml\n"
 /* Using mtables for eq number layout is poor in Amaya.
#define TTH_DISP1 "<br />\n\
    <math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n\
    <mtable border=\"1\" width=\"100%\"><mtr><mtd align=\"center\">\n<mrow>\n"
#define TTH_DISP2 "\n</mrow></mtd></mtr></mtable>\n    </math>\n<br />"
#define TTH_DISP3 "</mrow></mtd>\n<mtd width=\"1%\"><mrow>"
#define TTH_DISP4 "\n</mrow></mtd></mtr></mtable>\n    </math>\n<br />"
 */
 /* HTML numbering layout */
#define TTH_DISP1 "<br />\n<table width=\"100%\"><tr><td align=\"center\">\n\
    <math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n\
    <mstyle displaystyle=\"true\"><mrow>"
#define TTH_DISP2 "</mrow>\n    </mstyle></math>\n</td></tr></table>\n<br />"
#define TTH_DISP3 "</mrow>\n    </mstyle></math></td><td width=\"1\">\n    <math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n\
    <mstyle displaystyle=\"true\"><mrow>"
#define TTH_DISP4 "</mrow>\n    </mstyle></math>\n</td></tr></table>\n"
 /*
#define TTH_DISP1 "<br />\n<center><math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n<mrow>"
#define TTH_DISP2 "</mrow></math></center>\n<br />"
#define TTH_DISP3 "</mrow>\n<mrow>&emsp;&emsp;&emsp;&emsp;&emsp;"
#define TTH_DISP4 "</mrow></math></center>\n"
 */
#define TTH_DISP5 "</mrow></mtd><mtd columnalign=\"right\"><mrow>"
#define TTH_TSTY1 "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n<mrow>"
#define TTH_TSTY2 "</mrow></math>"
#define TTH_EQ1 ((tth_debug<2) ? "\n<mtable align=\"left\"><mtr><mtd columnalign=\"center\">\n" : "\n<mtable frame=\"dashed\" align=\"left\"><mtr><mtd columnalign=\"center\">\n")
 /* If the 80% does not work well with Amaya, then we should use: 
#define TTH_EQ3 TTH_EQ1
 */
 /*#define TTH_EQ3 ((tth_debug<2) ? "\n<mtable align=\"right\" width=\"80%\"><mtr><mtd columnalign=\"left\">\n" : "\n<mtable frame=\"dashed\" align=\"right\" width=\"80%\"><mtr><mtd columnalign=\"left\">\n")*/
#define TTH_EQ3 ((tth_debug<2) ? "\n<mtable align=\"right\" width=\"80%\">\n" : "\n<mtable frame=\"dashed\" align=\"right\" width=\"80%\">\n")
#define TTH_EQ2 "</mtable>\n"
#define TTH_EQ4 "</mtd></mtr></mtable>\n"

#define TTH_LEV1 ( "<mrow>")
#define TTH_LEV2 ( "</mrow>\n")
#define TTH_CHOOSE ( "<mfrac linethickness=\"0\">")
#define TTH_FRAC ( "<mfrac>")
#define TTH_DIV  ("" )
#define TTH_ATOP  ("" )
#define TTH_CELL1 ("\n")
#define TTH_CELL2 ( "</mfrac>\n")
 /*#define TTH_CELL3 "</mrow><mrow>\n"*/
#define TTH_CELL3 "\n"
#define TTH_CELL4 "</mrow><mrow>"
#define TTH_CELL5 ""  /* Null cell enclosure for matrix */
#define TTH_CELL_TAB (eqdepth ?"</mrow></mtd>":"</td>")
#define TTH_CELL_L "</td><td align=\"left\" class=\"cl\">"
#define TTH_CELL_R "</td><td align=\"right\" class=\"cr\">"
#define TTH_EQA1 "<mrow>"
#define TTH_EQA2 "</mrow>\n"
#define TTH_EQA3 ((eqalignlog) ? "</mtd><mtd columnalign=\"left\">\n" : "</mtd><mtd columnalign=\"center\">\n")
#define TTH_EQA4  ((eqalignlog) ? "</mtd><mtd columnalign=\"left\" columnspan=" : "</mtd><mtd columnalign=\"center\" columnspan=")
#define TTH_EQ5 "<mrow>"
#define TTH_NOALIGN "<mtr><mtd columnspan=\"6\">"
#define TTH_BR "</mrow>\n<mrow>"
#define TTH_BRN "<br />\n"
#define TTH_MSUBSUP "\n<msubsup>"
#define TTH_MSUBSUP2 "</mrow></msubsup>\n"
#define TTH_MLIMIT "\n<munderover>"
#define TTH_MUNOV2 "</mrow></munderover>"
#define TTH_SUP1 "<msup><mi></mi><mrow>"
#define TTH_SUP2 "</mrow></msup>\n"
#define TTH_SUB1 "<msub><mi></mi><mrow>"
#define TTH_SUB2 "</mrow></msub>\n"
#define TTH_MOVER "\n<mover>"
#define TTH_MUNDER "\n<munder>"
#define TTH_MSUP "\n<msup>"
#define TTH_MSUB "\n<msub>"
#define TTH_MOVER2 "</mover>\n"
#define TTH_MUNDER2 "</munder>\n"
#define TTH_MSUP2 "</msup>\n"
#define TTH_MSUB2 "</msub>\n"
 /* Use recursive strcats for an embedded string */
char mistring[TTH_CHARLEN]={0};
#define TTH_MI strcat(strcat(strcpy(mistring,"<mi"),tth_font_open[tth_push_depth]),">")
 /* #define TTH_MI   "<mi>" */
#define TTH_MIC  "</mi>"
#define TTH_MO strcat(strcat(strcpy(mistring,"<mo"),tth_font_open[tth_push_depth]),">")
 /* #define TTH_MO   "<mo>" */
#define TTH_MOC  "</mo>"
#define TTH_MN   "<mn>"
#define TTH_MNC  "</mn>"
 /*#define TTH_MONS   "<mo stretchy=\"false\">" */
#define TTH_MONS strcat(strcat(strcpy(mistring,"<mo"),tth_font_open[tth_push_depth])," stretchy=\"false\">")

#define TTH_EM1 ((eqdepth) ? "<mrow><mstyle fontstyle=\"italic\">" : "<em>")
#define TTH_EM2 ((eqdepth) ? "</mstyle></mrow>\n" : "</em>")
#define TTH_SMALLCAPS_FONT1 ((eqdepth) ? "<mstyle fontsize=\"-2\">" : "<span style=\"font-size:x-small\">")
#define TTH_SMALLCAPS_FONT2 ((eqdepth) ? "</mstyle>" : "</span>")
#define TTH_BOLDO " mathvariant=\"bold\"" 
#define TTH_BOLD1 ((eqdepth) ? "<mstyle mathvariant=\"bold\">" : "<b>")
#define TTH_BOLDC "\n"
#define TTH_BOLD2 ((eqdepth) ? "</mstyle>\n" : "</b>")
#define TTH_BLDITO " mathvariant=\"bold-italic\"" 
#define TTH_BLDIT1 ((eqdepth) ? "<mstyle mathvariant=\"bold-italic\">" : "<b><i>")
#define TTH_BLDITC "\n"
#define TTH_BLDIT2 ((eqdepth) ? "</mstyle>\n" : "</i></b>")
#define TTH_ITAL1 ((eqdepth) ? "<mstyle fontstyle=\"italic\">" : "<i>")
#define TTH_ITAL2 ((eqdepth) ? "</mstyle>\n" : "</i>")
#define TTH_ITALO " fontstyle=\"italic\""
#define TTH_ITALC "\n"
#define TTH_TT1 ((eqdepth) ? "<mstyle fontfamily=\"courier\" fontstyle=\"normal\">" : "<tt>")
#define TTH_TT2 ((eqdepth) ? "</mstyle>\n" : "</tt>")
#define TTH_TTO " fontfamily=\"courier\" fontstyle=\"normal\""
#define TTH_TTC "\n"
#define TTH_UNDL1 (eqdepth ? "<munder><mrow>" : "<u>")
#define TTH_UNDL2 (eqdepth ?"</mrow><mo>&#x0332;</mo></munder>" : "</u>")
 /*Underbar better*/
#define TTH_NORM1 ((eqdepth) ? " fontstyle=\"normal\"" : "")
#define TTH_NORM2 ((eqdepth) ? "\n" : "")
#define TTH_HELV1 ((eqdepth) ? "<mrow><mstyle fontfamily=\"helvetica\">" : \
		   "<span style=\"font-family:helvetica\">")
#define TTH_HELV2 ((eqdepth) ? "</mstyle></mrow>\n" : "</span>")
#define TTH_FONTCANCEL "</i></b></tt>"
#define TTH_STYLE ""

#define TTH_SIZESTYLE " <style type=\"text/css\">\n\
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
 </style>\n"


#define TTH_HGT 12

 /*
#define TTH_MATHI(chr) strcat(eqstr,TTH_MI);strcat(eqstr,chr);\
  strcat(eqstr,TTH_MIC);
#define TTH_MATHO(chr) strcat(eqstr,TTH_MO);strcat(eqstr,chr);\
  strcat(eqstr,TTH_MOC);
  Make all operators and identifiers potentially subsups in mathml*/
#define TTH_MATHI(chr) TTH_SUBDEFI(chr);
#define TTH_MATHO(chr) TTH_SUBDEFO(chr);
#define TTH_COMPLEX ( (strcspn(eqstr,"+-/") < strlen(eqstr)) || (strstr(eqstr,"\\pm") != NULL) || (strstr(eqstr,"\\mp") != NULL))
#define TTH_P_STYLE "<style type=\"text/css\">\n\
 div.p { margin-top: 7pt; }\n\
 span.roman {font-family: serif; font-style: normal; font-weight: normal;} \n\
</style>\n"
/*
#define TTH_PAR_ACTION if(tth_htmlstyle&2){\
 TTH_OUTPUT(closing); strcpy(closing,"</div>");\
 TTH_OUTPUT("\n<div class=\"p\">\n");}\
 else{TTH_OUTPUT("\n<p>\n");}horizmode=0;
*/
#define TTH_PAR_ACTION TTH_OUTPUT("\n<div class=\"p\"><!----></div>\n");horizmode=0;

#define TTH_CLEAR "<br clear=\"all\" />"
#define TTH_LIMITOP(chr) {\
   strcpy(eqlimited,chr);\
   if(levhgt[eqclose] == 1)levhgt[eqclose]=2;\
   yy_push_state(getsubp);}
#define TTH_OUTPUT(chr) if(eqdepth) strcat(eqstr,chr); else fprintf(tth_fdout,"%s",chr);
#define TTH_OUTPUTH(chr) if(eqdepth) strcat(eqstr,chr); else fprintf(tth_fdout,"%s",chr);horizmode=1;
#define TTH_CLOSEGROUP TTH_OUTPUT(closing)
#define TTH_SUBDEFER(chr)   mkkey(eqstr,eqstrs,&eqdepth);strcpy(eqstr,chr);\
  yy_push_state(getsubp);
#define TTH_SUBDEFI(chr)   mkkey(eqstr,eqstrs,&eqdepth);strcpy(eqstr,chr);\
  tth_enclose(TTH_MI,eqstr,TTH_MIC,eqstore);\
  yy_push_state(getsubp);  
#define TTH_SUBDEFO(chr)   mkkey(eqstr,eqstrs,&eqdepth);strcpy(eqstr,chr);\
  tth_enclose(TTH_MO,eqstr,TTH_MOC,eqstore);\
  yy_push_state(getsubp);   
#define TTH_SUBDEFONS(chr)   mkkey(eqstr,eqstrs,&eqdepth);strcpy(eqstr,chr);\
  tth_enclose(TTH_MONS,eqstr,TTH_MOC,eqstore);\
  yy_push_state(getsubp);   
#define TTH_BOXCODE "<mi>&#x25A1;</mi>"
#define TTH_HBAR "<mi>&hbar;</mi>"
#define TTH_TEXTBOX1 "\n<mtext>"
#define TTH_TEXTBOX2 "</mtext>\n"
 /* Tabular variable markup */
#define TTH_TRO (eqdepth ? "\n<mtr>" : "\n<tr>")
#define TTH_TRC (eqdepth ? "</mtr>" : "</tr>")
#define TTH_TABC (eqdepth ? "</mtable>\n" : "</table>\n")
#define TTH_TABB (eqdepth ? "<mtable rowlines=\"solid\" columnlines=\"solid\">" : "<table border=\"1\">")
#define TTH_TABO (eqdepth ? "<mtable>" : "<table>")
#define TTH_TRTD (eqdepth ? "<mtr><mtd></mtd></mtr>" : "<tr><td></td></tr>")
#define TTH_MULSTART (eqdepth ? "<mtd columnspan=\"%d\"%s>" : "<td colspan=\"%d\"%s>")
#define TTH_TABNOAL (eqdepth ? "\n<mtr><mtd columnspan=\"%d\">" : "\n<tr><td colspan=\"%d\">")
#define TTH_MULSPAN (eqdepth ? "<mtd columnalign=\"center\" columnspan=\"%d\">" : "<td align=\"center\" colspan=\"%d\">")
#define TTH_TDVAR (eqdepth ? "<mtd%s>" : "<td%s>")
#define TTH_TABRT (eqdepth ? " columnalign=\"right\"" : " align=\"right\"")
#define TTH_TABLT (eqdepth ? " columnalign=\"left\"" : " align=\"left\"")
#define TTH_TABCT (eqdepth ? " columnalign=\"center\"" :" align=\"center\"")

#define TTH_DOCML_TRANS "<!DOCTYPE html\
    PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN\"\n\
           \"http://www.w3.org/TR/MathML2/dtd/xhtml-math11-f.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\">"
#define TTH_DOCML "<?xml version=\"1.0\"?>\n<!DOCTYPE html\
    PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN\"\n\
           \"http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\">"
 /* This was the old doctype */
#define TTH_DOCTYPE4 "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"\n           \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<html>" 
#define TTH_DOCTYPE41 "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n        \"http://www.w3.org/TR/html4/loose.dtd\">\n<html>"
#define TTH_DOCXML "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n           \"DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">"
#define TTH_DOCTYPE (tth_htmlstyle&2 ? TTH_DOCML : TTH_DOCML_TRANS )

#define TTH_GENERATOR (!tth_htmlstyle&1 ? "\n<meta name=\"GENERATOR\" content=\"Tt%s %s\" />\n" : "\n<head>\n<meta name=\"GENERATOR\" content=\"Tt%s %s\" />\n")
#define TTH_ENCODING " "
#define TTH_MIME_HEAD "MIME-Version: 1.0\nContent-Type: MULTIPART/MIXED; BOUNDARY=\"1293058819-1213484446-873576042\"\n\n--1293058819-1213484446-873576042\nContent-Type: TEXT/HTML; charset=iso-8859-1; name=\"index.xml\"\n" /*sf*/
#define TTH_MIME_DIVIDE "\n--1293058819-1213484446-873576042\nContent-Type: TEXT/HTML; charset=US-ASCII; name=\"%s\"\n" /*sf*/


