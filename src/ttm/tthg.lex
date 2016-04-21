/* TtH flex file to convert plain TeX and LaTeX to HTML.
 	 (c) Ian Hutchinson, 1997-2011.

 Released under the terms of the GPL2. See license.txt

 This file needs to be turned into a C program using flex
 And then compiled into the tth executable using a C compiler.
   */
%{
#define TTH_VERSION "4.05"
  /*#define TTH_GOLD "gold" no longer a distinction*/  /*sf*/
#define TTH_HEAD "HEAD"  /*sf*/
char tth_DOC[]="\n\
                Version XXXX (c)1997-2011 Ian Hutchinson\n\
            TtH (TeX-to-HTML) translates TeX into HTML.\n\n\
The program is a filter by default: it reads from stdin and writes to stdout.\n\
But a non-switch argument specifies the file[.tex] to translate to file.html.\n\
Diagnostics concerning unknown or untranslated constructs are sent to stderr.\n\n\
  Obtain USAGE & switch information by:   tth -?\n\
  Obtain QUALIFICATIONS by:               tth -?q\n\n\
TtH may be used and distributed under the terms of the GPL version 2.\n";
char tth_DOCQ[]="\n\
TeX including mathematics; Plain TeX; LaTeX (2e). \n\
Limitations and special usages:\n\
 \\input searches TTHINPUTS not TEXINPUTS. Counter operations are global.\n\
 \\catcode changes, tabbing environment, \\usepackage: not supported.\n\
 \\epsfbox{file.eps} links or inlines the figure file, depending on -e switch.\n\
 \\special{html:stuff} inserts HTML stuff. \\iftth is always true.\n\
 \\href{URL}{anchor text} inserts a hypertext anchor pointing to URL.\n\
 %%tth: ... passes the rest of the comment to TtH (not TeX) for parsing\n\
\n\
";
char tth_USAGE[]="\n\
USAGE: tth [-a -c ...] [<]file.tex [>file.html] [2>err]\n\
 A non-switch argument specifies the input file and the implied output file.\n\
   -h print help. -? print this usage.\n\
   -a enable automatic calls of LaTeX: if no aux file exists, attempt to call.\n\
               picture environment conversion using latex2gif. Default omit.\n\
   -c prefix header \"Content-type: text/HTML\" (for direct web serving).\n\
   -d disable definitions with delimited arguments. Default enable.\n\
   -e? epsfbox handling: -e1 convert to png/gif using user-supplied ps2png/gif.\n\
       -e2 convert and include inline. -e0 (default) no conversion, just ref. \n\
   -f? limit built-up fraction nesting in display eqns to ?(0-9). Default 5.\n\
   -g remove, don\'t guess intent of, \\font commands. Default guess font/size.\n\
   -i use italic font for equations (like TeX). Default roman.\n\
   -j? use index page length ?. Default 20 lines. -j single column.\n\
   -Lfile tell tth the base file (no extension) for LaTeX auxiliary input,\n\
      enables LaTeX commands (e.g. \\frac) without a \\documentclass line.\n\
   -n? HTML title format control. 0 raw. 1 expand macros. 2 expand eqns. \n\
   -ppath specify additional directories (path) to search for input files.\n\
   -r raw HTML output (omit header and tail) for inclusion in other files.\n\
   -t display built-up items in textstyle equations. Default in-line.\n\
   -u unicode character encoding. (Default iso-8859-1).\n\
   -w? HTML writing style. Default no head/body tags. -w -w0 no title.\n\
     -w1 single title only, head/body tags. -w2 XHTML.\n\
   -y? equation style: bit 1 compress vertically; bit 2 inline overaccents.\n\
   -xmakeindxcmd  specify command for making index. Default \"makeindex\"\n\
   -v give verbose commentary. -V even more verbose (for debugging).\n";
char *tth_debughelp="\n\
Debugging mask: usage tth -vn with n the sum of:\n\
Bit 1.   1 Standard verbose messages.\n\
Bit 2.   2 Equation code.\n\
Bit 3.   4 Definitions, counters, countersetting.\n\
Bit 4.   8 Macro expansions. Delimited argument matching.\n\
Bit 5.   16 Stack levels, brace counts etc.\n\
Bit 6.   32 Tabular, Figures and Pictures.\n\
Bit 7.   64 Comments.\n\
Bit 8.   128 Auxiliary Files.\n\
Bit 9.   256 Cross-references.\n\
Bit 10.  512 Built-ins, codes.\n\
Bit 11.  1024 Conditionals, dimensions.\n\
Bit 12.  2048 Fonts\n\
Bit 13.  4096 Termination.\n\
Bit 14.  8192 Line-end diagnosis.\n\
Bit 16. 32768 Silence unknown command warnings.\n\
 -V= 2048+256+4+2+1\n";


#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h> /* For toupper */
#include <time.h>
#define GET_DIMEN {yy_push_state(lookforunit);yy_push_state(lookfornum);\
                   *argchar=0;}
#define TTH_MAXDEPTH 30
#define TTH_CHARLEN 500
#define TTH_DLEN 20000
#define TTH_34DLEN 72000
#define TTH_FONTLEN 200
#ifdef __vms
#define  SUCCESS 1
#define RMCMD "del"
#define RMTERM ";"
#define PATH_SEP ","
#define DIR_SEP ""
#else
#define  SUCCESS 0
#ifdef MSDOS
#define RMCMD "del"
#define RMTERM ""
#define PATH_SEP ";"
#define DIR_SEP "\\"
#else 
#define RMCMD "rm"
#define RMTERM ""
#define PATH_SEP ":"
#define DIR_SEP "/"
#endif
#endif

 /*#define TTH_EXIT(level) exit(level)*/
#define TTH_EXIT(level) return level;
#define TTH_FATAL(level) yy_push_state(error);tth_ercnt=-abs(level);tth_erlev=level;

 /* Silence warnings */
#define YY_NO_TOP_STATE

    /* lex Globals */
void tth_push(),tth_pop();
char* tth_symbol_point();
int tth_root_len[TTH_MAXDEPTH] ={0};
char tth_root_index[TTH_MAXDEPTH][TTH_CHARLEN]={{0}};
int tth_root_depth=0;
int tth_num_lines = 1;
int tth_push_depth=0;
char tth_closures[TTH_MAXDEPTH][TTH_CHARLEN];
char tth_texclose[TTH_MAXDEPTH][TTH_CHARLEN]={{0}};
char tth_font_open[TTH_MAXDEPTH][TTH_CHARLEN]={{0}};
char tth_font_close[TTH_MAXDEPTH][TTH_CHARLEN]={{0}};
char tth_fonto_def[TTH_CHARLEN]={0};
char tth_fontc_def[TTH_CHARLEN]={0};
int tth_key[TTH_MAXDEPTH];
int tth_debug = 0;
int tth_verb = 0;
int tth_delimdef=1;
int tth_mathitalic=1;
int tth_flev0=5;
int tth_flev=5;
int tth_multinum=1;
int tth_autopic=0;
int tth_istyle=3;
int tth_htmlstyle=0;
int tth_unicode=2;
int tth_indexpage=20;
int tth_allowinput=1;
int tth_titlestate=4;
int tth_tagpurge=0;

#ifdef MSDOS
 /* Define the size of djgpp stack*/
unsigned _stklen = 1048576;  /* need a larger stack (1Mb) */
#endif

 /*Global string pointer and length*/
#define MAX_INCLUDE_DEPTH 100
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
YY_BUFFER_STATE halbuff;
FILE *tth_inputfile=0;
FILE *tth_indexfile=0;
FILE *tth_indexstyle=0;
FILE *tth_picfile=0;
FILE *tth_fdout=0;
int tth_stack_ptr = 0;
int tth_ercnt=0;
int tth_erlev=0;
int tth_epsftype=0;
int tth_fontguess=1;
int tth_splitfile=0; /*sf*/
int tth_inlinefrac=0;
char tth_latex_file[TTH_CHARLEN]={0}; /* base name of latex files. */
char tth_index_cmd[TTH_CHARLEN]={0}; /* Makeindex command line. */
char tth_texinput_path[TTH_CHARLEN]={0};
int tth_LaTeX=0;
char *tth_latex_builtins = "\\def\\frac#1#2{{{#1}\\over{#2}}}\
\\def\\label#1{\\tthlabel}\
\\def\\newlabel#1#2{\\tthnewlabel}\
\\def\\ref#1{\\tthref}\
\\def\\pageref#1{\\tthpageref}\
\\def\\index{\\tthgpindex}\
\\def\\see#1#2{{\\it\\seename} #1}\
\\tthcountinit\
\\newcount\\footnote\
\\newcounter{chapter}\
\\newcounter{section}[chapter]\
\\newcounter{subsection}[section]\
\\renewcommand{\\thesubsection}{\\thesection.\\arabic{subsection}}\
\\newcounter{subsubsection}[subsection]\
\\renewcommand{\\thesubsubsection}{\\thesubsection.\\arabic{subsubsection}}\
\\newcounter{equation}[chapter]\
\\newcounter{figure}[chapter]\
\\newcounter{table}[chapter]\
\\newcounter{part}\
\\newcounter{secnumdepth}\
\\setcounter{secnumdepth}{3}\
\\def\\newtheorem#1#2{\\newenvironment{#1}{\\par\\stepcounter{#1}\
  \\textbf{#2 \\arabic{#1}}\\bgroup \\em}{\\par\\egroup}\\newcounter{#1}}\
\\def\\tthenclose#1#2#3{#1{#3}#2}\
\\def\\prefacename{Preface}\
\\def\\refname{References}\
\\def\\abstractname{Abstract}\
\\def\\bibname{Bibliography}\
\\def\\chaptername{Chapter}\
\\def\\appendixname{Appendix}\
\\def\\contentsname{Contents}\
\\def\\listfigurename{List of Figures}\
\\def\\listtablename{List of Tables}\
\\def\\indexname{Index}\
\\def\\figurename{Figure}\
\\def\\tablename{Table}\
\\def\\partname{Part}\
\\def\\enclname{encl}\
\\def\\ccname{cc}\
\\def\\headtoname{To}\
\\def\\pagename{Page}\
\\def\\seename{see}\
\\def\\alsoname{see also}\
\\def\\proofname{Proof}\
\\def\\newfont#1#2{\\font#1 #2 }\
\\def\\thanks#1{\\footnote{#1}}\
\\def\\bibcite{\\gdef}\n";
char *tth_latex_builtins2=
"\\newcommand{\\part}[1][]{\\tthpart}\
\\newcommand{\\chapter}[1][]{\\tthchapter}\
\\newcommand{\\section}[1][]{\\tthsection}\
\\newcommand{\\subsection}[1][]{\\tthsubsection}\
\\newcommand{\\subsubsection}[1][]{\\tthsubsubsection}\
\\newcounter{paragraph}[subsubsection]\
\\renewcommand{\\theparagraph}{\\thesubsubsection.\\arabic{paragraph}}\
\\newcommand{\\paragraph}[1][]{\\tthparagraph}\
\\newcounter{subparagraph}[paragraph]\
\\renewcommand{\\thesubparagraph}{\\theparagraph.\\arabic{subparagraph}}\
\\newcommand{\\subparagraph}[1][]{\\tthsubparagraph}\
\\newcommand{\\author}[2][]{\\centerheader{3}{#2}{align=\"center\"}}\
\\newcommand{\\date}[2][]{\\centerheader{3}{#2}{align=\"center\"}}\
\\newcommand{\\address}[2][]{\\centerheader{3}{#2}{align=\"center\"}}\
\\newcommand{\\parbox}[2][]{\\hbox to #2}\
\\def\\symbol#1{\\char#1}\
\\def\\text{\\textrm}\
\\def\\definecolor#1#2#3{\\def{#1}{{#3}}}\
\\def\\setlength#1#2{#1=#2}\
\\def\\columnwidth{\\hsize}\
\\newcommand\\caption[1][]{\\tthcaption}\
\\newenvironment{longtable}\
{\\begin{table}\\begin{center}\
 \\def\\noalcen##1{\\noalign{\\centering ##1}\\stepcounter{table}}\
 \\renewcommand\\caption[2][]{\\ifx ##2* \\noalcen\
 \\else\\noalign{\\tthcaption{##2}}\\fi}\
 \\def\\endhead{\\\\}\\def\\endfirsthead{\\\\}\
 \\def\\endfoot{\\\\}\\def\\endlastfoot{\\\\}\
 \\def\\kill{\\\\}\
 \\begin{tabular}}\
 {\\end{tabular}\\end{center}\\end{table}}\
\\def\\tthciteform{}\\def\\tthbibform{[}\\def\\tthbibcb{]}\
\\def\\tthciteob{[}\\def\\tthcitepb{,}\\def\\tthcitefi{,}\\def\\tthcitecb{]}\
\\newcommand\\citet[2][]{{\\def\\tthciteform##1##2##3##4{##3 [##2]}\
\\def\\tthciteob{}\\def\\tthcitecb{}\\cite[#1]{#2}}}\
\\newcommand\\citep[2][]{{\\def\\tthciteform##1##2##3##4{##3, ##2}\
\\def\\tthciteob{[}\\cite[#1]{#2}}}\
\\newcommand\\marginpar[2][]{\\special{html:<table align=\"right\" border=\
\"border\"><tr><td align=\"right\">}#2\\special{html:</td></tr></table>}}\
\\def\\newsavebox{\\newbox}\n";
char *tth_latex_builtins3=
"\\def\\tthsplittail{\
\\special{html:\n<hr /><table width=\"100\\%\"><tr><td>\n\
 <a href=\"index.html\">HEAD</a></td><td align=\"right\">\n\
<a href=\"}\\tthfilenext\\special{html:\">}NEXT\n\
\\special{html:</a></td></tr></table>\n</div></body></html>}}\n\
\\def\\tthsplittop{\
\\special{html:<table width=\"100\\%\"><tr><td>\n\
 <a href=\"index.html\">HEAD</a></td><td align=\"right\">\n\
 <a href=\"}\\tthfilechar\\special{html:\">}PREVIOUS\n\
\\special{html:</a></td></tr></table>}}\n\
\\def\\glossary\\index\n\
\\newenvironment{floatingfigure}{\\special{html:\
<br clear=\"all\" />\n\
<table border=\"0\" align=\"left\" width=\"20\\%\"><tr><td>}\
\\begin{figure}\\wd}{\\special{html:</td></tr></table>}\\end{figure}}\n\
\\def\\tabularnewline{\\\\}\n\
\\def\\AtEndDocument#1{}";
char *tth_builtins = "\\def\\bye{\\vfill\\eject\\end }\
\\def\\cal{\\sffamily\\it }\
\\def\\phantom#1{\\tthphantom}\
\\let\\hphantom=\\phantom\
\\def\\root#1\\of#2{\\sqrt[#1]{#2}}\
\\def\\H#1{\\\"#1}\\def\\b#1{\\underline{#1}}\
\\def\\v{\\noexpand\\v}\\def\\u{\\noexpand\\u}\
\\def\\t{\\noexpand\\t}\\def\\d{\\noexpand\\d}\
\\def\\c#1{\\noexpand\\c #1}\
\\def\\url{\\tthurl}\
\\def\\hyperlink#1#2{\\href{\\##1}{#2}}\
\\def\\hypertarget#1#2{\\special{html:<a id=\"#1\">}#2\\special{html:</a>}}\
\\def\\proclaim #1.#2\\par{\\medskip{\\bf#1.\\ }{\\sl#2\\par}}\
\\def\\newdimen#1{\\def#1{\\tthdimen#1 0\\tth_hsize}}\
\\def\\hsize{\\tthdimen\\hsize 1\\tth_hsize}\
\\def\\ensuremath#1{$#1$}\
\\def\\TeX{\\ensuremath{\\rm T_EX}}\
\\def\\LaTeX{\\ensuremath{\\rm L^AT_EX}}\
\\def\\buildrel#1\\over#2{\\mathop{#2}^{#1}}\
\\newcount\\tthdummy\
\\def\\uppercase#1{{\\tth_uppercase #1}}\
\\def\\newbox#1{\\def#1{}}\n\
\\def\\today{\\tth_today}\n\
\\def\\tthfootnotes{Footnotes}\n\
\\def\\string#1{\\verb!#1!}\n\
\\def\\displaylines#1{\\eqalign{#1}}\n\
\\def\\leqalignno#1{\\eqalignno{#1}}\n\
\\def\\leqno#1{\\eqno{#1}}\
\\def\\bm#1{{\\tth_bm #1}}\
\\newenvironment{abstract}{\\begin{tthabstract}}{\\end{tthabstract}}\
\\newcommand\\tthoutopt[1][]{#1}\n\
\\newcommand\\tthnooutopt[1][]{}\n";

 /* static functions */
static int indexkey();
static void mkkey(),rmkey(),rmdef(),mkdef();
static void delimit();
static int b_align();
static int roman();
static int scaledpoints();
static void tagpurge();
static int adddimen();

%}


 /* Start condition stacks, not POSIX */
%option stack	
 /* Permits to compile without -lfl */
%option noyywrap	
%option noreject
 /* Remove isatty calls for VMS */
%option always-interactive 

 /* Not as accurate, probably because of rescanning. %option yylineno */

	/* Start conditions */
 /* Paragraph grouping for beginsection, item etc: */
%s pargroup
 /* Cause par to scan texclose.*/
%s parclose 
 /* Look for first token following and put argchar at end:*/
%x tokenarg
 /* Expand following command and output expchar after first token,
    if non-null, else prefix exptex and rescan (in equations)*/
%x exptokarg
 /* Put swapchar after following open brace and rescan. */
%x swaparg
 /* Enclose a bare token in braces. Caller must initialize dupstore: */
%x embracetok
 /* Output the current brace group as raw text. Terminate with closing: */
%x rawgroup
 /* Output verbatim till we encounter \end{verbatim} */
%x verbatim
 /* Output verbatim till we encounter a character matching chr1[0] */
%x verb
 /* Output without HTML tags so that we are compatible with title*/
%x notags
 /* Get from here to end of brace group. Then treat according to storetype:
    0 Make argchar the closing of first, attach second copy, rescan.
    1 Save in supstore. 2 Save in substore. For sup/bscripting. 
    3 Rescan with argchar between first and second copies.
    4 Rescan one copy only with argchar prepended.
    5 Rescan one copy with argchar postpended.
 */
%x dupgroup
 /* Same thing but delimited by square brackets */
%x dupsquare
 /* Throw away a following group closed by \fi or \end{picture} */
%x discardgroup
 /* Throw away the following text closed by \else or \fi */
%x falsetext
 /* Inner if state inside falsetext. As falsetext except no else sensitivity*/
%x innerfalse 
 /* Throw away the following text closed by \or */
%x ortext
 /* Break out of dumping of ortext states */
%x orbreak
 /* Get the unexpanded tokens to compare for ifx */
%x getifx
 /* Get the tokens to compare for if */
%x getiftok
 /* Get the numbers to compare for ifnum */
%x getifnum
 /* Look for first number following. Put into argchar, and Pop. */
%x lookfornum 
 /* Look for first number following. Output num, argchar, and Pop. */
%x insertnum
 /* Look for unit.  Catenate to argchar. Construct dimension in anumber */
%x lookforunit 
 /* Get the first file-like argument. */
%x lookforfile 
 /* Get nothing but the corresponding closebrace. */
%x matchbrace
 /* Get a box definition for setbox. Mostly getting optional dimension */
%x getbox 
 /* Get an immediate sub or sup, else pop*/
%x getsubp
 /* Get the command we are defining only: */
%x getdef
 /* Get a brace group as the definition's name */ 
%x getdefbr 
 /* Get the definition's argument description. Leave number in narg. */
%x getnumargs
 /* Compress whitespace in delimited definition argument template and store*/
%x ddcomp
 /* Get the end part of a newenvironment */
%x getend
 /* Define a let command. Explicitly using predefined macro. */
%x letdef
 /* Throw away contiguous brace groups */
%x unknown
 /* Advancing dimensions */
%x dimadv

 /* Get complete definition of a new count: */
%x getcount
 /* Perform a counter advance: */
%x advance
 /* Output the value of a counter: */
%x number
 /* Set the value of a previously defined counter: */
%x counterset 

 /* Extract the halign template.  */
%x htemplate
 /* Inside tables, interpret & and \cr */
%s halign
 /* Handle ends of lines in halign state, e.g. \hline \end{tabular} \multi */
%x hendline
 /* State for exiting expand-after of an ampersand. */
%x hamper
 /* State for exiting expand-after of an ampersand in equations. */
%x mamper

%x vtemplate
%s valign

 /* Equation mode. */
%s equation
 /* Display table mode */
%s disptab
 /* Textbox in equations mode */
%s textbox

 /* latex listing environments */
%s Litemize
%s Lenumerate
%s Ldescription
%s Lindex

 /* Uppercase mode */
%s uppercase
 /* Small caps text mode, no braces allowed. */
%s textsc
 /* Define the token to be the next lot of text: */
%x define
 /* Obtain the bracegroup as a macro argument: */
%x macarg
 /* Obtain the bracket group as a macro argument: */
%x optag
 /* Detect the presence of [ and switch to optag if found */
%x optdetect
 /* Input a file. */
%x inputfile
 /* Parameter substitution in macros. */
%x psub
 /* Expanding an edef*/
%x xpnd
 /* Interpreting delimited definition argument */
%x delimint
 /* Removing spaces e.g. after commands */
%x removespace
 /* Warn if output takes place before title. */
%s titlecheck
 /* titlecheck state for strict HTML/XHTML. */
%s stricttitle
 /* Scan builtins at start. */
%x builtins
 /* Scan LaTeX builtins at start. */
%x latexbuiltins
 /* Glue flex clause removal */
%x glue
 /* rule dimension removal */
%x ruledim
 /* big delimiter get type */
%x bigdel
 /* Picture environment */
%x picture
 /* csname getting state */
%x csname
 /*tabular alignment string interpretation*/
%x talign
 /* Copying halign material to precell*/
%x tempamp
 /* Inserting space in horizontal lines and vertical.*/
%x hskip
%x vskip
 /* Dealing with hboxes */
%x hbox
 /* Dealing with vboxes */
%x vbox
 /* Setting Dimensions */
%x setdimen
 /* PreScanning tabular argument */
%x tabpre
 /* Error exiting state */
%x error
 /* Paragraph checking state after a newline when par is possible*/
%x parcheck
 /* Expand following token till we reach something no more expandable 
    but don't embrace it. Prefix exptex if not zero. */
%x tokexp
 /* Copying of a group but escaping special characters as we go. Hence
   making it suitable for subsequent verbatim or url handling. Ending
   as dugroup. */
%x escgroup
 /* Dupgroup that treats % as a normal character */
%x uncommentgroup
 /* Deal with the string that has been stored using uncommentgroup*/
%x urlgroup
%x indexgroup
 /* Checking if the start of a $$ indicates display table */
%x halsearch
	/* Defines */
 /* NOA	[^a-zA-Z0-9] Removed 1.04 */
NUM	[+-]?[0-9.]+
SP      [ ]
TSP     [ \t]
 /* Old versions. WSP     [ \t\n] WSC     [^ \t\n] NL      \n */
WSP     [ \t\r\n]
WSC     [^ \t\r\n]
NL      \n|\r|\r\n
NLC     [^\r\n]
CMNT    %[^\r\n]*{NL}?
ANY     .|\n
  /* Costs 120k C! BRCG   \{[^\}]*(\{[^\}]*(\{[^\}]*\})?[^\}]*\})?[^\}]*\} */
BRCG    \{[^\}]*\} 

%%

  /* Local storage */
%{
#define NCOUNT 256
#define NFNMAX 1600
#define NARMAX 20
#define TTH_PUSH_BUFF(rmv) if ( tth_stack_ptr >= MAX_INCLUDE_DEPTH )\
    {fprintf(stderr,buffdeep,tth_num_lines);TTH_EXIT( 1 );}\
    eofrmv[tth_stack_ptr]=rmv;\
    include_stack[tth_stack_ptr++] = YY_CURRENT_BUFFER;
char *buffdeep="**** Error: FATAL. Scan buffers nested too deeply. Infinite loop? Line %d.\n";
#define TTH_SCAN_STRING TTH_PUSH_BUFF(0);yy_scan_string
extern void tth_epsf(),tth_symext(),tth_encode(),tth_undefine();
 /*Not static except for tthfunc*/
#define STATIC
STATIC char closing[TTH_CHARLEN]={0};
STATIC char preclose[TTH_CHARLEN]={0};
STATIC char argchar[TTH_CHARLEN]={0};
STATIC char defchar[TTH_CHARLEN]={0};
STATIC char eqchar[4*TTH_CHARLEN]={0};
STATIC char eqchar2[4*TTH_CHARLEN]={0};
STATIC char scratchstring[TTH_CHARLEN]={0};
STATIC char scrstring[TTH_CHARLEN]={0};
STATIC char swapchar[TTH_CHARLEN]={0};
STATIC char expchar[TTH_CHARLEN]={0};
STATIC char exptex[TTH_CHARLEN]={0};
STATIC char strif[TTH_CHARLEN]={0};
STATIC char newcstr[TTH_CHARLEN]={0};
STATIC char boxalign[TTH_CHARLEN]={0};
STATIC char boxvalign[TTH_CHARLEN]={0};
STATIC char dupstore[TTH_DLEN];
STATIC char dupstore2[2*TTH_DLEN];
STATIC char supstore[TTH_DLEN]={0};
STATIC char substore[TTH_DLEN]={0};
STATIC char defstore[TTH_DLEN]={0};
STATIC char psubstore[TTH_DLEN]={0};
STATIC char chr1[2]={0};
STATIC int storetype=0;
STATIC int bracecount=0;
STATIC int horizmode=0; /* 1 in horizontal mode. -1 after a \n. 0 after a \par*/
STATIC int horiztemp=0;
STATIC int whitespace=0;
STATIC int edeftype=0;
 /* Stacking of halign and tabular operational data. */
STATIC int colnum=0;
STATIC char halstring[TTH_CHARLEN]={0};
STATIC char *halstrings[NARMAX];
STATIC YY_BUFFER_STATE halbuffs[NARMAX];
STATIC int halignenter=0;
STATIC int halenter[NARMAX]={99};
STATIC int halncols[NARMAX]={0};
STATIC int halind=0;
#define TTH_HAL_PUSH  if(tth_debug&32)fprintf(stderr,"HAL PUSH %d,",halind);\
   if(tth_debug&32)fprintf(stderr,"%s\n",halstring);\
  if(halind < NARMAX) {\
  halenter[halind]=halignenter;halncols[halind]=ncols;\
  halbuffs[halind]=halbuff;colnum=0;mkkey(halstring,halstrings,&halind);\
  }else{ fprintf(stderr,"**** Error: Fatal. Tables nested too deeply. Line %d\n",tth_num_lines);\
  TTH_EXIT(1);}
#define TTH_HAL_POP  if(tth_debug&32)fprintf(stderr,"HAL POP %d,",halind-1);\
   if(halind > 0){\
   strcpy(halstring,halstrings[halind-1]);\
   rmkey(halstrings,&halind);halbuff=halbuffs[halind];\
   halignenter=halenter[halind];ncols=halncols[halind];\
   if(tth_debug&32)fprintf(stderr,"%s\n",halstring);\
   }else{ fprintf(stderr,"**** Error: Fatal. Underflow of Table index. Line %d\n",tth_num_lines);\
    TTH_EXIT(1);}
STATIC int eqalignlog=0; /* 1 eqalign, >1 no-numbering, >100 reset at line end.*/
STATIC int colspan=1; /* colspan of table cell; was 0 default. Now 1.*/
STATIC int eqaligncell=0;
STATIC int eqalignrow=0;
STATIC int eqalog[NARMAX]; /* Storage for pushing eqalign flags */
STATIC int eqacell[NARMAX];
STATIC int eqarow[NARMAX];
STATIC int eqaind=0;
#define TTH_EQA_PUSH if(eqaind < NARMAX) {\
   eqalog[eqaind]=eqalignlog;eqacell[eqaind]=eqaligncell;\
   eqarow[eqaind]=eqalignrow;eqaind++;\
   }else{ fprintf(stderr,"**** Error: Fatal. Matrices nested too deeply. Line %d\n",tth_num_lines);\
   TTH_EXIT(1);}
#define TTH_EQA_POP if(eqaind > 0){ eqaind--;\
   eqalignlog=eqalog[eqaind];eqaligncell=eqacell[eqaind];\
   eqalignrow=eqarow[eqaind];\
   }else{ fprintf(stderr,"**** Error: Fatal. Underflow of Matrix index:%d Line %d\n",eqaind,tth_num_lines);\
    TTH_EXIT(1);}
STATIC int i,ind=0,jarg=0,jargmax=0,jscratch,js2,jshal,jstal=0, hgt=0;
STATIC int iac=0,jac=0;
STATIC int ncounters=0;
STATIC int counters[NCOUNT]={0};
STATIC char *countkeys[NCOUNT]={0};
STATIC char *countwithins[NCOUNT]={0};
STATIC int nkeys=0;
STATIC char *keys[NFNMAX]={0};
STATIC char *defs[NFNMAX]={0};
STATIC char *optargs[NFNMAX]={0};
STATIC int nargs[NFNMAX]={0};
STATIC int lkeys[NFNMAX]={0};
STATIC int ckeys[NFNMAX]={0};
STATIC int localdef=0;
STATIC int narg;
STATIC int margmax=0;
STATIC char *margkeys[NARMAX]={0};
STATIC char *margs[NARMAX]={0};
STATIC int margn[NARMAX]={0};
/* Fractions and math */
extern void tth_enclose(),tth_prefix();
STATIC int eqdepth=0;
STATIC char *eqstrs[NFNMAX];
STATIC char eqstr[4*TTH_DLEN]={0};
STATIC char eqstore[4*TTH_DLEN];
STATIC char eqlimited[TTH_DLEN]={0};
/*  STATIC int eqsubsup=0; */
STATIC int eqclose=0;
STATIC int eqhgt=0;
STATIC int mtrx[NFNMAX]={0};
STATIC int active[NFNMAX]={0};
STATIC int levhgt[NFNMAX]={0};
STATIC int tophgt[NFNMAX]={0};
STATIC char levdelim[NFNMAX][20]={{0}};
STATIC int tabwidth=150;
STATIC int qrtlen=0,qrtlen2=0;
STATIC time_t thetime;
struct tm timestruct;
STATIC char *chscratch=0;
STATIC char *chs2=0;
STATIC char *chs3=0;
STATIC char *chdef=0;
STATIC char *chopt=0;
STATIC int lopt=0;
/* Latex Sections etc*/
STATIC int chaplog=0;
STATIC int countstart=0;
#define ftntno counters[0+countstart]
#define chapno counters[1+countstart]
#define sectno counters[2+countstart]
#define subsectno counters[3+countstart]
#define subsubsectno counters[4+countstart]
#define equatno counters[5+countstart]
#define figureno counters[6+countstart]
#define tableno counters[7+countstart]
#define partno counters[8+countstart]
#define secnumdepth counters[9+countstart]
STATIC int appendix=0;
STATIC char environment[20]={0};   /* Name of environment */
STATIC char labelchar[20]={0}; /* Running label in current section. */
STATIC char envirchar[20]={0}; /* Running label in numbered environment. */
STATIC char refchar[20]={0};   /* Type of internal reference. */
STATIC char colorchar[20]={0};
STATIC char filechar[20]={0};
STATIC char filenext[20]={0}; /*sf*/
STATIC char auxflch[20]={0};
STATIC char schar[3]={0}; /*sf*/
#define TNO 400
STATIC char *tchar[TNO]={0}; /*sf*/
STATIC char *fchar[TNO]={0}; /*sf*/
STATIC int tbno=0;          /*sf*/
STATIC int fgno=0;          /*sf*/
STATIC char ftntcode[4];
STATIC int ftntwrap=0;
STATIC int displaystyle=0;
STATIC int nbuiltins=0;
 /*  STATIC int compression=0; */
STATIC int enumerate=0;
STATIC char enumtype[5]={'1','a','i','A','I'};
STATIC int eofrmv[MAX_INCLUDE_DEPTH];
STATIC int lbook=0;
STATIC int lefteq=0;
STATIC char unitlength[TTH_CHARLEN]={0};
STATIC int picno=0;
STATIC int ncols=0;
STATIC char tdalign[TTH_CHARLEN]={0};
STATIC char precell[TTH_CHARLEN]={0};
STATIC float anumber=0.,bnumber=1.,cnumber=0.;
STATIC float cyanc=0.,magentac=0.,yellowc=0.,blackc=0.;
STATIC float redc=0.,greenc=0.,bluec=0.;
STATIC int thesize=0;
STATIC int tthglue=0;
STATIC int tth_eqwidth=100;
STATIC int dimadvstate=0;
#define TTH_INDPC 5
extern int tth_group();
 /* Number of scaledpoints per screen pixel. 100 pixels per inch. */
#define SCALEDPERPIXEL (65536*72/100)
 /* Guess of the screen width in pixels larger than real is usually the best
    error to have. */
#define DEFAULTHSIZEPIX 1000
/* extern int tth_halcode(); */
STATIC int boxborder=0;
extern int tth_cmykcolor();
STATIC char xpndstring[2]={0};
STATIC int bibliogs=0;
STATIC int verbinput=0;
/* Open for reading, and test that we really can read it. */
STATIC char openscrt[2];
#define TTH_FILE_OPEN(scratchstring) \
 ( (tth_inputfile=fopen(scratchstring,"r")) ?\
  ( ( (fread(openscrt,1,1,tth_inputfile)==0) && ferror(tth_inputfile) \
       && (!fclose(tth_inputfile) || 1 ) ) ? \
       NULL : (freopen(scratchstring,"r",tth_inputfile)) )\
 : NULL )
STATIC int tth_index_face=0;
STATIC int tth_index_line=0;
STATIC int tthindexrefno=0;
STATIC int oa_removes=0;
STATIC char page_compositor[]="-";
STATIC char input_filename[TTH_CHARLEN]={0};
STATIC int minus=1;
#define TTH_UNKS_LEN 4000
STATIC char unknownstring[TTH_UNKS_LEN]={0};
STATIC char valignstring[TTH_CHARLEN]={0};
STATIC int valsec=0;
 /* */

 /* Define the storable stacked integers  */
#define INTDEPTHMAX 30 /* Stack depth*/ 
#define INTMAX 10      /* Maximum integers */
#define INTERROR 99999 /* Value indicating overflow */
int PUSHEDINTS[INTMAX][INTDEPTHMAX]={{0}};
int PUSHEDINTDEPTHS[INTMAX]={0};
#define TTH_INT_SETPUSH(name,value) \
   if(PUSHEDINTDEPTHS[name]<INTDEPTHMAX) {\
     PUSHEDINTS[name][++PUSHEDINTDEPTHS[name] ]=value;\
   }else{fprintf(stderr,"INT overflow, %s\n","name");++PUSHEDINTDEPTHS[name];}
#define TTH_INT_VALUE(name) \
   (PUSHEDINTDEPTHS[name]<=INTDEPTHMAX) ? \
   PUSHEDINTS[name][PUSHEDINTDEPTHS[name] ] :\
   INTERROR
#define TTH_INT_POP(name) \
   if(PUSHEDINTDEPTHS[name]>0){\
     PUSHEDINTS[name][PUSHEDINTDEPTHS[name]--]=0;\
   }else{fprintf(stderr,"INT underflow, %s\n","name");}
 /* Here we define as macros the names of our pushed integers. */
#define EQSUBSUP 0
 /* Calls are then of the form, e.g. TTH_INT_VALUE(EQSUBSUP,10)*/


/*mathstringshl*/

#define TTH_DO_MACRO *(yytext+strcspn(yytext," "))=0;\
  ind=indexkey(yytext,keys,&nkeys); \
  if(horizmode) horizmode=1;\
  if(ind != -1) {\
    jargmax=nargs[ind];\
    chdef=defs[ind];\
    chopt=optargs[ind];\
    if(optargs[ind]) lopt=1; else lopt=0;\
    *dupstore=0;\
    if( jargmax == 0){\
      jarg=1;\
      if(tth_debug&8)fprintf(stderr,"Using definition %s %d= %s\n",yytext,ind,chdef);\
      TTH_PUSH_BUFF(1);\
      yy_scan_string(chdef);\
      yy_push_state(psub);\
    }else if(jargmax >0){\
      jarg=1;\
      if(tth_debug&8) fprintf(stderr,"Getting arguments of %s\n",yytext);\
      bracecount=-1;\
      if(lopt) yy_push_state(optdetect);\
      else{yy_push_state(macarg);yy_push_state(embracetok);}\
    }else{\
      if(tth_debug&8)fprintf(stderr,"Using Delimited Definition:%s\n",yytext);\
      chscratch=defs[ind-1];\
      chs2=chscratch;\
      *dupstore2=0;\
      jarg=0;\
      yy_push_state(delimint);whitespace=0;\
      horizmode=1;\
    }\
  }

#define TTH_CHECK_LENGTH  js2=0;\
 if(strlen(dupstore) > 9*TTH_DLEN/10 ){chs2=dupstore;js2=1;}\
   else if(strlen(defstore) > 9*TTH_DLEN/10 ){chs2=defstore;js2=1;}\
   else if(strlen(psubstore) > 9*TTH_DLEN/10 ){chs2=psubstore;js2=1;}\
   else if(strlen(dupstore2) > 18*TTH_DLEN/10 ){chs2=dupstore2;js2=1;}\
 if(js2){ *(chs2+200)=0;fprintf(stderr,\
        "\n**** Error: FATAL. Exceeding allowed string length. Line %d. Runaway argument?\n String starts:%s ...\n",tth_num_lines,chs2);\
     fprintf(stderr,"   Possible cause: Use of macro %d, %s\n",ind,keys[ind]);\
     TTH_EXIT(1);}

#define TTH_CCAT(chr1,chr2) if(strlen(chr1)+strlen(chr2) >= TTH_CHARLEN)\
 {fprintf(stderr,\
"**** Character overflow; catenation of %s prevented, line %d\n%s",\
chr2,tth_num_lines,\
"     Check for alternating font changes. Use grouping instead.\n\
     If necessary, increase the value of TTH_CHARLEN and recompile TtH.\n");}\
else strcat(chr1,chr2);

#define TTH_CCPY(chr1,chr2) if(strlen(chr2) >= TTH_CHARLEN)\
 {fprintf(stderr,\
"**** Character overflow; strcpy of %s prevented, line %d\n",chr2,tth_num_lines);}\
else strcpy(chr1,chr2); 

#define TTH_PRECLOSE(chr1) strcpy(preclose,closing);TTH_CCPY(closing,chr1);\
 TTH_CCAT(closing,preclose); 

 /*
#define TTH_PRETEXCLOSE(chr1) strcpy(preclose,tth_texclose[tth_push_depth]);\
 TTH_CCPY(tth_texclose[tth_push_depth],chr1);\
 TTH_CCAT(tth_texclose[tth_push_depth],preclose); 
 */
#define TTH_PRETEXCLOSE(chr1) strcpy(scratchstring,tth_texclose[tth_push_depth]);\
 TTH_CCPY(tth_texclose[tth_push_depth],chr1);\
 TTH_CCAT(tth_texclose[tth_push_depth],scratchstring);*scratchstring=0; 

#define TTH_SWAP(chr1) strcpy(swapchar,chr1);yy_push_state(swaparg);\
  yy_push_state(embracetok);
  /* Do an explicitly defined tex function of argno arguments (>0) */
#define TTH_TEX_FN(chr1,argno)  chdef=chr1;jargmax=argno;\
  jarg=1;bracecount=-1;lopt=0;\
  yy_push_state(macarg);yy_push_state(embracetok);
  /* Do an explicitly defined tex function of argno arguments (>1)
     including an optional argument. */
#define TTH_TEX_FN_OPT(chr1,argno,defaultopt)  chdef=chr1;jargmax=argno;\
  jarg=1;bracecount=-1;lopt=1;chopt=defaultopt;\
  yy_push_state(optdetect);

#define TTH_PUSH_CLOSING tth_key[tth_push_depth]=nkeys;tth_push(closing)
#define TTH_POP_CLOSING if(tth_debug&16)fprintf(stderr,"nkeys:%d,tth_key:%d\n",nkeys,tth_key[tth_push_depth-1]);\
  if(nkeys-tth_key[tth_push_depth-1])\
  tth_undefine(keys,&nkeys,tth_key[tth_push_depth-1],lkeys);tth_pop(closing);

#define TTH_HALCODE(chr1) ((*chr1=='c') ? TTH_TABCT :\
( (*chr1=='r')? TTH_TABRT :\
(  (*chr1=='p')? (\
  (strcpy(scrstring," width=\"")!=NULL &&\
  strncat(scrstring,chr1+2,strlen(chr1+2)-1)!=NULL &&\
  strcat(scrstring,"\"")!=NULL) ? scrstring: "")\
 : TTH_TABLT)))


 /*    fprintf(stderr,"%s-%s[%d%d]",precell,yytext,jshal,jstal);\
    if(jshal==1){TTH_CCAT(precell,"{");}\
 */
#define TTH_HALACT if(tth_debug&32)\
    fprintf(stderr,"+%s[%d%d]",yytext,jshal,jstal);\
  if(jshal>1){jshal--;}else{\
    if(jshal==0){sprintf(scratchstring,TTH_TDVAR,TTH_HALCODE(yytext));\
         TTH_OUTPUT(tdalign);*tdalign=0;\
	 TTH_OUTPUT(scratchstring);\
         if(eqdepth){TTH_OUTPUT(TTH_EQ5);}\
    }\
    yy_switch_to_buffer(include_stack[--tth_stack_ptr] );\
    yy_pop_state();jshal=0;\
    if(tth_debug&32){fprintf(stderr,"%s",precell);}\
    TTH_SCAN_STRING(precell);*precell=0;} 
#define TTH_HALSWITCH  {TTH_PUSH_BUFF(0);yy_switch_to_buffer(halbuff);yy_push_state(talign);}

#define TTH_TEXCLOSE if(*tth_texclose[tth_push_depth-1]){\
    if(tth_debug&8)fprintf(stderr,\
	       "Active TEXCLOSE: %s at push_depth %d, eqclose=%d\n",	\
		tth_texclose[tth_push_depth-1],tth_push_depth,eqclose); \
	yyless(0);TTH_SCAN_STRING(tth_texclose[tth_push_depth-1]);\
	*tth_texclose[tth_push_depth-1]=0;}

#define TTH_INC_LINE if(!(tth_stack_ptr||ftntwrap)){\
 if(tth_debug&32)fprintf(stderr," Line increment: numlines=%d yytext=%s",\
 tth_num_lines,yytext);tth_num_lines++;};
#define TTH_INC_MULTI chs3=yytext;while((chs3=(strstr(chs3,"\n"))?(strstr(chs3,"\n")):(strstr(chs3,"\r")))){chs3++;TTH_INC_LINE};
#define TTH_EXTRACT_COMMENT \
 if((chscratch=strstr(yytext,"%%tth:"))||(chscratch=strstr(yytext,"%%ttm:"))){\
    TTH_CCPY(scratchstring,chscratch+6);\
    chs2=yytext;\
    while((chs2=strstr(chs2,"\n"))!=NULL&&chs2<=chscratch){\
      TTH_INC_LINE;chs2++;\
    }\
    TTH_SCAN_STRING(scratchstring);\
  }else


#define TTH_TINY (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"tiny\">" : "<div class=\"tiny\">")
#define TTH_SCRIPTSIZE (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"scriptsize\">": "<div class=\"scriptsize\">")
#define TTH_FOOTNOTESIZE (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"footnotesize\">": "<div class=\"footnotesize\">")
#define TTH_SMALL (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"small\">": "<div class=\"small\">")
#define TTH_NORMALSIZE (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"normalsize\">": "<div class=\"normalsize\">")
#define TTH_large (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"large\">": "<div class=\"large\">")
#define TTH_Large (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"larger\">": "<div class=\"larger\">")
#define TTH_LARGE (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"largerstill\">": "<div class=\"largerstill\">")
#define TTH_HUGE  (((horizmode!=0) || (tth_htmlstyle&4)) ? "<span class=\"huge\">": "<div class=\"huge\">")
#define TTH_SIZEEND (((horizmode!=0) || (tth_htmlstyle&4)) ? "</span>" :"</div>")

#define TTH_SIZEGEN1 "<span style=\"font-size:"
#define TTH_SIZEGEN2 "%\">"
#define TTH_COLOR "\\special{html:<span style=\"color:#%s\">}"
#define TTH_COLOREND "</span>"
 /*start executable statements*/

tth_flev=tth_flev0;

%}
 /******************************* RULES *****************************/

\\tthlatexbuiltins  nbuiltins=nkeys;tth_debug=tth_LaTeX-1;fprintf(tth_fdout,"\n");
\\tthbuiltins nbuiltins=nkeys; bibliogs=0;

 /* Strip out formating commands. */
<notags>\\bf
<notags>\\it
<notags>\\sl
<notags>\\rm
<notags>\\textbf
<notags>\\textit
<notags>\\textsl
<notags>\\textsf
<notags>\\texttt
<notags>\\textsc
<notags>\\textnormal
<notags>\\textrm
<notags>\\emph
<notags>\\thanks\{  |
<notags>\\special\{   yy_push_state(matchbrace);
 /* external macro expansion in notags.*/
<notags>\\[a-zA-Z@]+ {
  if(tth_titlestate&1){
    TTH_DO_MACRO else{TTH_OUTPUT(yytext);}
  }else{
    TTH_OUTPUT(yytext);
  }
}
<notags>\\(\#|\%|\\|[ ])   TTH_OUTPUT(yytext+1);
<notags>\$    {
  if(tth_titlestate&2){
    tth_tagpurge=1;
    TTH_SCAN_STRING("\\tth_notageq");  
  }
}

\\begin\{notags\}  {
  if(tth_titlestate){
    yy_push_state(notags);
  }else{
    yy_push_state(verbatim);
  }
  TTH_PUSH_CLOSING;
}
\\verbatiminput { /* Defined as a latex command with optional arg */
  verbinput=1;
  TTH_TEX_FN_OPT("\\tth_verbinput #2 \\tth_endverbinput#tthdrop2",2,"");
}
\\tth_verbinput    {
  fprintf(tth_fdout,"\n<pre>"); yy_push_state(verbatim); /*begin verbatim*/
  TTH_PUSH_CLOSING;  TTH_CCPY(closing,"\n</pre>");
  yy_push_state(inputfile);
  yy_push_state(removespace);
}

<exptokarg,tokexp,halign>\\expandafter |
\\expandafter   TTH_TEX_FN("\\tthexpandafter#tthdrop1",1);
<psub>\\tthexpandafter#tthdrop1  {
  if(horizmode) horizmode=1;
  js2=indexkey("#1",margkeys,&margmax);
  yy_pop_state();
  strcpy(exptex,margs[js2]);
  rmdef(margkeys,margs,&margmax); 
  if(tth_debug&8)fprintf(stderr,"Expanding after %s\n",exptex);
  *expchar=0;
  yy_push_state(tokexp); /* expandafter not using embracing  */
 }
<exptokarg,tokexp>\\csname |
\\csname  yy_push_state(csname);strcpy(scratchstring," ");
<csname>.     strcat(scratchstring,yytext);
<csname>{NL} {
  fprintf(stderr,"**** Error: line end in csname. Syntax error? Line %d\n",tth_num_lines);
  TTH_SCAN_STRING("\\endcsname");
}
<csname>\\endcsname {
  yy_pop_state();
  chscratch=scratchstring+strspn(scratchstring," \t")-1;
  *chscratch='\\';
  if(tth_debug&8)fprintf(stderr,"Rescanning \\csname:%s\n",chscratch);
  TTH_SCAN_STRING(chscratch);
}
 
 /**** **********  Non-standard functions. ******************/
 /* Put any personal rules here unless there is some special reason. */
\\[bB][iI][gG]bf {
  TTH_OUTPUT(TTH_Large);TTH_PRECLOSE(TTH_SIZEEND);
  TTH_OUTPUT(TTH_BOLD1);TTH_PRECLOSE(TTH_BOLD2);
}
\\includegraphics\*?(\[[^\]]*\]){0,2} {
  TTH_INC_MULTI;
  TTH_SCAN_STRING("\\epsfbox");
}
\\e?psfig |
\\epsffile |
 /* \\epsfbox TTH_TEX_FN("\\tthpsfile#tthdrop1",1);
 This code needs to be changed to behave like \leavevmode\hbox
 in that it stacks boxes horizontally. 
 A problem is that to prevent h/vbox from breaking lines unnecessarily in HTML
 we start a new table only if we are NOT in horizmode. This is the opposite
 of TeX's behaviour. However, a \vbox ought to do it.*/
\\epsfbox {
    {
      if(tth_debug&32)fprintf(stderr,"Calling tthpsfile %s\n",yytext);
    TTH_TEX_FN("\\tthpsfile#tthdrop1",1);
  }
}
\\tthepsfbox     TTH_TEX_FN("\\tthpsfile#tthdrop1",1);
<psub>\\tthpsfile#tthdrop1  {
  /*if(horizmode)*/ horizmode=1;
  js2=indexkey("#1",margkeys,&margmax);
  TTH_CCPY(scratchstring,margs[js2]);
  yy_pop_state();
  rmdef(margkeys,margs,&margmax); 
  if(tth_debug&32)fprintf(stderr,"Figure inclusion %s\n",scratchstring);
  if((chscratch=strstr(scratchstring,"file=")) != NULL){
    chscratch=chscratch+5;
  }else  if((chscratch=strstr(scratchstring,"figure=")) != NULL){
    chscratch=chscratch+7;
  }else{
    chscratch=scratchstring;
  }
  chscratch=chscratch+strspn(chscratch,"{ ");
  *(chscratch+strcspn(chscratch,"},"))=0;        /* Terminate at } or ,*/
  tth_epsf(chscratch,tth_epsftype);
 }
 

 /* Starting State for Constructing head/body and title.*/

<titlecheck,stricttitle>\\begin\{(raw)?(html|HTML)\}    {
  fprintf(stderr,"Initial HTML output assumed to be the title.\n");
  if(tth_htmlstyle&3)strcat(tth_texclose[tth_push_depth],
		   "</head>\n<body><div>\n");
  yy_pop_state();
  yyless(0);
  }
<titlecheck,stricttitle>\\special\{{SP}*html\:[^<\}]*(<title|<TITLE) {
  fprintf(stderr,"Initial HTML output including title.\n");
  if(tth_htmlstyle&3)strcat(tth_texclose[tth_push_depth],
		   "</head>\n<body><div>\n");
  yy_pop_state();
  yyless(0);
}
<titlecheck,stricttitle>\\special\{{SP}*html\: {
  fprintf(stderr,"Initial HTML output apparently NOT the title terminates head.\n");
  if(tth_htmlstyle&3) {TTH_OUTPUT("</head>\n<body><div>\n")};
  yy_pop_state();
  yyless(0);
}

<titlecheck,stricttitle>\\title   TTH_TEX_FN_OPT("{\\headline{#2} \\centerheader{1}{{#2}}{align=\"center\"}}#tthdrop2",2,"");

\\title   {
  if(!tth_htmlstyle&1){
    TTH_TEX_FN_OPT("{\\headline{#2}    \\centerheader{1}{{#2}}{align=\"center\"}}#tthdrop2",2,"");
  }else{
    TTH_TEX_FN_OPT("{\\centerheader{1}{{#2}}{align=\"center\"}}#tthdrop2",2,"");
  }
}

<titlecheck,stricttitle>\\headline=?  { 
  yy_pop_state();
  if(tth_htmlstyle&3){
    TTH_TEX_FN("{\\special{html:\n<title>} \\begin{notags}#1\\end{verbatim} \\special{html:</title>\n</head>\n<body><div>\n}}#tthdrop1",1);
  }else{
    TTH_TEX_FN("{\\special{html:\n<title>} \\begin{notags}#1\\end{verbatim}\\special{html:</title>\n}}#tthdrop1",1);
  }  
}

\\headline=?   if(!tth_htmlstyle&1){
  TTH_TEX_FN("{\\special{html:\n<title>}\\begin{notags}#1\\end{verbatim}\\special{html:</title>\n}}#tthdrop1",1);
}else{  
  TTH_TEX_FN("#tthdrop1",1);
}

<titlecheck,stricttitle>\\par
<titlecheck,stricttitle>{NL}  TTH_INC_LINE;      /* Don't put spurious \par s at top.*/
 /* Trap some common causes of improper output in titlecheck state. */
<titlecheck,stricttitle>\\beginsection |
<titlecheck,stricttitle>\\centerline    {TTH_SCAN_STRING("\\title");}

<titlecheck,stricttitle>\\underbar{SP}* |
<titlecheck,stricttitle>\\textsc    |
<titlecheck,stricttitle>\\uppercase |
<titlecheck,stricttitle>\\chapter\*?   |
<titlecheck,stricttitle>\\part      |
<titlecheck,stricttitle>\\subsection\*?      |
<titlecheck,stricttitle>\\subsubsection\*?      |
<titlecheck,stricttitle>\\section\*? {
  sprintf(newcstr,"\\headline{#1}%s{#1}#tthdrop1",yytext);
  TTH_TEX_FN(newcstr,1);}

<titlecheck,stricttitle>\\halign({SP}*to{SP}*\\hsize)?{WSP}*\{  |
<titlecheck,stricttitle>\{[ ]*\\(bf|sl|it)  |
<titlecheck,stricttitle>\\begin\{[^d][^\}]*\}   |
<titlecheck,stricttitle>\\centerheader      |
<titlecheck,stricttitle>\\item              |
<titlecheck,stricttitle>\\end               |
<titlecheck,stricttitle>\\hbox{SP}*([ ]to)?    |
<titlecheck,stricttitle>\\[^a-zA-Z][a-zA-Z]*         |
<titlecheck,stricttitle>\$\$        	|
<titlecheck,stricttitle>\$[^$]+\$ {
  fprintf(stderr,
	"**** File starts with \"%s\". It can\'t be the HTML title.\n",
	  yytext);
  fprintf(tth_fdout,"\n<title>No Title</title>\n");
  if(tth_htmlstyle&3)fprintf(tth_fdout,"</head>\n<body><div>\n");
  yy_pop_state();
  yyless(0);
  TTH_SCAN_STRING("\\par");
}
 /* Things that can't go in the HTML head in strict mode.*/
<stricttitle>\\rm(family)?{SP}* |
<stricttitle>\\obeylines{SP}* |
<stricttitle>\\it{SP}* |
<stricttitle>\\bf{SP}* |
<stricttitle>\\small{SP}* |
<stricttitle>\\(H|h)uge{SP}* |
<stricttitle>\\large{SP}* |
<stricttitle>\\LARGE{SP}* |
<stricttitle>\\Large{SP}* {
  fprintf(stderr,
	  "**** File starts with \"%s\". It can\'t be in strict HTML heads.\n",
	  yytext);
  fprintf(tth_fdout,"\n<title>No Title</title>\n");
  if(tth_htmlstyle&3)fprintf(tth_fdout,"</head>\n<body><div>\n");
  yy_pop_state();
  yyless(0);
  TTH_SCAN_STRING("\\par");
}
 /* Make the title the first one to five plain words. */
<titlecheck,stricttitle>[^ \\\{\}\t\r\n\$%]+({SP}+[^ \\\{\}\t\r\n\$%]+){0,5}  {
  fprintf(stderr,"HTML Title constructed as:%s\n",yytext);
  fprintf(tth_fdout,"\n<title>%s</title>\n",yytext);
  if(tth_htmlstyle&3)fprintf(tth_fdout,"</head>\n<body><div>\n");
  yy_pop_state();
  yyless(0);
  TTH_SCAN_STRING("\\par");
} 
<titlecheck,stricttitle>\\pagecolor {
  fprintf(stderr,"Pagecolor in titlecheck.\n");
  if(tth_htmlstyle&3)fprintf(tth_fdout,"<title>No title</title></head>\n");
  yy_pop_state();/* titlecheck terminated */
  TTH_TEX_FN_OPT("{\\edef\\tthexpcol{\\tthpageColor{#2}}\\tthexpcol}#tthdrop2",2,"");
}

\\htmlheader {  /*tth_num_lines--;*/
  TTH_TEX_FN("{\\special{html:\n<h#1>}#2\\special{html:</h#1>}}#tthdrop2",2); }
\\centerheader   TTH_TEX_FN("{\\special{html:\n<h#1 #3>}#2 \\special{html:</h#1>}}#tthdrop3",3);/* tth_num_lines--;*/

\\special\{{SP}*html\:	 |
\\begin\{(raw)?(html|HTML)\}    {
  TTH_PUSH_CLOSING;yy_push_state(rawgroup);
 }

\\href TTH_SCAN_STRING("\\expandafter\\tthhref\\tthescape");
\\tthhref {
  TTH_TEX_FN("{\\special{html:<a href=\"#1\">}#2\\special{html:</a>}}#tthdrop2",2); 
}
  /* Get the following brace group and escape special chars, rescan */
<tokexp>\\tthescape |
\\tthescape {
  *dupstore=0;
  *argchar=0;
  storetype=5; /* Rescan one copy argchar postfixed. */
  yy_push_state(escgroup);
  bracecount=-1;
  yy_push_state(embracetok); /* Make sure we have a braced argument */
}
<tokexp>\\tthurl  |
\\tthurl {
  *dupstore=0;
  *argchar=0;
  yy_push_state(urlgroup);
  storetype=99; /* Just leave in dupgroup to be dealt with by prior state*/
  yy_push_state(uncommentgroup);
  /*yy_push_state(escgroup);*/
  bracecount=-1;
  yy_push_state(embracetok); /* Make sure we have a braced argument */
}

<urlgroup>.|\n {
  yyless(0);
  yy_pop_state();
  /*remove the closing brace*/
  *(dupstore+strlen(dupstore)-1)=0;
  if(strcspn(dupstore,"\\&")!=0){
  /* Even the href can't contain an ampersand literally so we need to
   translate it.*/
    strcpy(dupstore2,dupstore);
    *dupstore=0;
    i=0;
    while(*(dupstore2+i)!=0){
      if(*(dupstore2+i)=='&'){
	if(*(dupstore+strlen(dupstore)-1)=='\\')
	  *(dupstore+strlen(dupstore)-1)=0;/*Remove prior  */
	strncat(dupstore,"&amp;",5);
      }else{
	strncat(dupstore,(dupstore2+i),1);
      }
      i++;
    }
  }
  sprintf(dupstore2,
	  "\\special{html:<a href=\"%s\">}\\verb%c%s%c\\special{html:</a>}"
	  ,dupstore+1,6,dupstore+1,6);
  TTH_SCAN_STRING(dupstore2);
  *dupstore=0;
  *dupstore2=0;
 }

 /*
<urlgroup>.|\n {
  yyless(0);
  yy_pop_state();
  strcpy(dupstore2,"\\href");strcat(dupstore2,dupstore);
  sprintf(dupstore2+strlen(dupstore2),"{\\verb%c%s",6,dupstore+1);
  sprintf(dupstore2+strlen(dupstore2)-1,"%c}",6);
  if(tth_debug&8)fprintf(stderr,"urlgroup rescanning:%s\n",dupstore2);
  TTH_SCAN_STRING(dupstore2);
  *dupstore=0;
  *dupstore2=0;
  }*/

   /* Colordvi commands, won't work in equations. Convert to \color */
\\Magenta |
\\Cyan    |
\\Yellow  |
\\Green   |
\\Blue    |
\\Red     |
\\Black   |
\\White   {
  strcpy(scratchstring,yytext+1);
  /**scratchstring=tolower(*scratchstring);*/
  sprintf(scrstring,"\\color{%s}",scratchstring);
  TTH_SWAP(scrstring);
}
{WSP}*\\and       TTH_INC_MULTI;fprintf(tth_fdout,",");

  /************************ Comment removal ******************/
  /* Many needed so that e.g.  inside a comment does not break stuff */
<define,tokenarg,embracetok,dupgroup,dupsquare,falsetext>{CMNT} |
<innerfalse,ortext,hamper,mamper,hendline,htemplate,tempamp>{CMNT} |
<matchbrace,getdef,getnumargs,macarg,optag,exptokarg,tokexp>{CMNT}   {
  TTH_INC_LINE;
  if(strstr(yytext,"%%tth:")==yytext){TTH_SCAN_STRING(yytext+6);}
  else if(strstr(yytext,"%%ttm:")==yytext){TTH_SCAN_STRING(yytext+6);}
  else{ 
    if(tth_debug&64) fprintf(stderr,"Comment:%s",yytext);
  }
 }

{CMNT}  {
  TTH_INC_LINE;
  if(strstr(yytext,"%%tth:")==yytext){TTH_SCAN_STRING(yytext+6);}
  else if(strstr(yytext,"%%ttm:")==yytext){TTH_SCAN_STRING(yytext+6);}
  else{ 
    if(tth_debug&64) fprintf(stderr,"Comment:%s",yytext);
    if(horizmode) horizmode=-1;
    yy_push_state(parcheck);
  }
 }

 /* escgroup explicitly ignores comment removal and other special chars.*/
<escgroup>(%|#)  strcat(dupstore,"\\");strcat(dupstore,yytext); 
 /* Don't escape things already escaped*/
<escgroup>(\\%|\\#)  strcat(dupstore,yytext); 
 /*********************************************************************/
 /* Date information needs to be before conditionals. */
\\tth_today {
  time(&thetime);
  strcpy(scratchstring,ctime(&thetime));
  strcpy(scratchstring+10,", ");
  TTH_OUTPUT(scratchstring+4);
  TTH_OUTPUTH(scratchstring+20);
 }

 /* Act as if these are counters */
<getifnum>(\\month|\\year|\\day) {
  yyless(0);
  TTH_SCAN_STRING("\\number");
}

<number>\\year {
  time(&thetime);
  timestruct=*localtime(&thetime);
  timestruct.tm_year= timestruct.tm_year+1900;
  sprintf(scrstring,"%d",timestruct.tm_year);
  /* Remove space afterwards*/ 
  TTH_PUSH_BUFF(1);yy_scan_string(scrstring);
  yy_pop_state();
}
<number>\\month {
  time(&thetime);
  timestruct=*localtime(&thetime);
  sprintf(scrstring,"%d",timestruct.tm_mon+1);
  TTH_PUSH_BUFF(1);yy_scan_string(scrstring);
  yy_pop_state();
}
<number>\\day {
  time(&thetime);
  timestruct=*localtime(&thetime);
  sprintf(scrstring,"%d",timestruct.tm_mday);
  TTH_PUSH_BUFF(1);yy_scan_string(scrstring);
  yy_pop_state();
}

 /***********************************************************************/
  /* Conditionals*/
\\newif{SP}*\\if[a-zA-Z@]+ {
  strcpy(scratchstring,strstr(yytext,"\\if")+3);
  sprintf(scrstring,"\\def\\if%s{\\iffalse}\\def\\%sfalse{\\%dfalse}\\def\\%strue{\\%dtrue}",scratchstring,scratchstring,nkeys,scratchstring,nkeys);
  TTH_SCAN_STRING(scrstring);
}
\\[0-9]*false {
  sscanf(yytext+1,"%d",&js2);
  strncpy(defs[js2]+3,"false",5);
}
\\[0-9]*true {
  sscanf(yytext+1,"%d",&js2);
  strncpy(defs[js2]+3,"true ",5);
}

<hamper,mamper,hendline,xpnd,getsubp>\\iftt[hm]{TSP}* |
\\iftt[hm]{TSP}* |
<hamper,mamper,hendline,xpnd,getsubp>\\iftrue{TSP}* |
\\iftrue{TSP}*   if(tth_debug&1024)fprintf(stderr,"Starting %s.\n",yytext);

<falsetext,ortext,innerfalse>\\%
<equation>\\if[hv]mode*{TSP}  |
<falsetext,innerfalse>\\if[a-z@]* {
  yy_push_state(innerfalse);
  if(tth_debug&1024)fprintf(stderr,"Starting inner \\if in falsetext.\n");
}
\\ifmmode{TSP}*        |
<hamper,mamper,hendline,xpnd,getsubp>\\iffalse{TSP}*
\\iffalse{TSP}* {
  yy_push_state(falsetext);
  if(tth_debug&1024)fprintf(stderr,"Starting \\iffalse.\n");
}
\\ifvmode{TSP}*   if(horizmode) yy_push_state(falsetext);
\\ifhmode{TSP}*   if(!horizmode) yy_push_state(falsetext);

<hamper,mamper,hendline,xpnd,getsubp>\\fi{TSP}* |
\\fi{TSP}*   {
  if(tth_debug&1024)fprintf(stderr,"Ending true clause \\if\\fi.\n");
  if(horizmode)horizmode=1;
}
<hamper,mamper,hendline,xpnd,getsubp,embracetok,optdetect,macarg,optag>\\else{TSP}* |
\\else{TSP}* {
  if(tth_debug&1024)fprintf(stderr,"Ending true clause \\if\\else\n");
  yy_push_state(falsetext);
  if(horizmode)horizmode=1;
}
<falsetext>\\else  {
  yy_pop_state();
  if(tth_debug&1024)fprintf(stderr,"Ending false clause \\if\\else.\n");
  if(horizmode)horizmode=1;
  yy_push_state(removespace);
}
<falsetext,innerfalse>\\fi[a-zA-Z@]+   /* Don't misinterpret other commands. */
<falsetext,innerfalse>\\fi{TSP}* {
  yy_pop_state(); 
  if(tth_debug&1024)fprintf(stderr,"Ending false clause \\if\\fi.\n");
  if(horizmode)horizmode=1;
}
<falsetext,innerfalse>. 

\\or    yy_push_state(innerfalse);
<ortext>\\or   yy_pop_state(); if(tth_debug&1024)fprintf(stderr,"\\or ");
<ortext>\\if[a-z]*    yy_push_state(innerfalse); /* Ignore nested ifs */
<ortext>#tthorbreak  {
 yy_pop_state(); if(tth_debug&1024)fprintf(stderr,"#tthorbreak\n");
 TTH_SCAN_STRING(yytext);
 }
<ortext>\\else  |
<ortext>\\fi   {
  if(tth_debug&1024)fprintf(stderr,"%s ortext\n",yytext);
  TTH_SCAN_STRING("#tthorbreak");}
<ortext>.   /*fprintf(stderr,"ortext ");*/

<orbreak>#tthorbreak   {
  yy_pop_state(); if(tth_debug&1024)fprintf(stderr,"#orbreak end\n");}
<orbreak>.  {
  yyless(0); 
  yy_pop_state(); if(tth_debug&1024)fprintf(stderr,"Orbreak exit\n");}

<hamper,mamper,hendline,xpnd,getsubp>\\ifnum  |
\\ifnum                                |
<hamper,mamper,hendline,xpnd,getsubp>\\ifodd  |
\\ifodd                                |
<hamper,mamper,hendline,xpnd,getsubp>\\ifcase |
\\ifcase   {
  yy_push_state(getifnum);strcpy(strif,yytext);yy_push_state(removespace);}
<getifnum>\\the{SP}* |       /* Kludge for now.*/
<getifnum>\\number{SP}*     yy_push_state(number);jscratch=0;
<getifnum>[0-9]* TTH_CCAT(strif,yytext);
<getifnum>\\[a-zA-Z@]+              { 
  TTH_DO_MACRO
  else if( (ind=indexkey(yytext,countkeys,&ncounters)) != -1) { 
    if(tth_debug&1024)fprintf(stderr,"If Counter %d, %s\n",ind,countkeys[ind]);
    sprintf(scratchstring,"%d ",counters[ind]);
    TTH_PUSH_BUFF(1);yy_scan_string(scratchstring); /* remove spaces */
  } else {
    yyless(0);
    TTH_SCAN_STRING("#"); /*Termination Sign*/
  }
 }
<getifnum>(<|>|=)  TTH_CCAT(strif,yytext);yy_push_state(removespace);
<getifnum>{WSP}  /*Oct 2001.*/
<getifnum>. {
  yy_pop_state();
  if(*yytext != '#') {yyless(0);}
  if(tth_debug&1024)fprintf(stderr,"strif text:%s\n",strif);
  chs2=strif+strcspn(strif,"0123456789");
  if(strstr(strif,"\\ifnum")){
    chscratch=chs2+strcspn(chs2,"<>=");
    sscanf(chs2,"%d",&jscratch);
    sscanf(chscratch+1,"%d",&js2);
    switch(*chscratch){
    case '<': if(!(jscratch<js2)) yy_push_state(falsetext);break;
    case '=': if(!(jscratch==js2)) yy_push_state(falsetext);break;
    case '>': if(!(jscratch>js2)) yy_push_state(falsetext);break;
    }
  }else if(strstr(strif,"\\ifodd")){
    sscanf(chs2,"%d",&jscratch);
    if(!(jscratch & 1)) yy_push_state(falsetext);break; /* even */
  }else if(strstr(strif,"\\ifcase")){
   sscanf(chs2,"%d",&jscratch);
   yy_push_state(orbreak);
   for(js2=1;js2<=jscratch;js2++) yy_push_state(ortext);
  }
}

<hamper,mamper,hendline,xpnd,getsubp>\\if |
\\if   yy_push_state(getiftok);*strif=0;  yy_push_state(removespace);
<getiftok>\\[a-zA-Z@]+              { 
  TTH_DO_MACRO
  else{
    if(tth_debug&1024) fprintf(stderr,
      "**** Unknown or unexpandable command %s as \\if test token. Line %d\n",yytext,tth_num_lines); 
    if(strlen(strif) > 1){
      yy_pop_state();
      if(!(strlen(strif)==strlen(yytext) && strstr(strif,yytext)))
	yy_push_state(falsetext);
    }else strcat(strif,yytext);
  }
}
<getiftok>{ANY} {
  if(strcspn(yytext,"\n")==0) TTH_INC_LINE;
  if(strlen(strif)){
    yy_pop_state();
    if(!(strlen(strif)==strlen(yytext) && strstr(strif,yytext)))
      yy_push_state(falsetext);
  }else strcat(strif,yytext);
}

<hamper,mamper,hendline,xpnd,getsubp>\\ifx |
\\ifx  yy_push_state(getifx);*strif=0;  yy_push_state(removespace);
<getifx>{ANY}         |
<getifx>\\[a-zA-Z@]+              {
  if(strcspn(yytext,"\n")==0) TTH_INC_LINE;
  if(tth_debug&1024) fprintf(stderr,"\\ifx comparison argument:%s\n",yytext);
  if(strlen(strif)){ /* Terminate */
    yy_pop_state();
    js2=0;
    if(strlen(strif)>1) {
      if(strlen(yytext)>1){ /* Both apparently command strings */
	if(strlen(strif)==strlen(yytext) && strstr(strif,yytext))js2=1;
	if(((ind=indexkey(yytext,keys,&nkeys))!=-1) ==
	   ((i=indexkey(strif,keys,&nkeys))!=-1)){
	  if((tth_debug&1024)&&(i>=0))
	    fprintf(stderr,"Comparing:%d:%d:%s:%s:\n",i,ind,defs[i],defs[ind]);
	  if(i==ind)js2=1; else if(strstr(defs[i],defs[ind])==defs[i]) js2=1;
	}else if((ind=indexkey(yytext,countkeys,&ncounters))!=-1)/*counters*/
	  if(ind == indexkey(strif,countkeys,&ncounters))js2=1;
      }
    }else if(strlen(yytext)==1){ /* Both single characters */
      if(*strif==*yytext) js2=1;
    }
    if(!js2){ 
      if(tth_debug&1024) fprintf(stderr,"ifx FALSE\n");
      yy_push_state(falsetext);
    }else if(tth_debug&1024) fprintf(stderr,"ifx TRUE\n");
  }
  if(strlen(yytext) > 1)yy_push_state(removespace);
  strcpy(strif,yytext);
}
 /********************************************************************/
 /* Equation Code */
 /*equationhl*/
 /* *************   LaTeX Math constructs.     ***********************/

\\begin\{equation\*?\}  |
\\begin\{displaymath\}  |
\\\[ {    /* Latex display equations */
  if(tth_debug&3)fprintf(stderr,"Latex display eqn %d\n",equatno);
  displaystyle=1;
  /* Not needed now that empty div is used.
  if(tth_htmlstyle&2){
    TTH_OUTPUT(closing); strcpy(closing,"</div>");
    TTH_OUTPUT("\n<div class=\"p\">\n");
    }*/
  horizmode=0;
  strcpy(eqstr,"");
  eqclose=0;
  mkkey(eqstr,eqstrs,&eqdepth);
  TTH_PUSH_CLOSING;
  if(!strstr(tth_font_open[tth_push_depth],TTH_ITALO)){
    TTH_CCAT(tth_font_open[tth_push_depth],tth_font_open[0]);
    TTH_CCAT(tth_font_close[tth_push_depth],tth_font_close[0]);
  }
  yy_push_state(equation);
  if( (strlen(yytext)>2) && *(yytext+7)=='e'){
    if(*(yytext+strlen(yytext)-2)!='*') {
      equatno++;  
      strcpy(environment,"equation");
      sprintf(envirchar,"%d",equatno);
    }else if(tth_multinum) *envirchar=0;
  }
  if(tth_debug&2) fprintf(stderr,"envirchar=%s, tth_multinum=%d, equatno=%d\n",
	  envirchar,tth_multinum,equatno);
  TTH_SCAN_STRING("{"); /*OCT*/
 }
 /* begin (inline) math moved after the close math */
\\begin\{eqnarray\*?\} { /* Assume this is NOT inside \math */
  if(strstr(yytext,"*") != NULL){
    eqalignlog=1; tth_multinum++; /* No row numbering. No end numbering */
  } else eqalignlog=0;
  if(tth_debug&2)fprintf(stderr,
			 "eqnarray: eqalignlog=%d, tth_multinum=%d yytext=%s\n",
			 eqalignlog,tth_multinum,yytext); 
  TTH_SCAN_STRING("\\begin{equation}\\eqalign{");
 }


 /* **********************   LateX Non Math  ********************************/
\\begin\{document\} { /* Check for aux file. If present input. */
  tth_LaTeX=1;
  if(tth_splitfile)strcpy(filechar,"index.html"); /*sf*/
  if(strlen(tth_latex_file)){
    TTH_CCPY(argchar,tth_latex_file);strcat(argchar,".aux");
    if( (tth_inputfile=fopen(argchar,"r")) != NULL){
      tth_prefix("\\input ",argchar,eqstore);
      TTH_SCAN_STRING(argchar);
      fclose(tth_inputfile);tth_inputfile=NULL;
    } else{
      fprintf(stderr,"No auxiliary LaTeX file found: %s\n",argchar);
      /* New automatic auxfile section.*/
      if(tth_autopic){
	fprintf(stderr,
    "...trying to run latex, logfile=%s.tlg. This may take a moment ...\n",
		tth_latex_file);
	sprintf(scratchstring,
		"latex -interaction=batchmode %s >%s.tlg",
		tth_latex_file,tth_latex_file);
	if((js2=system(scratchstring))!=SUCCESS)
        fprintf(stderr,"...latex returned: %d indicating error(s) in the tex file.\n",js2);
	if( (tth_inputfile=fopen(argchar,"r")) != NULL){
	  tth_prefix("\\input ",argchar,eqstore);
	  TTH_SCAN_STRING(argchar);
	  fclose(tth_inputfile);tth_inputfile=NULL;
	  fprintf(stderr,"...latex seems to have created the aux file.\n");
	}else{
	  fprintf(stderr,"**** System call:%s failed to create aux file.\n**** You probably don't have latex installed.\n",
		  scratchstring);
	  fprintf(stderr,"**** Continuing, but any forward references etc. will be incorrect.\n");
	}
	/* End of auto aux section.*/
      }
    }    
    argchar[0]=0;
  }else{
    fprintf(stderr,
      "Latex base filename blank. Auxiliary files will not be found.\n");
  }
    TTH_PUSH_CLOSING;TTH_CCPY(closing,"");
  /* {TTH_PAR_ACTION} Not here because of titles etc. */
  horizmode=0;
 }
\\makeindex {/* Open index tid file for writing and start to do so. */
  if(strlen(tth_latex_file)){
    strcpy(scratchstring,tth_latex_file);strcat(scratchstring,".tid");
    if( (tth_indexfile=fopen(scratchstring,"w")) ){
      fprintf(stderr,"Opened index file: %s\n",scratchstring);
      /* Open the makeindex style file. Or use default compositor.*/
      strcpy(scratchstring,tth_latex_file);strcat(scratchstring,".tms");
      if( (tth_indexstyle=fopen(scratchstring,"w")) ){
	strcpy(page_compositor,".");
	fprintf(tth_indexstyle,"page_compositor \"%s\"\n",page_compositor);
	fclose(tth_indexstyle);
      }
    } else {
      fprintf(stderr,"**** Failed to open index file: %s Line %d\n",scratchstring,tth_num_lines);
    }
  }
 }

\\tthgpindex { /* Version to grab whole thing even special chars*/
  *dupstore=0;
  *argchar=0;
  yy_push_state(indexgroup);
  storetype=99; /* Just leave in dupgroup to be dealt with by prior state*/
  yy_push_state(uncommentgroup);
  bracecount=-1;
}
<indexgroup>.|\n { /* \index action on group stored in dupstore. */
  yyless(0);
  yy_pop_state();
  if(horizmode) horizmode=1;
  chscratch=dupstore+1; /* Remove braces.*/
  *(chscratch+strlen(chscratch)-1)=0;
  tthindexrefno++;
  if(tth_indexfile != NULL){
    strcpy(scratchstring,chscratch);
    *(scratchstring+strcspn(scratchstring,"|@"))= 0  ;
  /*Here we should remove spaces and special characters in a version
    of scratchstring to be used as the name. Because (quoting) ID and
    NAME tokens must begin with a letter ([A-Za-z]) and may be
    followed by any number of letters, digits ([0-9]), hyphens ("-"),
    underscores ("_"), colons (":"), and periodsx(".").  This means
    the unallowed characters are: "\n\t_!\"#$%&'()*+,/;<=>?[\\]^`{|}~" */
    /* This version replaced only ! 
    while(strlen(scratchstring)-strcspn(scratchstring,"!"))
    *(scratchstring+strcspn(scratchstring,"!")) = '+';   */
    while(strlen(scratchstring)
	  -strcspn(scratchstring,"\n\t !\"#$%&'()*+,/;<=>?[\\]^`{|}~"))
      *(scratchstring
	+strcspn(scratchstring,"\n\t !\"#$%&'()*+,/;<=>?[\\]^`{|}~")) = '_';
    strcpy(scrstring,chscratch);
    *(scrstring+strcspn(scrstring,"|"))= 0 ; /* remove all number formatting */
    if(lbook){
      if(appendix)sprintf(argchar,"%c",chapno+64);
      else sprintf(argchar,"%d",chapno);
      if(strstr(chscratch,"|see")==NULL){
	if(tth_splitfile)	fprintf(tth_indexfile, /*sf*/
		"\\indexentry{%s|href{%s#%s%s%d%d}}{%s%s%d}\n", /*sf*/
		   scrstring,filechar,scratchstring,/*sf*/
			 argchar,sectno,tthindexrefno,/*sf*/
			 argchar,page_compositor,sectno); else /*sf*/
	fprintf(tth_indexfile,
		     "\\indexentry{%s|href{#%s%s%d%d}}{%s%s%d}\n",
		scrstring,scratchstring,
		argchar,sectno,tthindexrefno,
		argchar,page_compositor,sectno);
	fprintf(tth_fdout,"<a \nid=\"%s%s%d%d\"></a>",
		scratchstring,argchar,sectno,tthindexrefno);
      }else{ /* A |see case */
	fprintf(tth_indexfile,
		"\\indexentry{%s}{%s%s%d}\n",chscratch,
		argchar,page_compositor,sectno);      }
    }else {
      if(appendix)sprintf(argchar,"%c",sectno+64);
      else sprintf(argchar,"%d",sectno);
      if(strstr(chscratch,"|see")==NULL){
	if(tth_splitfile) fprintf(tth_indexfile, /*sf*/
	      "\\indexentry{%s|href{%s#%s%s%d%d}}{%s%s%d}\n", /*sf*/
	       scrstring,filechar,scratchstring, /*sf*/
				  argchar,subsectno,tthindexrefno, /*sf*/
			 argchar,page_compositor,subsectno); else /*sf*/
	   fprintf(tth_indexfile,
		  "\\indexentry{%s|href{#%s%s%d%d}}{%s%s%d}\n",
		  scrstring,scratchstring,
		   argchar,subsectno,tthindexrefno,
		   argchar,page_compositor,subsectno);
	fprintf(tth_fdout,"<a \nid=\"%s%s%d\"></a>"
		,scratchstring,argchar,subsectno);
      }else{ /* A |see case */
	fprintf(tth_indexfile,
		"\\indexentry{%s}{%s%s%d}\n",chscratch,
		argchar,page_compositor,subsectno);
      }
    }
    *argchar=0;
  }
  *dupstore=0;
}

\\printindex { /* Check for file. If present put title and open */
  if(tth_indexfile !=NULL){
    fprintf(stderr,"Closing index file and processing ...\n");
    fclose(tth_indexfile);
    tth_indexfile=NULL;/* Omitting this caused segfaults during
			  footnote wrap if there are index entries in
			  footnotes. I guess because one tries to
			  write to fclosed file. In any case those
			  entries aren't entered into index. Fixme.*/
    if(*tth_index_cmd){
      if(strstr(tth_index_cmd," ")){/* Command with spaces is complete format*/
	sprintf(scratchstring,
		tth_index_cmd,tth_latex_file,tth_latex_file,tth_latex_file);
      }else{/* No spaces: just the makeindex command */
	sprintf(scratchstring,"%s -o %s.tin %s.tid",
		tth_index_cmd,tth_latex_file,tth_latex_file);
      }
    }else sprintf(scratchstring,"makeindex -o %s.tin -s %s.tms %s.tid",
		 tth_latex_file,tth_latex_file,tth_latex_file);
    jscratch=system(scratchstring);
    if(jscratch != SUCCESS){
      fprintf(stderr,"**** System call failed: %s**** Index not made.\n"
	      ,scratchstring);
    }
    strcpy(scratchstring,"(showing section)");
  } else *scratchstring=0;
  /* Get the index anyway */
  sprintf(argchar,"\n\\special{html:<a id=\"tth_sEcindex\"></a>\n}\\beginsection{\\indexname{ %s}}\\par\\input %s.tin",
	  scratchstring,tth_latex_file);
  TTH_SCAN_STRING(argchar);
  argchar[0]=0;
  if(tth_splitfile){ /*sf*/
    strcpy(filenext,"docindex.html");/*sf*/
    TTH_SCAN_STRING("\\tthsplittail\\tthsplitinv\\tthsplittop\\tthfileupd"); /*sf*/
  }/*sf*/
 }
\\tableofcontents { /* Check for file. If present put title and open */
  TTH_CCPY(argchar,tth_latex_file);TTH_CCAT(argchar,".toc");
  if( (tth_inputfile=fopen(argchar,"r")) != NULL){
    fclose(tth_inputfile);tth_inputfile=NULL;
    sprintf(scratchstring,"\\htmlheader{1}{\\contentsname{ }}\\input %s ",
	    argchar);
    if(tth_indexfile) {TTH_PUSH_BUFF(11);} else /*get extra code*/ 
    {TTH_PUSH_BUFF(0);} /*braces required*/
    yy_scan_string(scratchstring);
  }
  argchar[0]=0;
 }
\\listoftables { /* Check for file. If present put title and open */
  TTH_CCPY(argchar,tth_latex_file);strcat(argchar,".lot");
  if( (tth_inputfile=fopen(argchar,"r")) != NULL){
    tth_prefix("\\htmlheader{1}{\\listtablename{ }}\\input ",argchar,eqstore);
    TTH_SCAN_STRING(argchar);
    fclose(tth_inputfile);tth_inputfile=NULL;
  }
  tbno=0;/*sf*/
  argchar[0]=0;
 }
\\listoffigures { /* Check for file. If present put title and open */
  TTH_CCPY(argchar,tth_latex_file);strcat(argchar,".lof");
  if( (tth_inputfile=fopen(argchar,"r")) != NULL){
    tth_prefix("\\htmlheader{1}{\\listfigurename{ }}\\input ",argchar,eqstore);
    TTH_SCAN_STRING(argchar);
    fclose(tth_inputfile);tth_inputfile=NULL;
  }
  fgno=0;/*sf*/
  argchar[0]=0;
 }
\\@writefile{NLC}*{NL}  { /*Processing aux file*/
  TTH_INC_LINE
  if(strstr(yytext,"toc}{\\contentsline")==yytext+12){  /*sf*/
    /* Updating section label*/ /*sf*/
    if( (chscratch=strstr(yytext,"numberline {"))!=NULL){  /*sf*/
      strncpy(schar,(chscratch+12),2); /*max: 2 digit number*/ /*sf*/
      *(schar+strcspn(schar,"}."))=0; /*sf*/
    } /*sf*/
  }else if(strstr(yytext,"lof}{\\contentsline")){ /*sf*/
    if(fgno < TNO) mkkey(schar,fchar,&fgno); /*sf*/ 
    else fprintf(stderr,"Too many figures"); /*sf*/
  }else if(strstr(yytext,"lot}{\\contentsline")){ /*sf*/
    if(tbno < TNO) mkkey(schar,tchar,&tbno); /*sf*/
    else fprintf(stderr,"Too many tables"); /*sf*/
  } /*sf*/
}
\\contentsline{SP}*\{[a-z]*\}\{(\\numberline{SP}{BRCG})?   {
  horizmode=1;
  *scrstring=0;
  if(tth_debug&128) fprintf(stderr,"Contentsline %s\n",yytext);
  strcpy(refchar,"tth_sEc");
  if(strstr(yytext,"{chapter}")!=NULL){ 
    chaplog=4;strcpy(refchar,"tth_chAp");
  }else if(strstr(yytext,"{table}")!=NULL){
    strcpy(refchar,"tth_tAb");
    for(i=0;i<4;i++) strcat(scrstring,"&nbsp;");    
  }else if(strstr(yytext,"{figure}")!=NULL){
    strcpy(refchar,"tth_fIg");
    for(i=0;i<4;i++) strcat(scrstring,"&nbsp;");    
  }else if(strstr(yytext,"{section}")!=NULL){
    for(i=0;i<chaplog;i++) strcat(scrstring,"&nbsp;");
  }else if(strstr(yytext,"{subsection}")!=NULL){
    for(i=-4;i<chaplog;i++) strcat(scrstring,"&nbsp;");
  }else{ /* if(strstr(yytext,"{subsubsection}")!=NULL) all lower levels*/
    for(i=-8;i<chaplog;i++) strcat(scrstring,"&nbsp;");
  }
  if((chscratch=strstr(yytext,"\\numberline"))!=NULL){
    *(chscratch+strlen(chscratch)-1)=0;
    chscratch=chscratch+strcspn(chscratch,"{")+1;
    if(tth_splitfile){ /*sf*/
      if(strstr(yytext,"{section}")!=NULL){ /*sf*/
	if(tth_splitfile==2 || *auxflch==0){ /*sf*/
	  tth_splitfile=2;                    /*sf*/
	  sprintf(auxflch,"sec%s",chscratch); /*sf*/
	  *(auxflch+strcspn(auxflch,"."))=0;  /*sf*/
	  strcat(auxflch,".html"); /*sf*/
	} /*sf*/
      }else if(strstr(yytext,"{chapter}")!=NULL){ /*sf*/
	sprintf(auxflch,"chap%s.html",chscratch);  /*sf*/
      }else if(strstr(yytext,"{table}")!=NULL){  /*sf*/
       if(*(auxflch)=='c')sprintf(auxflch,"chap%s.html",tchar[tbno++]);/*sf*/
       else sprintf(auxflch,"sec%s.html",tchar[tbno++]);/*sf*/
      }else if(strstr(yytext,"{figure}")!=NULL){  /*sf*/
       if(*(auxflch)=='c')sprintf(auxflch,"chap%s.html",fchar[fgno++]);/*sf*/
       else sprintf(auxflch,"sec%s.html",fchar[fgno++]);/*sf*/
      } /*sf*/
    } /*sf*/
    fprintf(tth_fdout,"%s<a href=\"%s#%s%s\"\n>%s&nbsp; ",
	   scrstring,auxflch,refchar,chscratch,chscratch);
    TTH_TEX_FN("{#1}\\special{html:</a><br />}\\tthunknown#tthdrop2",2);
  }else{
    if(strstr(yytext,"{part}")){/*Only enter unnumbered line if part*/ 
      TTH_TEX_FN("{#1}\\special{html:<br />}\\tthunknown#tthdrop2",2);
    }else{TTH_TEX_FN("\\tthunknown#tthdrop2",2);}
  }
  unput('{');          /* Already in first group. */
}
\\cite{WSP}*(\[[^\{\]]*\])?{BRCG} {
  TTH_INC_MULTI;
  js2=strcspn(yytext,"{");
  strcpy(dupstore,yytext+js2+1);
  if(tth_debug&256) fprintf(stderr,"Citations:%s\n",dupstore);
  i=0;ind=-1;
  strcpy(dupstore2,"\\tthciteob");
  for(jargmax=0;jargmax<30;jargmax++){
/*      ind=ind+i+1; */
    ind=ind+i+1+strspn(dupstore+ind+i+1,", \t\n");/*Advance to start of next*/
    js2=strcspn(dupstore+ind,"},\t\n"); /*Termination of key*/ 
    i=js2+strspn(dupstore+ind+js2," \t\n"); /* Next divider*/
    *(dupstore+ind+js2)=0;
    jarg=indexkey(dupstore+ind,keys,&nkeys);
    if(jarg == -1) {
      fprintf(stderr,"No bibcite for %s\n",dupstore+ind);
    }else{
      if(ckeys[jarg]==0){
	if(tth_splitfile)sprintf(dupstore2+strlen(dupstore2),/*sf*/
	   "\\special{html:<a href=\"refs.html#%s\" id=\"CITE%s\" class=\"tth_citation\">}",/*sf*/
		     dupstore+ind,dupstore+ind);else  /*sf*/
	  sprintf(dupstore2+strlen(dupstore2),
		    "\\special{html:<a href=\"#%s\" id=\"CITE%s\" class=\"tth_citation\">}",
		   dupstore+ind,dupstore+ind);
	ckeys[jarg]++;
      }else{
	if(tth_splitfile)sprintf(dupstore2+strlen(dupstore2),/*sf*/
	   "\\special{html:<a href=\"refs.html#%s\" class=\"tth_citeref\">}",/*sf*/
		     dupstore+ind);else  /*sf*/
	  sprintf(dupstore2+strlen(dupstore2),
		    "\\special{html:<a href=\"#%s\" class=\"tth_citeref\">}",
		   dupstore+ind);
      }
      strcpy(scratchstring,defs[jarg]);
      if((chscratch=strstr(scratchstring,"#tthdrop0"))) *chscratch=0;
      /* New operator on the bibcite */
      strcat(dupstore2,"\\tthciteform ");
      strcat(dupstore2,scratchstring);
      strcat(dupstore2,"\\special{html:</a>}");
      if(!nargs[jarg]){ 
	if(lbook)jscratch=chapno; else jscratch=sectno;
	if(appendix) nargs[jarg]=jscratch+64;
	else nargs[jarg]=jscratch;
	js2=jarg;
	mkkey(filechar,optargs,&js2);
      }
    }
    if(*(dupstore+ind+i+1)){
      strcat(dupstore2,"\\tthcitepb");
    } else { /* Exhausted citations */
      js2=strcspn(yytext,"{");
      if((jscratch=strcspn(yytext,"[")) < js2-2){
	strcat(dupstore2,"\\tthcitefi{}");
	strncat(dupstore2,yytext+jscratch+1,js2-jscratch-2);
      }
      strcat(dupstore2,"\\tthcitecb{}");
      jargmax=30;
    }
  }
  if(tth_debug&256)fprintf(stderr,"Rescanning citations:\n%s\n",dupstore2);
  TTH_SCAN_STRING(dupstore2);
  i=0;ind=0;jarg=0;jargmax=0; *dupstore=0; *dupstore2=0;
}

\\begin\{thebibliography\} TTH_TEX_FN("\\tth_thebibliography#tthdrop1",1);
\\tth_thebibliography {
  if(lbook)  {TTH_SCAN_STRING("\\special{html:<h2>}\\bibname\\special{html:</h2>\n}\\begin{description}");}
  else {TTH_SCAN_STRING("\\special{html:<h2>}\\refname\\special{html:</h2>\n}\\begin{description}");}
  if(tth_splitfile){ /*sf*/
    if(!bibliogs) strcpy(filenext,"refs.html"); /*sf*/
    else sprintf(filenext,"refs%d.html",bibliogs); /*sf*/
    bibliogs++; /*sf*/
    TTH_SCAN_STRING("\\tthsplittail\\tthsplitinv\\tthsplittop\\tthfileupd"); /*sf*/
  }/*sf*/
  TTH_SCAN_STRING("\\par");
 }

<Ldescription>\\bibitem TTH_TEX_FN_OPT("\\tthbibitem{#2}#tthdrop2",2,"");
<Ldescription>\\tthbibitem{BRCG} {
  TTH_INC_MULTI;
  TTH_OUTPUT(closing);strcpy(closing,"</dd>\n"); /*27 Apr 2001 */
  fprintf(tth_fdout," <dt>");
  strcpy(dupstore,yytext);
  *(dupstore+strlen(dupstore)-1)=0;
  if((chs2=strstr(dupstore,"]"))==NULL) chs2=dupstore;
  chs2=chs2+strcspn(chs2,"{")+1; 
  jarg=indexkey(chs2,keys,&nkeys);
  if(jarg== -1){
    fprintf(stderr,"Unknown bibitem %s\n",chs2);
    fprintf(tth_fdout,"[]</dt><dd>");
  }else{
    *(scratchstring)=0;
    if(tth_splitfile){  /*sf*/
      if(!optargs[jarg])  /*sf*/
	{fprintf(stderr,"**** Error: Null bibitem optarg (file)\n");}else/*sf*/
      strcpy(scratchstring,optargs[jarg]); /*sf*/
    } /*sf*/
      /* New operator on the bibcite */
    strcpy(scrstring,"\\tthbibform ");
    strcat(scrstring,defs[jarg]);
    if((chscratch=strstr(scrstring,"#tthdrop"))) *chscratch=0;/* huh?*/
    strcat(scrstring,"\\tthbibcb");
    strcat(scrstring,"}");
    TTH_PUSH_CLOSING;  strcpy(closing,"</a></dt><dd>");
    fprintf(tth_fdout,"<a href=\"%s#CITE%s\" id=\"%s\">",scratchstring,chs2,chs2);
    TTH_SCAN_STRING(scrstring);
  }
  jarg=0;*dupstore=0;
 }
\\bibliography{BRCG} { /* Input the bbl file. */
  TTH_CCPY(argchar,tth_latex_file);strcat(argchar,".bbl");
  if( (tth_inputfile=fopen(argchar,"r")) != NULL){
    tth_prefix("\\input ",argchar,eqstore);
    TTH_SCAN_STRING(argchar);
    fclose(tth_inputfile);tth_inputfile=NULL;
  }else{
      if(tth_autopic){
	fprintf(stderr,
	   "**** No bibliography file %s found. Trying to create.\n",argchar);
      /* New automatic bbl file section.*/
	fprintf(stderr,
    "...trying to run latex, logfile=%s.tlg. This may take a moment ...\n",
		tth_latex_file);
	sprintf(scratchstring,"latex -interaction=batchmode %s >%s.tlg",
		tth_latex_file,tth_latex_file);
	if((js2=system(scratchstring))!=SUCCESS)
        fprintf(stderr,"...latex returned: %d indicating error(s) in the tex file.\n",js2);
	fprintf(stderr,"...trying to run bibtex ...\n");
	sprintf(scrstring,"bibtex %s",tth_latex_file);
	if(system(scrstring)!=SUCCESS)fprintf(stderr,"Bibtex failed\n");
	if(system(scratchstring)!=SUCCESS){};
	if( (tth_inputfile=fopen(argchar,"r")) != NULL){
	  tth_prefix("\\input ",argchar,eqstore);
	  TTH_SCAN_STRING(argchar);
	  fclose(tth_inputfile);tth_inputfile=NULL;
	  fprintf(stderr,"...latex/bibtex have created file. ");
	  fprintf(stderr,"If Unknown bibitem now occurs, rerun tth.\n");
	}else{
	  fprintf(stderr,"**** System calls failed. You probably don't have latex or bibtex installed.\n**** No bbl file created. Bibliography will be incomplete.\n");
	}
      }else{
	/* End of auto bbl section.*/
	fprintf(stderr,
	"**** No bibliography file %s found. Create using latex and bibtex.\n",
		argchar);
      }
  }
  argchar[0]=0;
 }

\\appendix    {
  chapno=0;sectno=0;appendix=1;
  if(lbook) strcpy(scratchstring,
		   "\\renewcommand{\\thechapter}{\\Alph{chapter}}");
  else strcpy(scratchstring,
		   "\\renewcommand{\\thesection}{\\Alph{section}}");
  TTH_SCAN_STRING(scratchstring);
}
\\part\*  {  
  fprintf(tth_fdout,"\n<h1>"); yy_push_state(tokenarg); TTH_CCPY(argchar,"</h1>");
}
\\tthpart  {
  sprintf(scratchstring,"%s\\tthenclose{\\special{html:<br /><h1>}%s{ %s}   \\special{html:<br />}}{\\special{html:</h1><br />}} ",
	  "\\stepcounter{part}",
	  "\\partname","\\thepart");
  TTH_SCAN_STRING(scratchstring);
}
\\chapter\*  {
  fprintf(tth_fdout,"\n<h1>"); yy_push_state(tokenarg); TTH_CCPY(argchar,"</h1>");}
\\tthchapter {
  figureno=0;tableno=0;
  sprintf(labelchar,"%d",chapno+1);
  if(appendix) sprintf(labelchar,"%c",chapno+1+64);
  TTH_SCAN_STRING("\\tthchapcomplete");
  if(tth_splitfile){ /*sf*/
    sprintf(filenext,"chap%s.html",labelchar);/*sf*/
    TTH_SCAN_STRING("\\tthsplittail\\tthsplitinv\\tthsplittop\\tthfileupd"); /*sf*/
  }/*sf*/
}
\\tthfileupd   if(tth_splitfile)  strcpy(filechar,filenext); /*sf*/
\\tthsplitinv {/*sf*/
  fprintf(tth_fdout,TTH_MIME_DIVIDE,filenext);/*sf*/
  fprintf(tth_fdout,TTH_DOCTYPE); /*sf*/
  fprintf(tth_fdout,TTH_GENERATOR,TTH_NAME,TTH_VERSION); /*sf*/
  fprintf(tth_fdout,TTH_ENCODING); /*sf*/
  fprintf(tth_fdout,"%s",TTH_P_STYLE); /*sf*/
  if(tth_istyle)fprintf(tth_fdout,"%s",TTH_STYLE); /*sf*/
  if(!(tth_htmlstyle&4))fprintf(tth_fdout,"%s",TTH_SIZESTYLE); /*sf*/
  fprintf(tth_fdout,"<title>%s</title>\n",filenext);/*sf*/
  if(tth_htmlstyle&3)fprintf(tth_fdout,"</head>\n<body><div>\n");/*sf*/
}/*sf*/
\\tthfilenext fprintf(tth_fdout,"%s",filenext); /*sf*/
\\tthfilechar fprintf(tth_fdout,"%s",filechar); /*sf*/
\\tthchapcomplete {
  if(appendix) {TTH_CCPY(argchar,"\\appendixname");}
  else TTH_CCPY(argchar,"\\chaptername");
  sprintf(scratchstring,"\n\\stepcounter{chapter}\\tthenclose{\
 \\special{html:<a id=\"tth_chAp%s\"></a><h1>}\n%s{ \\thechapter}\
 \\special{html:<br />}}{\\special{html:</h1>}} ",
	  labelchar,argchar);
  TTH_SCAN_STRING(scratchstring);*argchar=0;
}
\\section\*  {   
  fprintf(tth_fdout,"\n<h2>"); yy_push_state(tokenarg); TTH_CCPY(argchar,"</h2>");}
\\tthsection {
  TTH_SCAN_STRING("\\tthsectcomplete");
  if(lbook) {
    sprintf(labelchar,"%d.%d",chapno,sectno+1);
    if(appendix)sprintf(labelchar,"%c.%d",chapno+64,sectno+1);
  }else{
    sprintf(labelchar,"%d",sectno+1);
    if(appendix)sprintf(labelchar,"%c",sectno+1+64);
    if(tth_splitfile){ /*sf*/
      sprintf(filenext,"sec%s.html",labelchar);/*sf*/
      TTH_SCAN_STRING("\\tthsplittail\\tthsplitinv\\tthsplittop\\tthfileupd"); /*sf*/
    }/*sf*/
  }
}
\\tthsectcomplete {
  if(secnumdepth > 0){
    /* the following needs the space at the end for tex compatibility */
    sprintf(scratchstring,"\n\\stepcounter{section}\\tthenclose{\
 \\special{html:<a id=\"tth_sEc%s\"></a><h2>}\n\\thesection\
 \\special{html:&nbsp;&nbsp;}}{\\special{html:</h2>}} ",labelchar);
    TTH_SCAN_STRING(scratchstring);    
  }else{
    fprintf(tth_fdout,"\n<h2>"); 
    yy_push_state(tokenarg); 
    TTH_CCPY(argchar,"</h2>");
  }
}
\\subsection\*  {   
  fprintf(tth_fdout,"\n<h3>"); yy_push_state(tokenarg); TTH_CCPY(argchar,"</h3>");}
\\tthsubsection {
  { 
    if(lbook) {
      if(appendix) sprintf(labelchar,"%c.%d.%d",chapno+64,sectno,subsectno+1);
      else sprintf(labelchar,"%d.%d.%d",chapno,sectno,subsectno+1);
    }else {
      if(appendix) sprintf(labelchar,"%c.%d",sectno+64,subsectno+1);
      else sprintf(labelchar,"%d.%d",sectno,subsectno+1);
    }
    if(secnumdepth > 1){
      sprintf(scratchstring,"\n\\stepcounter{subsection}\\tthenclose{\
     \\special{html:<a id=\"tth_sEc%s\"></a><h3>}\n\\thesubsection\
     \\special{html:&nbsp;&nbsp;}}{\\special{html:</h3>}} ",labelchar);
      TTH_SCAN_STRING(scratchstring);
    }else{
        fprintf(tth_fdout,"\n<h3>"); yy_push_state(tokenarg); TTH_CCPY(argchar,"</h3>");
    }
  }
}
\\subsubsection\*  {   
  fprintf(tth_fdout,"\n<h4>"); yy_push_state(tokenarg); TTH_CCPY(argchar,"</h4>");}
\\tthsubsubsection { 
  {
    if(lbook) {
      if(appendix) sprintf(labelchar,"%c.%d.%d.%d",
			   chapno+64,sectno,subsectno,subsubsectno+1);
      else sprintf(labelchar,"%d.%d.%d.%d",
		   chapno,sectno,subsectno,subsubsectno+1);
    }else {
      if(appendix) sprintf(labelchar,"%c.%d.%d",
			   sectno+64,subsectno,subsubsectno+1);
      else sprintf(labelchar,"%d.%d.%d",sectno,subsectno,subsubsectno+1);
    }
    if(secnumdepth > 2){
      sprintf(scratchstring,"\n\\stepcounter{subsubsection}\\tthenclose{\
      \\special{html:<a id=\"tth_sEc%s\"></a><h4>}\n\\thesubsubsection\
      \\special{html:&nbsp;&nbsp;}}{\\special{html:</h4>}} ",labelchar);
      TTH_SCAN_STRING(scratchstring);
    }else{
      fprintf(tth_fdout,"\n<h4>"); yy_push_state(tokenarg); TTH_CCPY(argchar,"</h4>");
    }
  }
}
\\tthparagraph {
  if(secnumdepth > 3){
    TTH_TEX_FN("\\par\\stepcounter{paragraph}{\\bf\\theparagraph\
 \\special{html:<a id=\"tth_sEc}\\theparagraph\\special{html:\">\n}\
    \\special{html:&nbsp;&nbsp;}#1\\special{html:</a>\n}\\ }#tthdrop1",1);
  }else{
    TTH_TEX_FN("\\par{\\bf#1\\ \\ }#tthdrop1",1);
  }
}
\\tthsubparagraph {
  if(secnumdepth > 4){
    TTH_TEX_FN("\\stepcounter{subparagraph}{\\special{html:<br />}\
    \\quad\\bf\
    \\special{html:<a id=\"tth_sEc}\\thesubparagraph\\special{html:\">\n}\
    \\thesubparagraph\
    \\special{html:&nbsp;&nbsp;}#1\\special{html:</a>\n}\\ }#tthdrop1",1);
  }else{
    TTH_TEX_FN("\\special{html:<br />}{\\quad\\bf#1\\ \\ }#tthdrop1",1);
  }
}

\\tthcaption {
  if(tth_debug&256)fprintf(stderr,"Caption in environment:%s\n",environment);
  if(!strcmp(environment,"figure")){
    figureno++;
    if(lbook) sprintf(envirchar,"%d.%d",chapno,figureno);
    else sprintf(envirchar,"%d",figureno);
    sprintf(scratchstring,"\n\\tthenclose{\\special{html:<div style=\"text-align:center\">}\\figurename{ \\thefigure:} }{\\special{html:</div>}} ");
  }else if(!strcmp(environment,"table")){
    tableno++;
    if(lbook) sprintf(envirchar,"%d.%d",chapno,tableno);
    else sprintf(envirchar,"%d",tableno);
    sprintf(scratchstring,"\n\\tthenclose{\\special{html:<div style=\"text-align:center\">}\\tablename{ \\thetable:} }{\\special{html:</div>}} ");
  }
  TTH_SCAN_STRING(scratchstring);
}
<psub>\\tthnewlabel {
  if(horizmode) horizmode=1;
  jscratch=indexkey("#1",margkeys,&margmax);
  if(tth_debug&256)fprintf(stderr,
    "tthnewlabel jscratch=%d, margs[jscratch]=%s\n",jscratch,margs[jscratch]);
  strcpy(dupstore,margs[jscratch]);
  if(tth_group(scrstring,margs[jscratch+1],TTH_CHARLEN-1)){
    fprintf(stderr,"Label end broken in newlabel:%s\n",margs[jscratch+1]); }
  if(tth_splitfile){ /*sf*/
    if(lbook)strcpy(scratchstring,"chap");  /*sf*/
    else strcpy(scratchstring,"sec"); /*sf*/
    if(strlen(schar)){ /* File defined; use it.*/  /*sf*/
      strcat(scratchstring,schar); /*sf*/
      strcat(scratchstring,".html"); /*sf*/
    }else if(*(scrstring+1)=='}') strcpy(scratchstring,"index.html"); /*sf*/
    else{ /* Should not now come here. */ /*sf*/
      strcat(scratchstring,scrstring+1); /*sf*/
      *(scratchstring+strcspn(scratchstring,".}"))=0; /*sf*/
      strcat(scratchstring,".html"); /*sf*/
      fprintf(stderr, /*sf*/
	     "**** Abnormal newlabel file reference:%s\n",scratchstring);/*sf*/
    } /*sf*/
  }else  /*sf*/
    *scratchstring=0;
  js2=nkeys; /* Just for copying the file name to optargs. */
  narg=*(scrstring+1);
  if(*(scrstring+1)=='}')narg=0;
  else if(narg > 64) narg=-(narg-64); /* Test for appendix */
  else sscanf(scrstring+1,"%d",&narg);
  if(nkeys < NFNMAX) {
    mkkey(scratchstring,optargs,&js2);
    lkeys[nkeys]=0;
    mkdef(dupstore,keys,scrstring,defs,&narg,nargs,&nkeys);
    if(tth_debug&256){
      i=indexkey(dupstore,keys,&nkeys);
      fprintf(stderr,"Defined Label %s, index %d, nargs %d, optarg %s, Def %s\n",
	      dupstore,i,nargs[i],optargs[i],defs[i]);
    }
  }
  else fprintf(stderr,"Too many functions to define %s\n",dupstore);
  *dupstore=0;
 }
<psub>\\tthlabel  { /* Called only by \label latex builtin. */
  if(horizmode) horizmode=1;
  jscratch=indexkey("#1",margkeys,&margmax);
  if(tth_debug&256)fprintf(stderr,"tthlabel jscratch=%d, margs[jscratch]=%s  ",
			  jscratch,margs[jscratch]);
  strcpy(dupstore,margs[jscratch]);
  narg=chapno;
  if(indexkey(dupstore,keys,&nkeys) == -1) {
    if(nkeys < NFNMAX) {
      js2=nkeys;
      mkkey(filechar,optargs,&js2);
      lkeys[nkeys]=0;
      if(strlen(environment))
	mkdef(dupstore,keys,envirchar,defs,&narg,nargs,&nkeys);
      else
	if(strlen(labelchar)) 
	   mkdef(dupstore,keys,labelchar,defs,&narg,nargs,&nkeys);
	else mkdef(dupstore,keys,"*",defs,&narg,nargs,&nkeys);
      if(tth_debug&256){
	i=indexkey(dupstore,keys,&nkeys);
	fprintf(stderr,"\nDefined Label %s index %d nargs %d Def %s\n",
		dupstore,i,nargs[i],defs[i]);
      }
    }
    else fprintf(stderr,"Too many functions to define %s",dupstore);
  }else{
    if(tth_debug&256)fprintf(stderr,"Predefined.\n");
  }
  fprintf(tth_fdout,"<a id=\"%s\">\n</a>",dupstore);
  *dupstore=0;
 }
<psub>\\tthpageref#tthdrop1 |
<psub>\\tthref#tthdrop1 {
  if(horizmode) horizmode=1;
  jscratch=indexkey("#1",margkeys,&margmax);
  if(tth_debug&256) fprintf(stderr,"tthref jscratch=%d, margs[jscratch]=%s\n",
			  jscratch,margs[jscratch]);
  strcpy(dupstore,margs[jscratch]);
  ind=indexkey(dupstore,keys,&nkeys);
  if(ind != -1){
    strcpy(scratchstring, "#tthdrop1\\special{html:<a href=\"");
    if(tth_splitfile){   /*sf*/
      if(!optargs[ind])   /*sf*/
	{fprintf(stderr,"**** Error: Null ref optarg (file)\n");} else/*sf*/
      strcat(scratchstring,optargs[ind]); /*sf*/
    }              /*sf*/
    if(*(yytext+4)=='p'){
      strcpy(scrstring,"pageref");
    }else{ 
      strcpy(scrstring,defs[ind]);
      if(strspn(scrstring," {}")==strlen(scrstring)) strcpy(scrstring,"*");
    }
    sprintf(scratchstring+strlen(scratchstring),
	    "#%s\">}%s\\special{html:</a>}",dupstore,scrstring);
    TTH_SCAN_STRING(scratchstring);
  }else{
    fprintf(stderr,"Unknown Latex \\ref:%s\n",dupstore);
    TTH_SCAN_STRING("#tthdrop1");
  }
  *dupstore=0;*argchar=0;
 }

<builtins,latexbuiltins>\n   TTH_INC_LINE;
<builtins>.  {
  /* These are purely to silence warnings. They are non-functional*/
  PUSHEDINTS[0][0]=0;
  PUSHEDINTDEPTHS[0]=0;
  /* end of warning silencing */
  yy_pop_state();
  yyless(0);
  strcpy(dupstore2,tth_builtins);
  strcat(dupstore2,"\\tthbuiltins");
  TTH_SCAN_STRING(dupstore2);
  *dupstore2=0;
 }
<latexbuiltins>.  {
  yy_pop_state();
  yyless(0);
  strcpy(dupstore2,tth_latex_builtins);
  strcat(dupstore2,tth_latex_builtins2);
  strcat(dupstore2,tth_latex_builtins3);
  strcat(dupstore2,"\\tthlatexbuiltins");
  TTH_SCAN_STRING(dupstore2);
  *dupstore2=0;
  tth_LaTeX=tth_debug+1; /* LaTeX initialization state. */
  if(tth_debug==1) tth_debug--; /* Don't debug builtins */
 }

\\tthcountinit    {
  countstart=ncounters;
  if(tth_debug&512) fprintf(stderr,"Countstart= %d\n",countstart);
}

\\document((class)|(style))(\[[^\]]*\])?{BRCG} {
  TTH_INC_MULTI;
  if(indexkey("\\label",keys,&nkeys) == -1){ /* Only if not already done */
    strcpy(dupstore2,tth_latex_builtins);
    strcat(dupstore2,tth_latex_builtins2);
    strcat(dupstore2,tth_latex_builtins3);
    tth_LaTeX=tth_debug+1; /* LaTeX initialization state. Make non-zero. */
    if(tth_debug==1) tth_debug--; /* Don't debug builtins */
    if(tth_debug&512) fprintf(stderr,"Defining built-in Latex commands\n");
  }
  if(strstr(yytext,"book")||strstr(yytext,"report")) {
    lbook=1;
    strcat(dupstore2,
	   "\\renewcommand{\\thesection}{\\thechapter.\\arabic{section}}");
    strcat(dupstore2,
	   "\\renewcommand{\\thefigure}{\\thechapter.\\arabic{figure}}");
    strcat(dupstore2,
	   "\\renewcommand{\\thetable}{\\thechapter.\\arabic{table}}");
    strcat(dupstore2,"\\setcounter{secnumdepth}{2}");    
    strcat(dupstore2,
	   "\\renewcommand{\\theequation}{\\thechapter.\\arabic{equation}}");
  } else {
    lbook=0;
  }
  strcat(dupstore2,"\\tthlatexbuiltins"); /* signals end of builtins */
  TTH_SCAN_STRING(dupstore2);
  *dupstore2=0;
}

\\usepackage{SP}*(\[[^\{\]]*\])?\{natbib\} {
  TTH_INC_MULTI;
  if(strstr(yytext,"numbers")){TTH_SCAN_STRING("\\NAT@numberstrue ");}
  TTH_SCAN_STRING("\\newif\\ifNAT@numbers\
\\def\\tthbibform#1#2#3#4{\\ifNAT@numbers[#1\\else[#3 #2\\fi}\
\\def\\tthciteform#1#2#3#4{\\ifNAT@numbers[#1\\else#3, [#2\\fi}\
\\def\\tthciteob{}\\def\\tthcitecb{]}\\input tthntbib.sty");
}
\\usepackage{SP}*\{  yy_push_state(matchbrace);

 /* Font faces and styles etc.*/
\\textmd               |
\\textnormal   TTH_SWAP("\\rm ");
\\textbf      TTH_SWAP("\\bf ");
\\textrm      TTH_SWAP("\\rm ");
\\textsl    TTH_SWAP("\\it ");
\\textit  TTH_SWAP("\\it ");
\\texttt  TTH_SWAP("\\tt ");
\\textsf  TTH_SWAP("\\sffamily ");
\\textsc  TTH_SWAP("\\scshape ");
 /*   Now using the halign brace closure */
<textsc>[a-z]*     {
  TTH_OUTPUT(TTH_SMALLCAPS_FONT1);
  for(jscratch=0;jscratch<strlen(yytext);jscratch++) {
    *(yytext+jscratch)=toupper(*(yytext+jscratch));}
  TTH_OUTPUTH(yytext);
  TTH_OUTPUT(TTH_SMALLCAPS_FONT2);horizmode=1;
 }
<textsc>[A-Z] TTH_OUTPUT(yytext);horizmode=1; /* Trying to fix in equations */


\\em{SP}*         TTH_OUTPUT(TTH_EM1);TTH_PRECLOSE(TTH_EM2);
<exptokarg,tokexp>\\emph |
\\emph            TTH_SWAP("\\em ");
\\begin\{em\}      TTH_SCAN_STRING("{\\em ");
\\begin\{verbatim\*?\}      {
  if(horizmode) horizmode=1;
  fprintf(tth_fdout,"\n<pre>"); yy_push_state(verbatim);
  TTH_PUSH_CLOSING;  TTH_CCPY(closing,"\n</pre>");}
\\begin\{center\}  {
  fprintf(tth_fdout,"\n<div style=\"text-align:center\">");  TTH_PUSH_CLOSING;  TTH_CCPY(closing,"</div>");}
\\begin\{flushright\}  {
  if(horizmode) horizmode=1;
  fprintf(tth_fdout,"\n<div align=\"right\">");TTH_PUSH_CLOSING;
  TTH_CCPY(closing,"</div>");}
\\begin\{verse\}  |
\\begin\{quotation\}  |
\\begin\{quote\}  {
  if(horizmode) horizmode=1;
  fprintf(tth_fdout,"\n<blockquote><div>");
  TTH_PUSH_CLOSING;TTH_CCPY(closing,"</div></blockquote>");}
\\begin\{tthabstract\} {
  if(horizmode) horizmode=1;
  TTH_SCAN_STRING("\\beginsection{\\abstractname}\\par");
  TTH_PUSH_CLOSING; /*TTH_CCPY(closing,TTH_PAR);*/
}
\\end\{tthabstract\}   TTH_SCAN_STRING("\\egroup\\par");

\\begin\{itemize\}     {
  horizmode=0;
  fprintf(tth_fdout,"\n<ul>");yy_push_state(Litemize);
  tth_eqwidth=tth_eqwidth-TTH_INDPC;
  TTH_PUSH_CLOSING;
}
{WSP}*\\end\{itemize\}    {
  TTH_INC_MULTI;
  yy_pop_state();
  TTH_OUTPUT(closing);
  fprintf(tth_fdout,"</ul>");
  tth_eqwidth=tth_eqwidth+TTH_INDPC;
  TTH_POP_CLOSING;
  horizmode=1;
}

\\begin\{enumerate\}  {
  horizmode=0;
  fprintf(tth_fdout,"\n<ol type=\"%c\">",
	 enumtype[(enumerate > 4 ? 0 : enumerate)]);
  yy_push_state(Lenumerate);
  enumerate++;
  tth_eqwidth=tth_eqwidth-TTH_INDPC;
  TTH_PUSH_CLOSING;
 }
{WSP}*\\end\{enumerate\}    {
  TTH_INC_MULTI;
  yy_pop_state();
  TTH_OUTPUT(closing);
  fprintf(tth_fdout,"</ol>");
  enumerate--;
  tth_eqwidth=tth_eqwidth+TTH_INDPC;
  TTH_POP_CLOSING;
  horizmode=1;
}
\\begin\{list\}   {    /* list like description */
  horizmode=0;
  fprintf(tth_fdout,"\n<dl>\n");yy_push_state(Ldescription);
  yy_push_state(unknown); /* dump adjacent brace groups */
  tth_eqwidth=tth_eqwidth-TTH_INDPC;
  TTH_PUSH_CLOSING;
  horizmode=1;
  yy_push_state(removespace);
}
 /* Multiple column index. */
\\begin\{theindex\} {
  if(tth_debug&3)fprintf(stderr,"Starting the index ");
  horizmode=0;
  yy_push_state(Ldescription);
  TTH_OUTPUT("\n<table width=\"100%\"><col span=\"2\" width=\"48%\" /><tr><td valign=\"top\"><hr />\n<dl>\n");
  tth_eqwidth=tth_eqwidth-TTH_INDPC;
  TTH_PUSH_CLOSING;
  tth_index_face=0;
  tth_index_line=0;
}

 /* Multiple two-column segments broken only at indexspace.*/
<Ldescription>{WSP}*\\indexspace {
  /* fprintf(stderr,"indexspace\n"); */
  TTH_INC_MULTI;
  if(tth_index_line > tth_indexpage){
    TTH_OUTPUT(closing);    *closing=0;
    tth_index_line=0;
    if((++tth_index_face)&1){
      TTH_OUTPUT("</dl></td><td valign=\"top\"><hr />\n<dl>\n");
    }else{
      TTH_OUTPUT("</dl></td></tr><tr><td valign=\"top\"><hr />\n<dl>\n");
    }
  }else{
    TTH_OUTPUT("<br /><br />");
    ++tth_index_line;
  }
}

<Ldescription>{WSP}*\\end\{theindex\} {
  TTH_INC_MULTI;
  yy_pop_state();
  TTH_OUTPUT(closing);
  TTH_OUTPUT("</dl></td></tr></table>");
  tth_eqwidth=tth_eqwidth+TTH_INDPC;
  TTH_POP_CLOSING;
}

\\begin\{(description|theindex)\} {
  /*  if(horizmode) horizmode=1; */
  horizmode=0;
  fprintf(tth_fdout,"\n<dl>\n");yy_push_state(Ldescription);
  tth_eqwidth=tth_eqwidth-TTH_INDPC;
  TTH_PUSH_CLOSING;
 }
{WSP}*\\end\{list\}   |
{WSP}*\\end\{(description|theindex|thebibliography)\}  {
  TTH_INC_MULTI;
  yy_pop_state();
  TTH_OUTPUT(closing);
  fprintf(tth_fdout,"</dl>");
  tth_eqwidth=tth_eqwidth+TTH_INDPC;
  TTH_POP_CLOSING;
}
\\begin\{figure\*?\}(\[[^\]]*\])? {
  TTH_INC_MULTI;
  if(horizmode) horizmode=1;
  strcpy(environment,"figure");
  TTH_PUSH_CLOSING;*closing=0;
  if(lbook) sprintf(envirchar,"%d.%d",chapno,figureno+1);
  else sprintf(envirchar,"%d",figureno+1);
  {TTH_PAR_ACTION};
  fprintf(tth_fdout,"<a id=\"tth_fIg%s\">\n</a> ",envirchar);
 }
\\begin\{table\*?\}(\[[^\]]*\])? {
  TTH_INC_MULTI;
  if(horizmode) horizmode=1;
  strcpy(environment,"table");
  TTH_PUSH_CLOSING;*closing=0;
  if(lbook) sprintf(envirchar,"%d.%d",chapno,tableno+1);
  else sprintf(envirchar,"%d",tableno+1);
  {TTH_PAR_ACTION};
  fprintf(tth_fdout,"<a id=\"tth_tAb%s\">\n</a> ",envirchar);
 }
\\end\{figure\*?\} |
\\end\{table\*?\}  {   /* Special case. Remove environment label. */
  TTH_TEXCLOSE else{
  TTH_CLOSEGROUP;TTH_POP_CLOSING;
  {TTH_PAR_ACTION};
  *environment=0;}}

\\setlength\{\\unitlength\}{BRCG} strcpy(unitlength,yytext);
\\begin\{picture\}   {
  if(tth_autopic){
    picno++;
    if(tth_debug&32)fprintf(stderr,"Starting picture number %d\n",picno);
    fprintf(tth_fdout,"<br /><img src=\"pic%d.gif\" alt=\"Picture %d\" />",picno,picno);
    {TTH_PAR_ACTION};
    sprintf(scratchstring,"pic%d.gif",picno);
    if((tth_picfile=fopen(scratchstring,"r"))){
      fclose(tth_picfile);tth_picfile=NULL;
      fprintf(stderr,"Including existing picture %s\n",scratchstring);
      yy_push_state(discardgroup);
    }else{
      sprintf(scratchstring,"pic%d.tex",picno);
      if ( (tth_picfile=fopen(scratchstring,"w")) != NULL){
	fprintf(tth_picfile,
		"\\batchmode\\documentclass{article}\n\\usepackage{graphicx}\\usepackage{epsfig}\n\\pagestyle{empty}\n\\begin{document}%s\n%s",
		unitlength,yytext);
	yy_push_state(picture);
	jscratch=0;
      }else{
	fprintf(stderr,"Unable to open picture file for writing.\n");
	yy_push_state(discardgroup);
	fprintf(tth_fdout,"<br />Picture Not Created.<br />\n");
      }
    }
  }else{
    yy_push_state(discardgroup);
    fprintf(tth_fdout,"<br />Picture Omitted<br />");
  }
}
<picture>\\begin\{picture\} jscratch++;fprintf(tth_picfile,"%s",yytext);    
<picture>\\end\{picture\} {
  if(jscratch) {jscratch--; fprintf(tth_picfile,"%s",yytext);}    
  else{
    fprintf(tth_picfile,"%s",yytext);
    fprintf(tth_picfile,"\\end{document}\n");
    fclose(tth_picfile);tth_picfile=NULL;
    sprintf(scratchstring,"latex2gif pic%d",picno);
    jscratch=system(scratchstring);
    if(jscratch==SUCCESS){ fprintf(stderr,"Created pic%d.gif\n",picno);}
    else{
      fprintf(stderr,"**** Failed to create pic%d.gif\n",picno);
      fprintf(tth_fdout,"<br />Picture Not Created.<br />");
    }
    yy_pop_state();
  }
}
<picture>%%tt[hm]: 
<picture>{ANY}       {
  if(strcspn(yytext,"\n")==0) TTH_INC_LINE;
  fprintf(tth_picfile,"%s",yytext);
}
<discardgroup>\\begin\{picture\} {
  yy_push_state(discardgroup);
  if(tth_debug&32)fprintf(stderr,"Discarding unsupported construct:%s\n",yytext);
 }
<discardgroup>\\end\{picture\} {
  yy_pop_state();
  if(tth_debug&32)fprintf(stderr,"Ending discarding construct:%s\n",yytext);
 }
<discardgroup>.

 /***********************************************************************/
 /* Latex tabular and haligns */
\\begin\{tabular(\*|x)\}  TTH_TEX_FN("\\begin{tabular}#tthdrop1",1);
\\begin\{tabular\}  {
  TTH_TEX_FN_OPT("\\tth_tabular#tthdrop2",2,"");
}
<psub>\\tth_tabular#tthdrop2   {
  TTH_HAL_PUSH;
  *halstring=0;
  if((jscratch=indexkey("#2",margkeys,&margmax))!=-1){
    if(tth_debug&33) fprintf(stderr,"Tabular argument:%s> ",margs[jscratch]);
    yy_pop_state();
    TTH_SCAN_STRING("\\tth_endtabpre");
    TTH_SCAN_STRING(margs[jscratch]);
    rmdef(margkeys,margs,&margmax);       rmdef(margkeys,margs,&margmax); 
  }else fprintf(stderr,"**** Error: No tabular argument found.\n");
  if(tth_debug&33) fprintf(stderr,"Beginning tabular\n");
  if(!eqdepth)yy_push_state(disptab);  /* Prevent $$ from being display math.*/
  yy_push_state(tabpre);   /* Prescan the tabular argument.*/
  ncols=0;
}
<tabpre>{NL}   TTH_INC_LINE;
<tabpre>{TSP}   /*remove spaces*/
<tabpre>\|      TTH_CCAT(halstring,yytext);
<tabpre>c|l|r   TTH_CCAT(halstring,yytext);ncols++;
 /*
<tabpre>c|l|r   {
  TTH_CCAT(halstring,"&{&");
  TTH_CCAT(halstring,yytext);ncols++;
  TTH_CCAT(halstring,"&}&");
}*/
<tabpre>@   {  TTH_TEX_FN("\\tth_preat#tthdrop1",1); }
<psub>\\tth_preat#tthdrop1 {
  yy_pop_state();
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1){
    TTH_CCAT(halstring,"@{");
    TTH_CCAT(halstring,margs[jscratch]);
    TTH_CCAT(halstring,"}");
    if(tth_debug&32) fprintf(stderr,"@string copied =%s\n",margs[jscratch]);
    rmdef(margkeys,margs,&margmax);
  }
}
<tabpre>p    { TTH_TEX_FN("\\tth_presp#tthdrop1",1);ncols++; }
<psub>\\tth_presp#tthdrop1  {
  yy_pop_state();
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1){
    if(tth_debug&32) fprintf(stderr,"p-string =%s ",margs[jscratch]);
    TTH_CCPY(scratchstring,margs[jscratch]);
    TTH_CCAT(scratchstring,"\\tth_pfinish");
    TTH_SCAN_STRING(scratchstring);
    GET_DIMEN;
    rmdef(margkeys,margs,&margmax);
  }
}
<tabpre>\\tth_pfinish {
  /*  sprintf(scratchstring,"&{&p{%d}&}&",thesize/SCALEDPERPIXEL);*/
  sprintf(scratchstring,"p{%d}",thesize/SCALEDPERPIXEL);
  TTH_CCAT(halstring,scratchstring);
  if(tth_debug&1056) fprintf(stderr,"p-string copied=%s pixels for %d sp\n",
			   scratchstring,thesize);
}
<tabpre>\*    { TTH_TEX_FN("\\tth_tabstar#tthdrop2",2); }
<psub>\\tth_tabstar#tthdrop2 {
  yy_pop_state();
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1){
    if(tth_debug&32) fprintf(stderr,"*{%s} construct. ",margs[jscratch]);
    sscanf(margs[jscratch],"%d",&js2);
    if((jscratch=indexkey("#2",margkeys,&margmax))!=-1 ||
       js2>=1 || js2<255){
      if(tth_debug&32) fprintf(stderr,"Codes: %s\n",margs[jscratch]);
      for(js2++;js2>1;js2--){TTH_CCAT(halstring,margs[jscratch]);ncols++;}
      rmdef(margkeys,margs,&margmax);
    }else fprintf(stderr,"**** Error in tabular argument * number:%d\n",js2);
    rmdef(margkeys,margs,&margmax);
  }
}
<tabpre>{ANY}   if(strcspn(yytext,"\n")==0) TTH_INC_LINE;/* Do nothing if we don't recognize */ 
<tabpre>\\tth_endtabpre {
  yy_pop_state();
  TTH_PUSH_CLOSING;
  TTH_CCPY(closing,TTH_TABC);
  if(eqdepth) {/* equation case */
    TTH_EQA_PUSH;
    eqclose++;
    tophgt[eqclose]=0;
    levhgt[eqclose]=1;
    eqalignrow=0;
  }
  if(eqdepth && displaystyle) { /* only display equations.*/
    TTH_OUTPUT(TTH_CELL3);TTH_CCAT(closing,TTH_CELL3);
  }else {TTH_OUTPUT("\n");}
  if(*(halstring) == '|') {
    TTH_OUTPUT(TTH_TABB);
  }else{
    TTH_OUTPUT(TTH_TABO);
  }  /* Guess that if template starts '|' we want a boxed table, else not */
  *tdalign=0;*precell=0; /* Safety only; ought not to be needed */
  if(eqdepth)eqalignrow++;
  yy_push_state(hendline); /* check for multicol at start */
  TTH_PUSH_BUFF(0);halbuff=yy_scan_string(halstring); /* Setup halbuff */
  yy_switch_to_buffer(include_stack[--tth_stack_ptr]); 
  /* But keep current*/
  if(tth_debug&32)fprintf(stderr,"Endtabpre:%s>\n",halstring);
  if(!*halstring){
    fprintf(stderr,"**** Error Fatal. Null or improper alignment argument, line %d.\n",tth_num_lines);
    TTH_EXIT(3);
  }
 }

<talign>\|  { /* cell boundary. Scan @strings if any */
  if(tth_debug&32)fprintf(stderr,"|");
  jstal=-1;
  if(*precell && !jshal && *tdalign){ 
    strcat(precell,"&");
    *tdalign=0;
    yy_switch_to_buffer(include_stack[--tth_stack_ptr] );
    yy_pop_state();
    if(tth_debug&32){fprintf(stderr,"%s",precell);}
    TTH_SCAN_STRING(precell);*precell=0;
  } else if(jshal==1 || jshal==-1 ){
    TTH_HALACT;
  }
}
<talign>@  {
  /*  if(tth_debug&32) fprintf(stderr,"tth_@, %d\n",margmax);*/
  TTH_TEX_FN("\\tth_atstring#tthdrop1",1);
}
<psub>\\tth_atstring#tthdrop1 {
  yy_pop_state();
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1){
    if(jshal<1){
      TTH_CCAT(precell,"{");
      TTH_CCAT(precell,margs[jscratch]);
      TTH_CCAT(precell,"}");
      /*     if(tth_debug&32) fprintf(stderr,"@string=%s ",precell);*/
    }
    rmdef(margkeys,margs,&margmax);
  } /* Have to explicitly excape from macro
       because <<EOF>> not handled in talign */
  yy_delete_buffer( YY_CURRENT_BUFFER );
  yy_switch_to_buffer(include_stack[--tth_stack_ptr] );
}

<talign>c|r|l|p{BRCG}  {
  if(jshal==1||jshal==-1){yyless(0);} 
  if(jstal==-1)jstal=0;
  TTH_HALACT; 
}
<talign><<EOF>> {  /* Reset halbuff to start. Gives matrix underflows.
    yy_delete_buffer(YY_CURRENT_BUFFER);
    if(tth_debug&32)fprintf(stderr,"\nTemplate end rescan:%s> \n",halstring);
    halbuff=yy_scan_string(halstring);
    yy_switch_to_buffer(halbuff);  */
    TTH_HALACT; /*Old approach */
}
<talign>&   yy_push_state(tempamp);
<tempamp>&  {
  yy_pop_state();
  /*  if(tth_debug&32)fprintf(stderr,"%dprecell=%s\n",jshal,precell);*/
  /* if(jshal>0)*precell=0; don't now throw away */
}
<tempamp>\{|\}   {TTH_CCAT(precell,yytext);}
<tempamp>\\&|\\%  |   /* ensure ampersand does not escape */
<tempamp>{ANY} {
  if(strcspn(yytext,"\n")==0) TTH_INC_LINE;
  if(jshal<1){TTH_CCAT(precell,yytext);}
}
<talign>. fprintf(stderr,"Unknown tabular format: %s\n",yytext);TTH_HALACT;

<valign>&  TTH_SCAN_STRING("\\par");
<valign>\\cr(cr)? {
  fprintf(tth_fdout,"\n</td><td%s>",valignstring);
}
<valign>\\tthexitvalign  {
  yy_pop_state();
}

&   {
  if(*halstring) {yy_push_state(hamper); 
  }else{fprintf(tth_fdout,"</td><td width=\"%d\">\n",tabwidth);}/* settabs */
}
\\crcr      |
\\tth_halcr |   /* used for <equation> state. */ 
\\cr |
\\\\\*?{SP}*(\[[^\]]*\])?  {
  TTH_INC_MULTI;
  if(*halstring){ /* halign and tabular */
    if(jstal==0){
      jstal=1;
      jshal=-1;
      yyless(0);
      TTH_HALSWITCH;
    }else{
      jstal=0;
      TTH_OUTPUT(TTH_CELL_TAB);
      TTH_OUTPUT(TTH_TRC);
      if(eqdepth){
	if(tth_istyle&1)eqalignrow=eqalignrow+6*(levhgt[eqclose]-1)+TTH_HGT;else
	  eqalignrow=eqalignrow+levhgt[eqclose];
	if(tth_debug&2)fprintf(stderr,
	   "Halcr. eqalignrow=%d, eqaind=%d, levhgt=%d\n",
			       eqalignrow,eqaind,levhgt[eqclose]);
	levhgt[eqclose]=1;
      }
      yy_push_state(hendline);
      yy_delete_buffer(halbuff);  /* Reset halbuff to start */
      if(tth_debug&32)fprintf(stderr,"\nEOL rescan:%s> \n",halstring);
      TTH_PUSH_BUFF(0);halbuff=yy_scan_string(halstring);
      yy_switch_to_buffer(include_stack[--tth_stack_ptr]);
    }
  }else{
    if(*(yytext+1)=='c'){
      TTH_OUTPUT("</td></tr></table>\n"); /* settabs */
    }else{
      TTH_OUTPUT("<br />"); /* LaTeX Plain text line break */
    }
  }
}
<hamper>{NL}  TTH_INC_LINE;
<hamper>{TSP}*
<hamper>\\multicolumn   {
  if(tth_debug&32) fprintf(stderr,"\nInner Multicolumn(%d%d)",jshal,jstal);
  if(jstal==0){
    jstal=1;
    jshal=-1;
    yyless(0);
    yy_pop_state();TTH_SCAN_STRING("&");
    TTH_HALSWITCH;
  }else /**/{
    jstal=0;
    TTH_OUTPUT(TTH_CELL_TAB);
    TTH_TEX_FN("\\tth_multistart#tthdrop2",2); 
  }
} /* See psub below. */
<hamper>\\omit  TTH_SCAN_STRING("\\multispan1");
<hamper>\\multispan {
  if(tth_debug&32) fprintf(stderr,"Inner Multispan(%d%d)",jshal,jstal);
  if(jstal==0){
    jstal=1;
    jshal=-1;
    yyless(0);
    yy_pop_state();TTH_SCAN_STRING("&");
    TTH_HALSWITCH;
  }else{
      jstal=0;
      yy_pop_state();
      TTH_OUTPUT(TTH_CELL_TAB);
      TTH_TEX_FN("\\tth_multispan#tthdrop1",1); 
  }
} /* See psub below */
<hamper>\\[a-zA-Z@]+   { /* expand first */
  TTH_DO_MACRO
  else{ 
    yyless(0);
    strcpy(tdalign,TTH_CELL_TAB);  /* Save the cell closing.*/
    yy_pop_state();jshal=0;
    TTH_HALSWITCH;
  }
}
<hamper>. {
  yyless(0);
  strcpy(tdalign,TTH_CELL_TAB);  /* Save the cell closing.*/
  yy_pop_state();
  jshal=0;
  TTH_HALSWITCH;
}
<hendline>\\hline
<hendline>\\hline{WSP}*\\hline    TTH_INC_MULTI;TTH_OUTPUT(TTH_TRTD);
<hendline>\\cline{SP}*\{  yy_push_state(matchbrace);
<hendline>{TSP}
<hendline>{NL}  TTH_INC_LINE;

<hendline>\\multicolumn  {
  if(tth_debug&32) fprintf(stderr,"Multicolumn at start:");
  TTH_OUTPUT(TTH_TRO);
  TTH_TEX_FN("\\tth_multiinner#tthdrop2",2); 
}
 /* Add an open brace for a starting multicol */
<psub>\\tth_multiinner#tthdrop2  {
  /*TTH_SCAN_STRING("{");
    if(tth_debug&32){fprintf(stderr,"{");}*/
  TTH_SCAN_STRING("\\tth_multistart#tthdrop2");
}
<psub>\\tth_multistart#tthdrop2 {
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1){
    sscanf(margs[jscratch],"%d",&jshal);
  }else{fprintf(stderr,"No argument #1 in multicol\n");}
  if((jscratch=indexkey("#2",margkeys,&margmax))!=-1){
    strcpy(scrstring,margs[jscratch]);
    chscratch=scrstring+strcspn(scrstring,"lrcp"); /* No @strings allowed */
    strcpy(scratchstring,TTH_HALCODE(chscratch));
  }else{*scratchstring=0;fprintf(stderr,"No argument #2 in multicol\n");}
  if(tth_debug&32) fprintf(stderr,"%d,%s\n",jshal,scratchstring);
  sprintf(scrstring,TTH_MULSTART,jshal,scratchstring);
  TTH_OUTPUT(scrstring);
  if(eqdepth){TTH_OUTPUT(TTH_EQ5);}
  yy_pop_state();    yy_pop_state(); /* get out of hendline/hamper too */  
  rmdef(margkeys,margs,&margmax);rmdef(margkeys,margs,&margmax); 
  jshal++;/* fix */
  TTH_HALSWITCH;
 }
<hendline>\\end\{(tabular|array)(\*|x)?\} {
  TTH_TEXCLOSE else{
  if(tth_debug&32) fprintf(stderr,"Ending tabular\n");
  yy_delete_buffer(halbuff);
  yy_pop_state();
  TTH_HAL_POP;
  if(eqdepth){
    eqclose--;
    if(tth_istyle&1)jscratch=(eqalignrow+6*(levhgt[eqclose+1]-1)+TTH_HGT)/6; 
    else    jscratch=levhgt[eqclose+1]+eqalignrow;
    if(jscratch>levhgt[eqclose])levhgt[eqclose]=jscratch;
    /* This was an alternative attempt when \\ was forced. Height was broken.
      if(eqalignrow>levhgt[eqclose])levhgt[eqclose]=eqalignrow;*/
    if(tth_debug&2)fprintf(stderr,
	      "Equation Tabular Close: eqclose=%d, eqalignrow=%d, levhgt=%d\n",
			   eqclose,eqalignrow,levhgt[eqclose]);
    TTH_EQA_POP;
  }
  TTH_CLOSEGROUP;TTH_POP_CLOSING;
  if(!eqdepth)yy_pop_state(); /* the disptab we added */
} 
}
<hendline>\} {
  yy_pop_state(); /* out of hendline */
  TTH_TEXCLOSE else{
  if(!eqdepth){
    if(tth_push_depth==halignenter){
      TTH_HAL_POP;
    }
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
  }else{ /* This for equation state should not happen */
    eqclose--;
    TTH_EQA_POP;
    yy_pop_state();yyless(0);
  }
}} /* end of halign. */
<hendline>.  {
  yyless(0); TTH_OUTPUT(TTH_TRO);
  yy_pop_state();
  jshal=0;
  TTH_HALSWITCH;
}

<hendline>\\noalign {/*attempt to fix*/
  if(tth_debug&33) fprintf(stderr,
	"Noalign in hendline. eqdepth=%d, ncols=%d.\n",eqdepth,ncols);
  sprintf(scrstring,"\\multicolumn{%d}{l}{#1}\\cr#tthdrop1",ncols);
  TTH_TEX_FN(scrstring,1);
}


    /* The folloing is a hack that is probably wrong for mathml. But I
       did't quite know why this is all necessary anyway. Ought to be
       fixed.  It ought to be possible to convert a \noalign into
       \multicolumn, which is what the above is supposed to do.
    */
 /*
<hendline>\\noalign  {
  if(tth_debug&32) fprintf(stderr,"noalign in hendline. eqdepth=%d\n",eqdepth);
  yy_pop_state();
  TTH_PUSH_BUFF(0);halbuff=yy_scan_string("");
  yy_switch_to_buffer(include_stack[--tth_stack_ptr]);
  TTH_TEX_FN("\\tth_noalign#tthdrop1",1);
  yy_push_state(removespace);
  
}
<psub>\\tth_noalign {
  if(tth_debug&32) fprintf(stderr,"tth_noalign\n");
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1){
    if(tth_debug&32)fprintf(stderr,"Noalign:%s; eqdepth=%d\n",margs[jscratch],eqdepth);
    if(eqdepth){
      sprintf(defstore,
	      "\\special{html: \n<tr><td id=\"e1\" colspan=\"%d\"><table><tr><td>}{%s}\\cr"
	    ,ncols,margs[jscratch]);
    }else{
      sprintf(defstore,
	      "\\special{html: \n<tr><td id=\"e0\" colspan=\"%d\">}{%s}\\cr"
	    ,ncols,margs[jscratch]);
    }
    TTH_SCAN_STRING(defstore);*defstore=0;
  }else fprintf(stderr,"Noalign no argument:%d\n",jscratch);
}
 */
<hendline>\\omit  TTH_SCAN_STRING("\\multispan1");
<hendline>\\multispan  {
  yy_pop_state();
  if(tth_debug&32) fprintf(stderr,"Line Start Multispan\n");
  TTH_TEX_FN("\\tth_multispan#tthdrop1",1); 
  TTH_OUTPUT(TTH_TRO);
}
<psub>\\tth_multispan#tthdrop1  {
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1)
    sscanf(margs[jscratch],"%d",&jshal);
  if(tth_debug&32) fprintf(stderr," %d",jshal);
  sprintf(scrstring,TTH_MULSPAN,jshal);
  TTH_OUTPUT(scrstring);
  yy_pop_state();
  rmdef(margkeys,margs,&margmax);
  jshal++;/* fix */
  TTH_HALSWITCH;
}
<hendline>\\[a-zA-Z@]+   { /* expand first */
  TTH_DO_MACRO
  else{
    yyless(0);TTH_OUTPUT(TTH_TRO);
    yy_pop_state();
    jshal=0;
    TTH_HALSWITCH;
  }
}
\\end\{tabular(\*|x)?\} yyless(0);TTH_SCAN_STRING("\\\\"); 

\\cline{SP}*\{  yy_push_state(matchbrace);
\\hline
\\hline{WSP}*\\hline    TTH_INC_MULTI;TTH_OUTPUT("</tr><tr><td>");
   /* End of tabular and halign code.*/
 /********************************************************************/

\\tiny{SP}*  	TTH_OUTPUT(TTH_TINY);TTH_PRECLOSE(TTH_SIZEEND);
\\scriptsize{SP}*     TTH_OUTPUT(TTH_SCRIPTSIZE);TTH_PRECLOSE(TTH_SIZEEND);
\\footnotesize{SP}*   TTH_OUTPUT(TTH_FOOTNOTESIZE);TTH_PRECLOSE(TTH_SIZEEND);
\\small{SP}*  	TTH_OUTPUT(TTH_SMALL);TTH_PRECLOSE(TTH_SIZEEND);
\\normalsize{SP}*   TTH_OUTPUT(TTH_NORMALSIZE);TTH_PRECLOSE(TTH_SIZEEND);
\\large{SP}*  	TTH_OUTPUT(TTH_large);TTH_PRECLOSE(TTH_SIZEEND);
\\Large{SP}*  	TTH_OUTPUT(TTH_Large);TTH_PRECLOSE(TTH_SIZEEND);
\\LARGE{SP}*  	TTH_OUTPUT(TTH_LARGE);TTH_PRECLOSE(TTH_SIZEEND);
\\(H|h)uge{SP}*   TTH_OUTPUT(TTH_HUGE);TTH_PRECLOSE(TTH_SIZEEND);

\\centering   fprintf(tth_fdout,"<div style=\"text-align:center\">");TTH_PRECLOSE("</div>");
\\raggedleft  fprintf(tth_fdout,"<div align=\"right\">");TTH_PRECLOSE("</div>");

 /* Insert an implied hbox around the minipage(s) that terminates at the
    next \par. Inside the minipages the state is not pargroup. Thus any
    \par inside the minipage does not terminate the hbox group.
 */
<pargroup>\\begin\{minipage\}  {
  yy_push_state(INITIAL);
  TTH_TEX_FN_OPT("\\vbox\\bgroup\\hsize=#2#tthdrop2",2,"");
}
\\begin\{minipage\}  {
  TTH_PUSH_CLOSING; /* This will be cancelled at the end of the pargroup*/
  yy_push_state(pargroup);
  yy_push_state(INITIAL);
  TTH_TEX_FN_OPT("\\tth_hbox\\vbox\\bgroup\\hsize=#2#tthdrop2",2,"");
}
\\end\{minipage\} {
  TTH_SCAN_STRING("\\egroup");
  yy_pop_state();
}

  /*Default Begin and End Are at end of flex code. */

 /* colordvi-compatible commands. Expand the argument first.*/
\\Color   TTH_TEX_FN("{\\textColor{#1}#2}#tthdrop2",2);
 /* textColor in colordvi is global. But that's a terrible thing to do 
    so in TtH it is local. */
\\textColor TTH_TEX_FN("\\edef\\tthexpcol{\\tthtextColor{#1}}\\tthexpcol#tthdrop1",1);
\\tthpageColor{BRCG}    |
\\tthbgColor{BRCG}      |
\\tthspecialcolor{BRCG} |
\\tthtextColor{BRCG} { /* Color defined in one of four ways*/
  chscratch=yytext+strcspn(yytext,"{")+1;
  *(chscratch+strcspn(chscratch,"}"))=0;
  if((jscratch=sscanf(chscratch,"%f %f %f %f",
		      &cyanc,&magentac,&yellowc,&blackc))<=2){
    if((jscratch=sscanf(chscratch,"%f , %f , %f , %f", /*Latex comma delimits*/
			&cyanc,&magentac,&yellowc,&blackc))<=2){
      if(jscratch == 1) { /* grey */
	redc=cyanc;
	greenc=cyanc;
	bluec=cyanc;
      }else if(jscratch==0 || jscratch==EOF){ /* Try a named color*/
	if((jscratch=indexkey(chscratch,keys,&nkeys))!=-1){
	  /* Custom color.*/    /*Substitute and scan again*/
	  TTH_CCPY(scratchstring,yytext);
	  *(scratchstring+strcspn(scratchstring,"{"))=0;
	  TTH_CCAT(scratchstring,defs[jscratch]); 
	  *(scratchstring+strcspn(scratchstring,"#"))=0; /* Fix end*/
	  TTH_SCAN_STRING(scratchstring);
	  jscratch=5;
	}else{ 
	  jscratch=tth_cmykcolor(chscratch,&cyanc,&magentac,&yellowc,&blackc);
	}
      }else{
	jscratch=0;
      }
    }
  }
  if(jscratch!=5){ /* For non custom colors*/
    if(jscratch==0){
      fprintf(stderr,"**** Unknown color specification %s\n",chscratch);
    }else if(jscratch==4){ /* Convert to RGB from CMYK*/
      if((redc=1.-cyanc-blackc)<0.) redc=0.;
      if((greenc=1.-magentac-blackc)<0.) greenc=0.;
      if((bluec=1.-yellowc-blackc)<0.) bluec=0.;
    }else if(jscratch==3){ /* It is RGB already */
      redc=cyanc;
      greenc=magentac;
      bluec=yellowc;
    }
    if(jscratch){
      sprintf(colorchar,"%2.2X%2.2X%2.2X",
	      (int)(redc*255),(int)(greenc*255),(int)(bluec*255));
      if(tth_debug&32)fprintf(stderr,"RGB=%f,%f,%f\ncolorchar=%s\n",
			      redc,greenc,bluec,colorchar);
      if(strstr(yytext,"tthbgC")){/*Box Background color case CSS*/
	sprintf(scratchstring,
		"\\special{html:\n<span style=\"background: #%s;\">}"
		,colorchar); 
	TTH_PRECLOSE("</span>");
      }else if(strstr(yytext,"tthpageC")){ /* Page color HTML violation*/
	sprintf(scratchstring,
		"\\special{html:<body bgcolor=\"#%s\">}",colorchar);       
      }else{
	sprintf(scratchstring,TTH_COLOR,colorchar); 
	/* if(!strstr(yytext,"tthspecial"))
	 Not  closing locally for the colordvi special case breaks stuff. */
	{TTH_PRECLOSE(TTH_COLOREND);}
      }
	TTH_SCAN_STRING(scratchstring);
    }
  }
}
 /* The specials that colordvi constructs for dvips for unknown colors. */
\\special{WSP}*\{color[ ]pop\}     TTH_INC_MULTI;
 /* TTH_OUTPUT(TTH_COLOREND); Remove because nesting gets broken */
\\special{WSP}*\{color([ ]push)?[ ][^\}]*\} {
  TTH_INC_MULTI;
  TTH_CCPY(scratchstring,"\\tthspecialcolor{");
  /* if(strstr(yytext,"push")){
    TTH_CCPY(scratchstring,"\\tthtextColor{");
    } */
  TTH_CCAT(scratchstring,(strrchr(yytext,' ')+1));
  TTH_SCAN_STRING(scratchstring);
}
 
 /* Latex graphics colors (see grfguide.ps). The syntax is confusingly the 
    exact opposite of colordvi, in that textcolor colorizes its argument
    but color is the switch. Use the preceding function anyway.*/
\\textcolor   TTH_TEX_FN_OPT("{\\textColor{#2}#3}#tthdrop3",3,"");
\\color TTH_TEX_FN_OPT("\\edef\\tthexpcol{\\tthtextColor{#2}}\\tthexpcol#tthdrop2",2,"");
\\colorbox TTH_TEX_FN_OPT("{\\edef\\tthexpcol{\\tthbgColor{#2}}\\tthexpcol #3}#tthdrop3",3,"");
\\fcolorbox TTH_TEX_FN_OPT("\\fbox{\\colorbox[#1]{#2}{#3}}#tthdrop3",3,"");
\\pagecolor TTH_TEX_FN_OPT("{\\edef\\tthexpcol{\\tthpageColor{#2}}\\tthexpcol}#tthdrop2",2,"");

\\renewcommand[*] |
\\newcommand[*]   |
\\providecommand[*] |
\\renewcommand |
\\newcommand   |
\\providecommand	{
  localdef=1;
  horizmode=0; /* This protection against \par should not be needed but ...*/
  yy_push_state(define);  
  yy_push_state(getnumargs);
  yy_push_state(getdef);
}
\\renewenviroment{BRCG} {
  fprintf(stderr,"**** %s: works only for non-standard environments\n",yytext);
  strcpy(scratchstring,"\\newenvironment");
  strcat(scratchstring,yytext+strcspn(yytext,"{"));
  TTH_SCAN_STRING(scratchstring);
}
\\newenvironment{BRCG} {
  localdef=0;
  horizmode=0;
  yy_push_state(getend);  /* will define the end environment, see following */
  yy_push_state(define);  /* defines the begin environment */
  yy_push_state(getnumargs);
  TTH_CCPY(defchar,"\\begin");
  strcat(defchar,strstr(yytext,"{"));
  *dupstore=0; /*does getdef*/
  TTH_PUSH_CLOSING;TTH_CCPY(closing,strstr(yytext,"{")); /* save for getend */
}
\\newtheorem{BRCG}\[[^\]]*\]{WSP}*{BRCG}  { 
  TTH_INC_MULTI;
  /* Newtheorem with numberedlike option. Overrides macro definition.*/
  if(tth_debug&4)fprintf(stderr,"New numbered-like theorem:%s\n",yytext);
  strcpy(scratchstring,strstr(yytext,"{")+1);
  strcpy(dupstore,strstr(scratchstring,"{"));
  *strstr(scratchstring,"}")=0;
  strcpy(scrstring,strstr(yytext,"[")+1);
  *strstr(scrstring,"]")=0;
  sprintf(dupstore2,"\\newenvironment{%s}{\\par\\stepcounter{%s}   \\textbf{%s \\arabic{%s}}\\bgroup \\em}{\\par\\egroup}",
	  scratchstring,scrstring,dupstore,scrstring);
  TTH_SCAN_STRING(dupstore2);
  *dupstore=0;
  *dupstore2=0;
}
<getend>. {
  yyless(0);yy_pop_state();
  yy_push_state(define);
  yy_push_state(getnumargs);
  TTH_CCPY(defchar,"\\end");strcat(defchar,closing);*dupstore=0; /*does getdef*/
  TTH_POP_CLOSING;
} /* end and beginning now defined. */

\| {
  if(indexkey("\\amslatex",keys,&nkeys)!=-1){
    TTH_SCAN_STRING("\\verb|");
  }else{
    TTH_OUTPUT(" - ");
  }
} 
 /* url that does not use braces */
\\url[^ \t\n\{]    |
  /*\\verb\*?[^ \t\na] { prior to 12 Jan 2002*/
\\verb\*?[^\t\na] {  /* Prevent erroneous \verbatim detection */
  if(tth_debug&8)fprintf(stderr,"Entering Verb state:%s\n",yytext);
  chr1[0]=*(yytext+strlen(yytext)-1);
  TTH_OUTPUT(TTH_TT1); yy_push_state(verb);
  TTH_PUSH_CLOSING;  TTH_CCPY(closing,TTH_TT2);
 }
 /* Deal with cases that are not in line.*/
\\verb TTH_TEX_FN("\\verb#1#tthdrop1",1);

 /* ************* Enclosing multiple groups in stuff. ******** removed **/

  /* **************Paragraphing closures.***************/
<parcheck>[ \t]*{NL}   {
  TTH_INC_LINE;yy_pop_state();TTH_SCAN_STRING("\\par\n");horizmode=1;}
<parcheck>.          {yyless(0);yy_pop_state();horizmode=1;}

<pargroup>{NL} {
  TTH_INC_LINE;
  if(horizmode==1){
    horizmode=-1;
    yy_push_state(parcheck);
    fprintf(tth_fdout,"%s",yytext);
  }else if(horizmode==-1) {
    fprintf(stderr,"**** Abnormal NL in -1 horizmode, pargroup\n");
    /* TTH_SCAN_STRING("\\par"); */
  }
}
<pargroup>\\par	  {
  TTH_TEXCLOSE else{
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
    yy_pop_state();
    if(tth_eqwidth<100) tth_eqwidth=tth_eqwidth+TTH_INDPC;
    horizmode=0;/*{TTH_PAR_ACTION} not in pargroup?*/
  }
}
<pargroup>{SP}*\\item	 {
  TTH_TEXCLOSE else{ 
    if(!strcmp(closing,"</dd></dl>")) {
      /* Do not close the list or pop closing.*/
      fprintf(tth_fdout,"%s","</dd>\n <dt>\n");
    }else{ /* Have to close a different item */
      TTH_CLOSEGROUP; /* This a special case no POP_CLOSING */
      fprintf(tth_fdout,"<dl><dt>");
      TTH_CCPY(closing,"</dd></dl>");
      horizmode=0;/*{TTH_PAR_ACTION}*/
    }
    TTH_CCPY(argchar,"</dt>\n<dd>");yy_push_state(tokenarg);
  }
}
<pargroup>{SP}*\\itemitem    {
  TTH_TEXCLOSE else{
    if(!strcmp(closing,"</dd></dl></dl>")) {
      /* Do not close the list or pop closing.*/
      fprintf(tth_fdout,"%s","</dd><dt>\n");
    }else{ /* Have to close a different item */
      TTH_CLOSEGROUP; /* This a special case no POP_CLOSING */
      fprintf(tth_fdout,"<dl><dd><dl><dt>");
      TTH_CCPY(closing,"</dd></dl></dd></dl>");
      horizmode=0;
    }
    TTH_CCPY(argchar,"</dt><dd>\n");yy_push_state(tokenarg);
  }
}

<pargroup>\\hrule |    /* Implied \par commands */
<pargroup>\\(big|med|small)(skip|break) |
<pargroup>\\end  {
  sprintf(scratchstring,"\\par%s",yytext); TTH_SCAN_STRING(scratchstring);
}
  /* Fix for \hang and friends end of a vbox implies a par */
<pargroup>\}          |
<pargroup>\\endgroup  |
<pargroup>\\egroup    {
  if(strstr(closing,"--vbox")){
    TTH_SCAN_STRING("\\par}");
  }else{
    TTH_SCAN_STRING("\\tthparendgroup");
  }
}


<parclose>\\par {
  if(strstr(tth_texclose[tth_push_depth-1],"\\tthhbclose")){
    if(tth_debug&1024){
      fprintf(stderr,"Par in hhbc:%s\n",tth_texclose[tth_push_depth-1]);}
    yyless(0);TTH_SCAN_STRING(tth_texclose[tth_push_depth-1]);
    *tth_texclose[tth_push_depth-1]=0;
  }else{
    if(horizmode) {TTH_PAR_ACTION}
    else {fprintf(tth_fdout,"\n");}
  }
}  
<parclose>{NL} {
  TTH_CHECK_LENGTH;
  if(bracecount) fprintf(stderr,
			 "**** Error. Bracecount=%d nonzero, line %d\n",
			 bracecount,tth_num_lines);
  TTH_INC_LINE;
  if(horizmode==1){
    horizmode=-1;
    yy_push_state(parcheck);
    TTH_OUTPUT(yytext);
  }else if(horizmode==-1) {
    fprintf(stderr,"**** Abnormal NL in -1 horizmode, parclose\n");
  }
}

\\par     {
  if(horizmode) {
    {TTH_PAR_ACTION}
  } else {fprintf(tth_fdout,"\n");}
 }

{NL} {
  TTH_CHECK_LENGTH;
  if(bracecount) fprintf(stderr,"**** Error. Bracecount=%d nonzero, line %d\n",
			 bracecount,tth_num_lines);
  TTH_INC_LINE;
  if(horizmode==1){
    horizmode=-1;
    yy_push_state(parcheck);
    TTH_OUTPUT(yytext);
  }else if(horizmode==-1) {
    fprintf(stderr,"**** Abnormal NL in -1 horizmode.\n");
/*      {TTH_PAR_ACTION} */
  }
 }

 /*************************** General Rules. *****************/
\\beginsection	{
  TTH_PUSH_CLOSING; fprintf(tth_fdout,"\n<h2> ");
  TTH_CCPY(closing,"</h2>\n");
  yy_push_state(pargroup);tth_eqwidth=tth_eqwidth-TTH_INDPC;}
\\centerline	{
  TTH_OUTPUT("\n<table align=\"center\" border=\"0\"><tr><td>\n");
  TTH_CCPY(argchar,"</td></tr></table><!--hboxt-->");
  yy_push_state(tokenarg);
}
\\leftline	{
  fprintf(tth_fdout,"\n<br />");yy_push_state(tokenarg);
  TTH_CCPY(argchar,"<br />");}


<exptokarg,tokexp>\\underbar |
\\underbar   |
<exptokarg,tokexp>\\underline |
\\underline	TTH_SWAP("\\tth_underline ");
\\hrule(fill)?   yy_push_state(ruledim);TTH_OUTPUT("<hr />\n");
\\vrule          yy_push_state(ruledim);
\\bigbreak |
\\bigskip	{
  /*  if(horizmode) {fprintf(tth_fdout,TTH_PAR);horizmode=0;} replaced by*/
  if(horizmode) {{TTH_PAR_ACTION}}
  fprintf(tth_fdout,"<br /><br />");
}
\\medbreak |
\\medskip   	{
  if(horizmode) {{TTH_PAR_ACTION}}
  fprintf(tth_fdout,"<br />");
}
\\smallbreak |
\\goodbreak  |
\\smallskip 	{
  if(horizmode) {{TTH_PAR_ACTION}}
}

 /* Suck up prior whitespace to prevent paragraphs in lists*/
({WSP}*(%.*{NL}))*{WSP}*\\indexspace   {
  TTH_EXTRACT_COMMENT{TTH_INC_MULTI;TTH_OUTPUT("<br />");}
}
 /* Because of sucking up, this must be explicit. */
<Litemize,Lenumerate>({WSP}*(%.*{NL}))*{WSP}*\\itemsep {
  TTH_EXTRACT_COMMENT{GET_DIMEN;}
}
  /* Try a better job at sucking up whitespace before items. */
<Litemize,Lenumerate>({WSP}*(%.*{NL}))*{WSP}*\\item  {
  TTH_EXTRACT_COMMENT{    /* Fix tth-comment before item bug. */
    TTH_INC_MULTI;
    TTH_OUTPUT(closing);
    *closing=0;
    strcat(closing,"\n<div class=\"p\"><!----></div>\n");
    strcat(closing,"</li>\n");
    fprintf(tth_fdout,"\n<li>");
  }
}
 /* New approach to optional item argument. Don't try to grab the whole.*/
<Litemize,Lenumerate>({WSP}*(%.*{NL}))*{WSP}*\\item{WSP}*\[  {
  TTH_EXTRACT_COMMENT{    /* Fix tth-comment before item bug. */
    TTH_INC_MULTI;
    if(tth_htmlstyle&2){/* Strict xhtml doesn't allow text outside <li>*/
      TTH_OUTPUT(closing);
      *closing=0;
      strcat(closing,"\n<div class=\"p\"><!----></div>\n");
      strcat(closing,"</li>\n");
      fprintf(tth_fdout,"\n<li>");
      TTH_SCAN_STRING("\\tthnooutopt[");
    }else{
      fprintf(tth_fdout,"\n<br />");
      TTH_SCAN_STRING("\\tthoutopt[");
    }
  }
}
<Litemize,Lenumerate>\\subitem  fprintf(tth_fdout,"<br />&nbsp;&nbsp;&nbsp;&nbsp;");
<Litemize,Lenumerate>\\subsubitem  fprintf(tth_fdout,"<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
<Ldescription>{WSP}*\\item[^ [] { /* Space might not mean no opt. */ 
  /* If we can immediately detect absence of opt arg. Don't put dt section*/
  TTH_INC_MULTI;
  jscratch=strlen(yytext)-1; /*circumlocution necessary*/
  yyless(jscratch); 
  TTH_OUTPUT(closing); strcpy(closing,"</dd>\n");
  fprintf(tth_fdout,"\n\t<dd>");
  tth_index_line++;
}
<Ldescription>({WSP}*(%.*{NL}))*{WSP}*\\item{SP}* { /* If opt arg absent just gives null dt*/
  TTH_EXTRACT_COMMENT{    /* Fix tth-comment before item bug. */
  TTH_INC_MULTI;
  TTH_OUTPUT(closing); strcpy(closing,"</dd>\n");
  TTH_TEX_FN_OPT("\\special{html: <dt><b>}#1\\special{html:</b></dt>\n\t<dd>}#tthdrop1",1,"");
  tth_index_line++;
  }
}
<Ldescription>({WSP}*(%.*{NL}))*{WSP}*\\subitem  {
  TTH_EXTRACT_COMMENT{    /* Fix tth-comment before item bug. */
  TTH_INC_MULTI;
  TTH_OUTPUT(closing); strcpy(closing,"</dd>\n");
  fprintf(tth_fdout,"<dd>&nbsp;&nbsp;&nbsp;&nbsp;");
  tth_index_line++;
  }
}
<Ldescription>({WSP}*(%.*{NL}))*{WSP}*\\subsubitem  {
  TTH_EXTRACT_COMMENT{    /* Fix tth-comment before item bug. */
  TTH_INC_MULTI;
  TTH_OUTPUT(closing); strcpy(closing,"</dd>\n");
  fprintf(tth_fdout,"<dd>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
  tth_index_line++;
  }
}
\\item		{
  fprintf(tth_fdout,"%s","\n<dl>\n <dt>\n");TTH_PUSH_CLOSING;
  TTH_CCPY(closing,"</dd></dl>");
  TTH_CCPY(argchar,"</dt>\n<dd>\n");
  yy_push_state(pargroup);tth_eqwidth=tth_eqwidth-TTH_INDPC;
  yy_push_state(tokenarg); /* item code */
 }
\\itemitem	{
  fprintf(tth_fdout,"\n<dl><dd><dl><dt>");TTH_PUSH_CLOSING;
  TTH_CCPY(closing,"</dd></dl></dd></dl>");
  TTH_CCPY(argchar,"</dt><dd>");
  yy_push_state(pargroup);tth_eqwidth=tth_eqwidth-TTH_INDPC;
  yy_push_state(tokenarg); /* itemitem code */
}
\\((mid)|(top)|(page))insert	{TTH_PUSH_CLOSING;fprintf(tth_fdout,"\n<br />");}
\\endinsert  {
  TTH_TEXCLOSE else{
    TTH_CLOSEGROUP;TTH_POP_CLOSING;fprintf(tth_fdout,"\n<br />");}
}

\\footnote{SP}*(\[[0-9]*\])?     {  /* Now using embracetok Sep 98*/
  ftntno++;
  tth_encode(ftntcode,ftntno);
  if(tth_LaTeX){ /* convert to plain TeX form */
    if((chscratch=strstr(yytext,"["))){ /* optional argument case */
      strcpy(scratchstring,chscratch+1);
      *(scratchstring+strcspn(scratchstring,"]"))=0;
      sprintf(dupstore,"{$^{%s}$}",scratchstring);
      ftntno--;
      sscanf(scratchstring,"%d",&js2);
      tth_encode(ftntcode,js2);
    }else{
      sprintf(dupstore,"{$^{%d}$}",ftntno);
    }
  }
  if(tth_splitfile)sprintf(scratchstring,"<a href=\"footnote.html#tthFtNt%s\" id=\"tthFref%s\">",ftntcode,ftntcode);else /*sf*/
  sprintf(scratchstring,
	  "<a href=\"#tthFtNt%s\" id=\"tthFref%s\">",ftntcode,ftntcode);
  TTH_OUTPUT(scratchstring);
  bracecount--;
  TTH_CCPY(argchar,"\\tth_footnote");
  storetype=3;             /* Make argchar to be rescanned */
  yy_push_state(dupgroup); /* Puts in anchors */
  yy_push_state(embracetok);
}

\\tth_footnote { /* xdef footnote with reference.*/
  if(tth_debug&4) fprintf(stderr,"tthfootnote, dupstore=%s\n",dupstore);
  TTH_OUTPUT("</a>");  /* end the anchors */
  sprintf(newcstr,
	  "\\xdef\\tthFtNt%s{\\tthhref{%s#tthFref%s}{#1}{#2}\\end}#tthdrop2",
	  ftntcode,filechar,ftntcode);
  TTH_TEX_FN(newcstr,2);
  }

\\tth_uppercase {
  yy_push_state(uppercase);
  tth_push_depth--;
  TTH_PRETEXCLOSE("\\tth_endupper");
  tth_push_depth++;
}
<uppercase>[a-z]*     {
  for(jscratch=0;jscratch<strlen(yytext);jscratch++) {
    *(yytext+jscratch)=toupper(*(yytext+jscratch));}
  TTH_OUTPUTH(yytext);horizmode=1;
 }
<uppercase>\"[a-z]   |
<uppercase>\\(\'|\`|\"|\^|\~)[a-z] {
  *(yytext+strlen(yytext)-1)=toupper(*(yytext+strlen(yytext)-1));
  TTH_SCAN_STRING(yytext);
}

\\halign{SP}*to{SP}*\\hsize{WSP}*\{  |
\\halign{WSP}*\{	{
  TTH_INC_MULTI;
  yy_push_state(htemplate);
  *scratchstring=0;
  /*  strcpy(scrstring,"&{"); */
  strcpy(scrstring,"&");
  ncols=0;
  TTH_PUSH_CLOSING;
  TTH_CCPY(closing,"</table>\n");
  TTH_HAL_PUSH;
  *halstring=0;
  halignenter=tth_push_depth; 
 }
<htemplate>\\vrule  {
 strcpy(scratchstring," border=\"1\"");
 TTH_CCAT(scrstring,yytext);
}
 /* Add template interpretation into && strings and alignment.*/
<htemplate>& {
  TTH_CCAT(halstring,tdalign);
  /*  TTH_CCAT(scrstring,"}&|");  */
  TTH_CCAT(scrstring,"&|");  
  TTH_CCAT(halstring,scrstring);
  /*  strcpy(scrstring,"&{");*/
  strcpy(scrstring,"&");
  /*TTH_CCAT(scrstring,"&|");  
  if(strlen(scrstring)>3){
    TTH_CCAT(halstring,scrstring);
  }else {TTH_CCAT(halstring,"|");}
  strcpy(scrstring,"&"); Old version */
  *tdalign=0;
  js2=ncols; /* signifies that we are in the first part of the cell */
} 
<htemplate>\\(hfill?|hss) {
  if(*tdalign==0) {
    strcpy(tdalign,"r"); 
  } else if(ncols!=js2){
    if(*tdalign=='r') strcpy(tdalign,"c"); else strcpy(tdalign,"l");
    yy_push_state(removespace);
  }
}
<htemplate>#       {
  ncols++;
  TTH_CCAT(scrstring,"&");
  if(strlen(scrstring)>2){TTH_CCAT(halstring,scrstring);}
  strcpy(scrstring,"&");
  if(!*tdalign) strcpy(tdalign,"l");
}
<htemplate>\\#|\\&|\\% |
<htemplate>\n TTH_INC_LINE;TTH_CCAT(scrstring,yytext);
<htemplate>.  TTH_CCAT(scrstring,yytext);
<htemplate>\\cr  { /* New version uses the scanning of template. */
  /*
  TTH_CCAT(scrstring,"&");  
  TTH_CCAT(halstring,tdalign);
  if(strlen(scrstring)>2)  {TTH_CCAT(halstring,scrstring);}
  */
  /*  TTH_CCAT(scrstring,"}&");  */
  TTH_CCAT(scrstring,"&");  
  TTH_CCAT(halstring,tdalign);
  TTH_CCAT(halstring,scrstring);
  if(tth_debug&32)fprintf(stderr,"halign format string:%s> ",halstring);
  *tdalign=0;*dupstore=0;
  yy_pop_state();
  yy_push_state(hendline); /* check for multicol at start */
  TTH_PUSH_BUFF(0);halbuff=yy_scan_string(halstring); /* Setup halbuff */
  yy_switch_to_buffer(include_stack[--tth_stack_ptr]); 
  fprintf(tth_fdout,"\n<table%s>",scratchstring);
}

 /*  end of halign and htemplate */

 /*  Hack of valign allowing only one row . */
\\valign{WSP}*\{	{
  TTH_INC_MULTI;
  yy_push_state(valign);
  yy_push_state(vtemplate);
  *valignstring=0;
  valsec=0;
  TTH_PRETEXCLOSE("\\tthexitvalign");
  TTH_PUSH_CLOSING;
  TTH_CCPY(closing,"</td></tr></table>\n");
 }

<vtemplate>#       valsec++;
<vtemplate>\\(vfill?|vss) {
  if(valsec){
    if(*valignstring){
      TTH_CCPY(valignstring," valign=\"middle\"");    
    }else{
      TTH_CCPY(valignstring," valign=\"top\"");
    }
  }else{
    TTH_CCPY(valignstring," valign=\"bottom\"");
  }
}
<vtemplate>\\cr {
  fprintf(tth_fdout,"\n<table><tr><td%s>",valignstring);
  yy_pop_state();
}    


<textsc>\\tth_endsmallcaps              |
<uppercase>\\tth_endupper		{
  yy_pop_state();
}
   /* altered approach to input*/
\\@input   |
\\include  |
\\input	      yy_push_state(inputfile);yy_push_state(removespace); 
<inputfile><<EOF>>  TTH_SCAN_STRING(" \\tth_eof");
<inputfile>{CMNT} |
<inputfile>{NL} TTH_INC_LINE;TTH_SCAN_STRING(" ");
<inputfile>\}   |
<inputfile>{TSP}*   {
    if ( tth_stack_ptr >= MAX_INCLUDE_DEPTH )
      {
      fprintf(stderr, "**** Error: Fatal. Includes nested too deeply. Line %d\n",tth_num_lines);
      TTH_EXIT( 1 );
    }
  if(tth_allowinput){
    strcpy(scratchstring,input_filename);
    if( (tth_inputfile=TTH_FILE_OPEN(scratchstring)) == NULL){
      strcat(scratchstring,".tex");
      if ( (tth_inputfile=fopen(scratchstring,"r")) == NULL){
	if(strlen(tth_texinput_path) > 0){
	  chscratch=tth_texinput_path;
	  while(strlen(chscratch)){
	    if((js2=strcspn(chscratch,PATH_SEP))){
	      strcpy(scratchstring,chscratch);
	      strcpy(scratchstring+js2,DIR_SEP);
	      strcat(scratchstring,input_filename);
	      if(tth_debug&128)
		fprintf(stderr,"Input try file:%s\n",scratchstring);
	      chscratch=chscratch+js2;
	      chscratch=chscratch+strspn(chscratch,PATH_SEP);
	      if ( (tth_inputfile=fopen(scratchstring,"r")) == NULL){
		strcat(scratchstring,".tex");
		tth_inputfile=fopen(scratchstring,"r");
	      }
	    }else{++chscratch;}
	    if(tth_inputfile)break;
	  }
	}
      }
    }
    if(tth_inputfile){
      if(tth_debug&1) fprintf(stderr,"Input file: %s\n",scratchstring);
      sprintf(scrstring,"\\tth_fileclose%p ",tth_inputfile);
      TTH_SCAN_STRING(scrstring);
      include_stack[tth_stack_ptr++] = YY_CURRENT_BUFFER;
      yy_switch_to_buffer(yy_create_buffer( tth_inputfile, YY_BUF_SIZE));
    }else{
      fprintf(stderr,"Input file %s not found\n",input_filename);
    }
  }else{
    fprintf(stderr,"Input of file %s not allowed.\n",input_filename);
  }
  *input_filename=0;
  yy_pop_state();
 }
<inputfile>\{  
<inputfile>.  TTH_CCAT(input_filename,yytext);
  /* Specific internal commands to expand in inputfile */
<inputfile>\\jobname   TTH_SCAN_STRING(tth_latex_file);
<inputfile>\\[a-zA-Z@]+ {
  TTH_DO_MACRO
    else{
      TTH_CCAT(input_filename,yytext);
    }
}

<verbatim,notags>\\tth_fileclose[^ ]*[ ] |
\\tth_fileclose[^ ]*[ ] {
#ifdef MSDOS
    /* pointer reading is broken in DJGPP */
  sscanf(yytext,"\\tth_fileclose%x ",&tth_inputfile);
#else
  sscanf(yytext,"\\tth_fileclose%p ",&tth_inputfile);
#endif
  if(!fclose(tth_inputfile)) {
    if(tth_debug&1){
      fprintf(stderr,"Closing %s.\n",yytext);
    }
  }else{ 
    fprintf(stderr,"**** Error closing %s. ",yytext);
    fprintf(stderr," Apparent file pointer:%p.\n",tth_inputfile);
  }
  
  tth_inputfile=NULL;
} 

\\font{SP}*\\[^ \t\r\n=]*[ \t\r\n=]*[^ \t\r\n%]*{WSP}*(((at{WSP}*{NUM}{WSP}*(true{SP}*)?pt)|(scaled[ \t\r\n\\]*[^ \t\r\n\\%]*)){NL}?)? {
  TTH_INC_MULTI;
 if(tth_fontguess){/* Try to guess what size etc is being called for. */
  strcpy(scratchstring,yytext);
  jscratch=0;
  js2=0;
  if(tth_debug&2048)fprintf(stderr,"Font definition start:%s\n",scratchstring);
  if((chscratch=strstr(scratchstring," at ")) != NULL){ /* at NNpt */
    chscratch=chscratch+4+strspn(chscratch+4," ");
    if(strspn(chscratch,"0123456789")){
      *(chscratch+strspn(chscratch,"0123456789"))=0;
      sscanf(chscratch,"%d",&js2);
      jscratch=(js2-10)/2;
    }
  }
  if(!js2){  /* No "at", Guess scaled */
    if((chscratch=strstr(scratchstring,"\\magstep")) != NULL){
      if(strspn(chscratch+8,"1234567890")){
	*(chscratch+8+strspn(chscratch+8,"1234567890"))=0;
	sscanf(chscratch+8,"%d",&jscratch);
	*chscratch=0;
      }
    }
    if(strcspn(scratchstring,"123456789") != strlen(scratchstring)){
      sscanf(scratchstring+strcspn(scratchstring,"123456789"),"%d",&js2);
      jscratch=jscratch + (js2-10)/2; /* Approx */
      *(scratchstring+strcspn(scratchstring,"123456789"))=0;
    }
  }
  chscratch=strstr(scratchstring+1,"\\");
  chscratch=chscratch+strcspn(chscratch," =");
  if(strstr(chscratch,"mb") != NULL) strcpy(defstore,"\\rmfamily\\bf");
  else if(strstr(chscratch,"mr") != NULL) strcpy(defstore,"\\rmfamily");
  else if(strstr(chscratch,"mssb") != NULL) strcpy(defstore,"\\sffamily\\bf");
  else if(strstr(chscratch,"mssi") != NULL) strcpy(defstore,"\\sffamily\\it");
  else if(strstr(chscratch,"mss") != NULL) strcpy(defstore,"\\sffamily ");
  else if(strstr(chscratch,"msl") != NULL) strcpy(defstore,"\\rmfamily\\it");
  else if(strstr(chscratch,"mi") != NULL) strcpy(defstore,"\\rmfamily\\it");
  else if(strstr(chscratch,"mtti") != NULL) strcpy(defstore,"\\ttfamily\\it");
  else if(strstr(chscratch,"mttb") != NULL) strcpy(defstore,"\\ttfamily\\bf");
  else if(strstr(chscratch,"mtt") != NULL) strcpy(defstore,"\\upshape\\ttfamily");
  else *defstore=0;
  switch(jscratch){
  case 1: strcat(defstore,"\\large ");break;
  case 2: strcat(defstore,"\\Large ");break;
  case 3: strcat(defstore,"\\LARGE ");break;
  case 4: case 5: case 6: case 7: case 8: strcat(defstore,"\\huge ");break;
  case -1: strcat(defstore,"\\small ");break;
  case -2: strcat(defstore,"\\footnotesize ");break;
  case -3: strcat(defstore,"\\scriptsize ");break;
  case -4: case -5: case -6:  strcat(defstore,"\\tiny ");break;
  default : strcat(defstore,"\\normalsize ");break;
  }  
  chscratch=strstr(scratchstring+1,"\\");
  *(chscratch+strcspn(chscratch," ="))=0;
  sprintf(dupstore,"\\def%s{%s}",chscratch,defstore);
  if(tth_debug&2048)fprintf(stderr,"Font definition:%s\n",dupstore);
  *defstore=0;
  TTH_SCAN_STRING(dupstore);
  *dupstore=0;
 }else 	fprintf(tth_fdout," ");
}
 /* Latex counters etc.*/
\\newcounter{WSP}*\{[a-zA-Z@]*\}  {
  TTH_INC_MULTI;
  sprintf(newcstr,"\\tth_newcounter%s",strstr(yytext,"{"));
  TTH_TEX_FN_OPT(newcstr,1,""); 
  /* This does not work using scratchstring. Need a permanent String*/
}
<psub>\\tth_newcounter\{[a-zA-Z@]*\} {
  if(tth_debug&4)fprintf(stderr,"Newcounter: %s\n",yytext);
  strcpy(dupstore2,"\\");strcat(dupstore2,yytext+strcspn(yytext,"{")+1);
  *(strstr(dupstore2,"}"))=0;
  mkkey(dupstore2,countkeys,&ncounters);
  if(tth_debug&4) fprintf(stderr,"Created new counter %s\n",dupstore2);
  sprintf(scratchstring,"\\gdef\\the%s{\\arabic{%s}}",dupstore2+1,dupstore2+1);
  strcpy(scrstring,yytext);
  TTH_SCAN_STRING(scratchstring);
  /* New using opt arg.*/
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1){
    sprintf(scratchstring,"\\%s",margs[jscratch]);
    yy_pop_state();
    rmdef(margkeys,margs,&margmax);
  }
  if(strlen(scratchstring)>1){
    if((ind=indexkey(scratchstring,countkeys,&ncounters)) != -1){
      *scrstring=0;
      i=ind;
      if(countwithins[ind]){
	strcpy(scrstring,countwithins[i]);
	i++;
	rmkey(countwithins,&i);
      }
      strcat(scrstring,dupstore2+1);
      strcat(scrstring,",");
      mkkey(scrstring,countwithins,&i);
      if(tth_debug&4)fprintf(stderr,"Added %s to withins of %s:%s\n",
			     dupstore2+1,scratchstring,scrstring);
    }else{
     fprintf(stderr,"**** Error: No such counter for \"within\" option: %s. Line %d\n",
	     scratchstring,tth_num_lines);
    }
  }
  *dupstore2=0;
  if(horizmode)horizmode=1;
 }
\\setcounter{WSP}*\{[a-zA-Z]*\}{WSP}*\{({NUM}|{SP}*\\value\{[a-zA-Z]*\}{SP}*)\}  {
  TTH_INC_MULTI;
  if(tth_debug&4)fprintf(stderr,"Setcounter: %s\n",yytext);
  yytext=yytext+strcspn(yytext,"{");
  TTH_CCPY(argchar,yytext);*(argchar+strcspn(argchar,"}"))=0;
  *(argchar)='\\';
  if((ind=indexkey(argchar,countkeys,&ncounters)) != -1){
    yy_push_state(counterset);
    if((chscratch=strstr(yytext,"\\value")) != NULL){
      strcpy(dupstore2,(chscratch+6));
      *dupstore2='\\';
    }else{
      strcpy(dupstore2,yytext+1+strcspn(yytext+1,"{")+1);
    }
    *(dupstore2+strcspn(dupstore2,"}"))=0;
    TTH_SCAN_STRING(dupstore2);
    *dupstore2=0;
  }else fprintf(stderr,"**** No counter: %s to set. Line %d\n",argchar,tth_num_lines);
  *argchar=0;
 }
\\addtocounter  iac=-1;yy_push_state(advance);  yy_push_state(removespace);
\\(arabic|alph|Alph|roman|Roman)\{[a-zA-Z]+\} {
  if(strstr(yytext,"alph")) jscratch=1;
  else if(strstr(yytext,"Alph")) jscratch=2;
  else if(strstr(yytext,"roman")) jscratch=3;
  else if(strstr(yytext,"Roman")) jscratch=4;
  else jscratch=0;
  if((chscratch=strstr(yytext,"{"))!=NULL) yytext=chscratch;
  else yytext=yytext+3;
  if((chscratch=strstr(yytext,"}"))!=NULL) *chscratch=0;
  *yytext='\\';
  TTH_SCAN_STRING(yytext);
  yy_push_state(number);if(horizmode)horizmode=1;
 }
\\stepcounter{WSP}*\{[a-zA-Z]*\} {
  TTH_INC_MULTI;
  strcpy(scratchstring,yytext+strcspn(yytext,"{"));
  *scratchstring='\\';
  *(scratchstring+strlen(scratchstring)-1)=0;
  if((ind=indexkey(scratchstring,countkeys,&ncounters)) != -1){
    strcpy(dupstore2,"\\addtocounter");
    strcat(dupstore2,yytext+strcspn(yytext,"{"));
    strcat(dupstore2,"{1}");
    if(countwithins[ind]){
      strcpy(scrstring,countwithins[ind]);
      chscratch=scrstring;
      while((chs2=strstr(chscratch,",")) != NULL){
	*chs2=0;
	sprintf(dupstore2+strlen(dupstore2),"\\setcounter{%s}{0}",chscratch);
	chscratch=chs2+1;
      }
    }
    if(tth_debug&4) fprintf(stderr,"Stepping counter:%s\n",dupstore2);
    TTH_SCAN_STRING(dupstore2);
  }else{
    fprintf(stderr,"**** No counter:%s to step. Line %d\n",scratchstring,tth_num_lines);
  }
  *dupstore2=0;if(horizmode)horizmode=1;
 }
\\@addtoreset({WSP}*\{[a-zA-Z]*\}){2} {
  TTH_INC_MULTI;
  chscratch=yytext+strcspn(yytext,"{")+1;
  chs2=chscratch+strcspn(chscratch,"{")+1;
  *(chscratch+strcspn(chscratch,"}"))=0;
  *(chs2+strcspn(chs2,"}"))=0;
  strcpy(scratchstring,"\\");
  strcat(scratchstring,chs2);
  if((ind=indexkey(scratchstring,countkeys,&ncounters)) != -1){
    *scrstring=0;
    i=ind;
    if(countwithins[ind]){
      strcpy(scrstring,countwithins[i]);
      rmkey(countwithins,&i);
      i++;
    }
    strcat(scrstring,chscratch);
    strcat(scrstring,",");
    mkkey(scrstring,countwithins,&i);
    if(tth_debug&4)fprintf(stderr,"Added %s to withins of %s:%s\n",
			 chscratch,scratchstring,scrstring);
  }else{
    fprintf(stderr,"**** Error: No such counter for \"within\" option: %s. Line %d\n",
	    scratchstring,tth_num_lines);
  }
}
 
 /* TeX counters */
\\newcount   {
  if(horizmode)horizmode=1;yy_push_state(getcount);yy_push_state(removespace);}
<getcount>\\[a-zA-Z]+ {
  mkkey(yytext,countkeys,&ncounters);yy_pop_state();
 }
<getcount>.  fprintf(stderr,"Ill-formed newcount");yy_pop_state();


\\advance     {iac=-1;yy_push_state(advance);if(horizmode)horizmode=1;}

<advance>{WSP}*    TTH_INC_MULTI;

 /*
<advance>\\[a-zA-Z]+((margin)|(width)|(height)|(size)|(offset)|(indent)){SP}*(by)?    { 
  TTH_INC_MULTI;
  if(tth_debug&4) fprintf(stderr,"Removing dimension advance: %s\n",yytext);
  yy_pop_state();
  GET_DIMEN;
 } Override the real command */

<advance>\{[a-zA-Z]*\}{WSP}*\{(({NUM})|({SP}*\\value\{[a-zA-Z]*\}{SP}*))\} {
  /* Latex addtocounter. Convert into plain form. */
  TTH_INC_MULTI;
  *yytext='\\';
  *(yytext+strcspn(yytext,"}"))=' ';
  *(yytext+strcspn(yytext,"{"))=' ';
  *(yytext+strlen(yytext)-1)=0;
  if((chscratch=strstr(yytext,"\\value")) != NULL){
    strcpy(chscratch,"      ");
    *(chscratch+6)='\\';
    *(chscratch+strcspn(chscratch,"}"))=0;
  }
  if(tth_debug&4)fprintf(stderr,"Latex advance string:%s\n",yytext);
  TTH_SCAN_STRING(yytext);
}

<advance,dimadv>by
<advance>\\tthdimen[ ]?\\[a-zA-Z]+ {/* Dimension advancing: get counter name.*/
  chscratch=yytext+strlen("\\tthdimen");
  strcpy(newcstr,chscratch+strspn(chscratch," "));
  yy_pop_state();
  yy_push_state(dimadv); /* Prepare to get second and advance. */
  dimadvstate=0;
  GET_DIMEN;
  if(tth_debug&1024)fprintf(stderr,"Advancing %s\n",newcstr);
}

<dimadv>.|\n {
  yyless(0);
  if(!dimadvstate){ /* Return of first time we have the first num,unit. */
    cnumber=anumber;
    strcpy(scrstring,scratchstring);
    GET_DIMEN;
    dimadvstate=1;
  }else{
    if(tth_debug&1024)fprintf(stderr,"Adding: %f %s, %f %s\n",
			      cnumber,scrstring,anumber,scratchstring);
    adddimen(&cnumber,scrstring,&anumber,scratchstring);
    if(*scrstring=='%')strcpy(scrstring,"\\tth_hsize");
    yy_pop_state();
    sprintf(scratchstring,"%s %f%s",newcstr,cnumber,scrstring);
    if(tth_debug&1024)fprintf(stderr,"Dimension advance string:%s\n",scratchstring);
    TTH_SCAN_STRING(scratchstring);
    dimadvstate=0;
  }
}


<advance>[+-]+ {
  if(strcspn(yytext,"-") < strlen(yytext)) minus=-1;
}             
<advance>{NUM}             |
<advance>\\[a-zA-Z]+  {
  if(iac==-1){ /* First time we are getting the one to set */ 
    iac=indexkey(yytext,countkeys,&ncounters);
    if(tth_debug&4) fprintf(stderr,"First advance:%s: %d, currently: %d.\n",
	    yytext,iac,counters[iac]);
    if(iac == -1) {
      TTH_DO_MACRO else{
	if(!(tth_debug&32768))
	  fprintf(stderr,"**** Unknown counter to advance: %s\n",argchar);
	yy_pop_state();
	GET_DIMEN;
      }
    } else {
      strcpy(argchar,yytext);
    }
  }else{
    if(tth_debug&4) fprintf(stderr,"Advancing counter %d, %s by %s. "
			    ,iac,argchar,yytext);
    if(strcspn(yytext,"0123456789") < strlen(yytext)){
      sscanf(yytext+strcspn(yytext,"+-0123456789"),"%d",&jac);
      counters[iac]=counters[iac]+jac*minus;
      jac=0;
    } else {
      TTH_CCPY(newcstr,yytext+strcspn(yytext,"\\"));
      jac=indexkey(newcstr,countkeys,&ncounters);
      if(jac == -1) {
	TTH_DO_MACRO else{
	  if(!(tth_debug&32768))
	    fprintf(stderr,"**** Unknown counter: %s\n",newcstr);
	  jac=-2; /* Quit. Expansion is exhausted. */
	}
      } else {
	if(strcspn(yytext,"-") == strlen(yytext)) {
	  counters[iac]=counters[iac]+minus*counters[jac];
	}else{
	  counters[iac]=counters[iac]-minus*counters[jac];
	}
      }
    }
    if(jac!=-1){
      minus=1;
      yy_pop_state();
      if(tth_debug&4) fprintf(stderr,"New counter value=%d\n",counters[iac]);
      *argchar=0;
    }
  }
}
<advance>.   {
  fprintf(stderr,"**** Error. Ill-formed \\advance statement\n");
  yy_pop_state();
}

<getifnum>\\value{WSP}*\{[a-zA-Z]*\} |
\\value{WSP}*\{[a-zA-Z]*\} {
  chscratch=strstr(yytext,"{");
  strcpy(scratchstring,chscratch);
  *(scratchstring+strcspn(scratchstring,"}"))=0;
  *(scratchstring)='\\';
  TTH_SCAN_STRING(scratchstring);    
  }

<exptokarg>\\number{SP}* | /* Needed for unembraced ^\the\counter*/   
<exptokarg>\\the{SP}* |
\\the{SP}* |        /*Pretend the is number. It is the same for counters.*/
\\number{SP}*     yy_push_state(number);jscratch=0;
<number>\\[a-zA-Z]+   {
  i=indexkey(yytext,countkeys,&ncounters);
  if(i == -1) {
    TTH_DO_MACRO else {
      if(!(tth_debug&32768))
	fprintf(stderr,"**** Unknown counter for number, %s\n",yytext);
      yy_pop_state();
    }
  } else {
    switch(jscratch){ 
    case 0: sprintf(dupstore2,"%d",counters[i]);break;
    case 1: sprintf(dupstore2,"%c",counters[i]+96);break;
    case 2: sprintf(dupstore2,"%c",counters[i]+64);break;
    case 3: roman(counters[i],dupstore2);break;
    case 4: roman(counters[i],dupstore2);
      for(js2=0;js2<strlen(dupstore2);js2++)
	*(dupstore2+js2)=toupper(*(dupstore2+js2));
      break;
    }
/*      if(tth_debug&4) fprintf(stderr,"Found counter %s=%s\n",yytext,dupstore2); */
    TTH_PUSH_BUFF(1);yy_scan_string(dupstore2);
    *dupstore2=0;
    yy_pop_state();
  }
}
<number>.   fprintf(stderr,"No number at character:%s",yytext);yy_pop_state();
<counterset>{SP}*=*{SP}*     /* Remove optional = and space */
<counterset>\{    TTH_PUSH_CLOSING;
<counterset>{NUM} {
  sscanf(yytext+strcspn(yytext,"+-0123456789"),"%d",&counters[ind]);
  if(tth_debug&4) fprintf(stderr,"Counter %d set to %d\n",ind,counters[ind]);
  yy_pop_state();
  }
<counterset>[+-]*\\[a-zA-Z]+ {
  js2=ind; /* Save ind because it is used by TTH_DO_MACRO */
  i=indexkey(yytext+strcspn(yytext,"\\"),countkeys,&ncounters);
  if(i == -1){
    TTH_DO_MACRO
    else{
      if(!(tth_debug&32768))
	fprintf(stderr,"**** Unknown counter for counterset, %s\n",
	    yytext+strcspn(yytext,"\\"));
      yy_pop_state();
    }
    ind=js2;
  }else{
    counters[ind]=counters[i];
    if(strcspn(yytext,"-") != strlen(yytext)) counters[ind]=-counters[ind];
    yy_pop_state();
    if(tth_debug&4)fprintf(stderr,"Counter %d set to %d\n",ind,counters[ind]);
  }
 }
<counterset>.|\n {
  fprintf(stderr,"**** Error: Failed to find value to set counter %s.\n",countkeys[ind]);
  yy_pop_state();
}


 /* Definitions */
\\let 	{	
  localdef=1;
  if(tth_debug&4) fprintf(stderr,"%s(localdef=%d)",yytext,localdef);
  /* yy_push_state(define); */
  yy_push_state(letdef);
  yy_push_state(getnumargs);
  yy_push_state(embracetok); /* Prevent let looking for arguments */
  yy_push_state(getdef);
  }
<letdef>\} {  /* others are the same as <define> */
  if(!bracecount){
    if(tth_debug&4) fprintf(stderr,"Close brace ending let,count=%d\n",
			     bracecount);
    yy_pop_state();
    strcpy(scratchstring,defstore+strspn(defstore," {"));
    *(scratchstring+strcspn(scratchstring,"}"))=0;
    if((i=indexkey(scratchstring,keys,&nkeys))==-1){
      if(tth_debug&4) fprintf(stderr,"Macro %s not found for \\let. Presuming native.\n",scratchstring);
      strcat(defstore,"#tthdrop");
      sprintf((defstore+strlen(defstore)),"%d",abs(narg));
      if(nkeys < NFNMAX) {
	lkeys[nkeys]=localdef;
	mkdef(defchar,keys,defstore,defs,&narg,nargs,&nkeys);
	if(tth_debug&4){
	  i=indexkey(defchar,keys,&nkeys);
	  fprintf(stderr,"  Just Defined Key %s index %d nargs %d Def %s\n",
		  defchar,i,nargs[i],defs[i]);
	}
      }
      else fprintf(stderr,"Too many functions to define %s",defchar);
    }else{
      if(nkeys < NFNMAX) {
	lkeys[nkeys]=localdef;
	mkdef(defchar,keys,defs[i],defs,nargs+i,nargs,&nkeys);
	if(tth_debug&4){
	  i=indexkey(defchar,keys,&nkeys);
	  fprintf(stderr,"Defined Let Key %s index %d nargs %d Def %s\n",
		  defchar,i,nargs[i],defs[i]);
	}
      }else fprintf(stderr,"Too many functions to define %s",defchar);
    }
    *defchar=0;
    *defstore=0;
  } else {
    if(tth_debug&4) fprintf(stderr,"Close brace in [e]def, count=%d\n",
			     bracecount);
    strcat(defstore,yytext);bracecount--;
  }
}

(\\def|\\gdef|\\global\\def)	{
  if(*(yytext+1)!='d')localdef=0; else localdef=1;
  if(tth_debug&4) fprintf(stderr,"%s(localdef=%d)",yytext,localdef);
  yy_push_state(define);  
  yy_push_state(getnumargs);
  yy_push_state(getdef);
  }
(\\edef|\\xdef|\\global\\edef) {
  if(*(yytext+1)!='e')localdef=0; else localdef=1;
  if(tth_debug&4) fprintf(stderr,"%s(localdef=%d)",yytext,localdef);
  edeftype=1;
  yy_push_state(define);  
  yy_push_state(getnumargs); /* determine no of args */
  yy_push_state(getdef);  /* determine the key of definition */
  }
<getdef>{NL} TTH_INC_LINE;
<getdef>{TSP}*
<getdef>\{  yy_push_state(getdefbr);strcpy(dupstore,"{");
<getdefbr>\} {  /* Really ought to match braces. */
  /*fprintf(stderr,"getdefbr strings:%s:%s:",yytext,dupstore);*/
  yy_pop_state();
  TTH_CCPY(defchar,dupstore+strspn(dupstore,"{ \t\n"));
  yy_pop_state();*dupstore=0;
  /* If this is a true definition, terminate at space etc.*/
  if(*defchar=='\\')
    *(defchar+strcspn(defchar," =}"))=0;
  if(tth_debug&4) fprintf(stderr,":%s,",defchar);
}
<getdefbr>.  strcat(dupstore,yytext);
<getdef>\\[a-zA-Z@]+({SP}*=)? 	{
  /*fprintf(stderr,"getdef string:%s:",yytext);*/
  TTH_CCPY(defchar,yytext+strspn(yytext,"{ \t\n"));
  yy_pop_state();*dupstore=0;
  *(defchar+strcspn(defchar," =}"))=0;
  if(tth_debug&4) fprintf(stderr,":%s,",yytext);
  }
<getdef>. {
  fprintf(stderr,
	  "\n**** Error: incompatible syntax in macro name:%s: Line %d\n",
	  yytext,tth_num_lines);
  yy_pop_state();
}

 /* Latex form accommodates arg number perhaps WSP is wrong. */
<getnumargs>{WSP}*\[[1-9]\]{WSP}*\{    |  
<getnumargs>([ \t]*{NL})?[ \t]*(#[0-9])+\{	{ /* New pattern */
  /*  sscanf((yytext+strcspn(yytext,"] \t\n{")-1),"%d",&narg); */
  TTH_INC_MULTI;
  sscanf((yytext+strcspn(yytext,"]{")-1),"%d",&narg);
  yy_pop_state();
  if(tth_debug&4) fprintf(stderr," %d arguments.\n",narg);
  }
<getnumargs>\{	{
  narg=0;
  yy_pop_state();
  if(tth_debug&4) fprintf(stderr," no arguments.\n");
  }
<getnumargs>(([^\{#]*#[0-9])+[^\{#]*)+\{   {
  if(tth_delimdef){
    yy_pop_state();
    if(tth_debug&4) fprintf(stderr,"yytext=%s",yytext);
    chs2=yytext-1;
    while(chs2 != NULL){
      chscratch=chs2;
      chs2=strstr(chscratch+1,"#");
    }
    sscanf(chscratch+1,"%d",&narg);
    narg=-narg;
    if(tth_debug&4) fprintf(stderr,
		 "Delimited definition:%s\n No of args: %d\n ",defchar,narg);
    if(nkeys < NFNMAX) {
      whitespace=1;
      horizmode=1;
      yyless(0);
      *dupstore=0; /* ought not to be needed */
      yy_push_state(ddcomp);
    }
    else fprintf(stderr,"Too many functions to define %s",defchar);
  }else{
    TTH_INC_MULTI;
    yy_pop_state();yy_pop_state();yy_push_state(matchbrace);
    fprintf(stderr,"Discarding delimited definition:%s\n",defchar);
  }
}
<ddcomp>{NL} {
  if(!whitespace)strcat(dupstore," ");
  TTH_INC_LINE;
  whitespace=1;
  if(horizmode==1){
    horizmode=-1;
    yy_push_state(parcheck);  
  }else{
    if(horizmode==-1){
      fprintf(stderr,"**** Abnormal NL in -1 ddcomp.\n");
/*        horizmode=0;strcat(dupstore,"\\par"); */
    }
  }
}
<ddcomp>[ \t]         {if(!whitespace){strcat(dupstore," ");} whitespace=1; }
<ddcomp>\\[a-zA-Z@]*  {whitespace=1;strcat(dupstore,yytext);}
<ddcomp>\{ {
  whitespace=0;strcat(dupstore,yytext);horizmode=1;
    lkeys[nkeys]=0;
  mkdef("",keys,dupstore,defs,&narg,nargs,&nkeys);
  if(tth_debug&4){
    fprintf(stderr,"Defined Argument-Template: index %d nargs %d Def:%s\n",
	    nkeys-1,nargs[nkeys-1],defs[nkeys-1]);
  }
  *dupstore=0;
  yy_pop_state();
}
<ddcomp>\\(\\|%|\$|&|\#)  {whitespace=0;strcat(dupstore,yytext+1);horizmode=1;}
<ddcomp>. {whitespace=0;strcat(dupstore,yytext);horizmode=1;}

<getnumargs>\[[1-9]\]{WSP}*\[[^\]]*\]{WSP}*\{   { 
  TTH_INC_MULTI;
  strcpy(scratchstring,yytext);
  chscratch=strstr(scratchstring+1,"[")+1;
  *(chscratch+strcspn(chscratch,"]"))=0;
  js2=nkeys;
  mkkey(chscratch,optargs,&js2);
  if(tth_debug&4){
    js2--;
    fprintf(stderr,"Defined Default argument %s index %d nargs %d Def %s\n",
	    chscratch,js2,nargs[js2],optargs[js2]);
  }
  strcpy(scratchstring+3,"{");
  TTH_SCAN_STRING(scratchstring);
}

\{               |
\\begingroup	 |
\\bgroup		TTH_PUSH_CLOSING;
\\tthparendgroup     |
\}               |
\\endgroup	 |
\\egroup	 {
  TTH_TEXCLOSE else{
/*    if(horizmode==-1)horizmode=1;  */
  TTH_CLOSEGROUP;TTH_POP_CLOSING;}
}
<matchbrace>\{	bracecount++;
<matchbrace>\}	{if(!bracecount){yy_pop_state();} else {bracecount--;}}
<matchbrace>\\\{ 
<matchbrace>\\\}
<matchbrace>. 

\\\+  if(!tth_LaTeX) fprintf(tth_fdout,"<table><tr><td width=\"%d\">\n",tabwidth);

\\settabs{SP}*{NUM}{SP}*\\columns {
  sscanf(yytext+8,"%d",&jscratch);
  tabwidth=1000/jscratch;
 }
\\eject           {TTH_PAR_ACTION};

  /* Standard TeX formatting switches work properly inside groups.*/
\\obeylines	fprintf(tth_fdout,"<pre>");TTH_PRECLOSE("\n</pre>");
\\tth_underline{SP}* { /* underline switch. */
  if(eqdepth && strcspn(TTH_NAME,"M")>0 ){ /* In equations not Mathml */
    TTH_CCAT(tth_font_open[tth_push_depth],TTH_UNDL1);
    TTH_CCAT(tth_font_close[tth_push_depth],TTH_UNDL2);
  }else{
    TTH_OUTPUT(TTH_UNDL1);TTH_PRECLOSE(TTH_UNDL2);
  }
 }
\\bfseries{SP}* {
  if(eqdepth){
    TTH_CCAT(tth_font_open[tth_push_depth],TTH_BOLDO);
    TTH_CCAT(tth_font_close[tth_push_depth],TTH_BOLDC);
    if(strstr(tth_texclose[tth_push_depth-1],"tth_boxclose")) {  
      TTH_OUTPUT(TTH_BOLD1);TTH_PRECLOSE(TTH_BOLD2);
      }  
  }else{
    TTH_OUTPUT(TTH_BOLD1);TTH_PRECLOSE(TTH_BOLD2);
  }
 }
\\bf{SP}*	{
  if(eqdepth){
    TTH_CCPY(tth_font_open[tth_push_depth],TTH_BOLDO);
    TTH_CCPY(tth_font_close[tth_push_depth],TTH_BOLDC);
    if(strstr(tth_texclose[tth_push_depth-1],"tth_boxclose")) {  
      TTH_OUTPUT(TTH_BOLD1);TTH_PRECLOSE(TTH_BOLD2);
    } 
  }else{
    TTH_OUTPUT(TTH_BOLD1);TTH_PRECLOSE(TTH_BOLD2);
  }
 }
  /* Implementation of \bm from math package. Bold italic.*/
\\tth_bm{SP}*	{
  if(eqdepth){
    TTH_CCPY(tth_font_open[tth_push_depth],TTH_BLDITO);
    TTH_CCPY(tth_font_close[tth_push_depth],TTH_BLDITC);
    if(strstr(tth_texclose[tth_push_depth-1],"tth_boxclose")) {  
      TTH_OUTPUT(TTH_BLDIT1);TTH_PRECLOSE(TTH_BLDIT2);
    } 
  }else{
    TTH_OUTPUT(TTH_BLDIT1);TTH_PRECLOSE(TTH_BLDIT2);
  }
 }
\\itshape{SP}* |
\\slshape{SP}* {
  if(eqdepth){
    TTH_CCAT(tth_font_open[tth_push_depth],TTH_ITALO);
    TTH_CCAT(tth_font_close[tth_push_depth],TTH_ITALC);
    if(strstr(tth_texclose[tth_push_depth-1],"tth_boxclose")) {  
      TTH_OUTPUT(TTH_ITAL1);TTH_PRECLOSE(TTH_ITAL2);
    }
  }else{
    TTH_OUTPUT(TTH_ITAL1);TTH_PRECLOSE(TTH_ITAL2);
  }
 }
\\it{SP}*  |
\\sl{SP}*	{
  if(eqdepth){
    TTH_CCPY(tth_font_open[tth_push_depth],TTH_ITALO);
    TTH_CCPY(tth_font_close[tth_push_depth],TTH_ITALC);
    if(strstr(tth_texclose[tth_push_depth-1],"tth_boxclose")) {  
      TTH_OUTPUT(TTH_ITAL1);TTH_PRECLOSE(TTH_ITAL2);
    }
  }else{
    TTH_OUTPUT(TTH_ITAL1);TTH_PRECLOSE(TTH_ITAL2);
  }
 }
\\ttfamily{SP}* |
\\tt{SP}*	{
  if(eqdepth){
    TTH_CCPY(tth_font_open[tth_push_depth],TTH_TTO);
    TTH_CCPY(tth_font_close[tth_push_depth],TTH_TTC);
    if(strstr(tth_texclose[tth_push_depth-1],"tth_boxclose")) {  
      TTH_OUTPUT(TTH_TT1);TTH_PRECLOSE(TTH_TT2);
    }
  }else{
    TTH_OUTPUT(TTH_TT1);TTH_PRECLOSE(TTH_TT2);
  }
 }
\\rmfamily{SP}* |
\\mdseries{SP}* |
\\upshape{SP}* |
\\normalfont{SP}* |
\\rm{SP}*	{
  if(eqdepth){
    TTH_CCPY(tth_font_open[tth_push_depth],TTH_NORM1);
    TTH_CCPY(tth_font_close[tth_push_depth],TTH_NORM2);
  }else{
    if(!eqdepth && !(tth_istyle&1)){ 
      TTH_OUTPUT(TTH_FONTCANCEL); /* not in equations: avoid bug */
    }else{
      TTH_OUTPUT(TTH_NORM1);TTH_PRECLOSE(TTH_NORM2);
    }
  }
}
\\scshape   { /* new approach */
  if(tth_push_depth){
    yy_push_state(textsc);
    tth_push_depth--;
    TTH_PRETEXCLOSE("\\tth_endsmallcaps");
    tth_push_depth++;}
}
\\sffamily{SP}*   {
  TTH_OUTPUT(TTH_HELV1); TTH_PRECLOSE(TTH_HELV2);}
\\boldmath{SP}* {
    TTH_CCAT(tth_font_open[tth_push_depth],TTH_BOLDO);
    TTH_CCAT(tth_font_close[tth_push_depth],TTH_BOLDC);
}  
\\unboldmath{SP}* {
    TTH_CCPY(tth_font_open[tth_push_depth],tth_fonto_def);
    TTH_CCPY(tth_font_close[tth_push_depth],tth_fontc_def);
}  

\\narrower	fprintf(tth_fdout,"<dl><dd>");TTH_PRECLOSE("</dd></dl>");

\\hang		        {
  fprintf(tth_fdout,"<dl><dd>");
  if(strstr(closing,"--vbox")){
    TTH_CCPY(scratchstring,"<!--vbox_par-->");
  }else{*scratchstring=0;}
  TTH_PUSH_CLOSING;
  TTH_CCPY(closing,scratchstring);
  TTH_CCAT(closing,"</dd></dl>\n");
  yy_push_state(pargroup);tth_eqwidth=tth_eqwidth-TTH_INDPC;}
\\hangindent	{
  TTH_PUSH_CLOSING; fprintf(tth_fdout,"<dl><dd>");
  TTH_CCPY(closing,"</dd></dl>\n");
  yy_push_state(pargroup);tth_eqwidth=tth_eqwidth-TTH_INDPC;
  GET_DIMEN }
\\hangafter   {
  fprintf(stderr,"Hangafter ignored\n");yy_push_state(lookfornum);*argchar=0;
}


 /* Getting values and units, do nothing. Only treat the explicit case. 
 A tokenized DIMEN will treat command and dimen as unknown commands.
 Removed /{NUM} also in hangindent, 1.01 (also saved 10k size)*/

\\parindent	GET_DIMEN
\\overfullrule	GET_DIMEN
 /* Setting sizes: */
\\[hv]offset	GET_DIMEN
\\[hv]fuzz	GET_DIMEN
\\(top|oddside|evenside)margin    GET_DIMEN
\\(head|text|foot)height          GET_DIMEN
\\(textwidth|headsep)             GET_DIMEN

 /*<argclear>.|\n  yyless(0);yy_pop_state(); *argchar=0; */

\\tthdimen{WSP}*\\[a-zA-Z@]+ {   /* Set a dimension that was defined. */
  strcpy(newcstr,yytext+1+strcspn(yytext+1,"\\"));
  *scratchstring=0;
  if(tth_push_depth-tth_LaTeX>0 || strcmp(newcstr,"\\hsize"))
     yy_push_state(setdimen);
  GET_DIMEN;/* Get the new dimension */
 /*    yy_push_state(argclear); */
  GET_DIMEN;/* Get the current dimension*/
  if(tth_debug&1024){fprintf(stderr,"Dimension to set: %s  Now follow the current and the new values:\n",newcstr);}
}
   /* Preexisting dimensions, skips etc. Now not preexisting.
\\hsize {
  strcpy(newcstr,yytext);*scratchstring=0;
  if(tth_push_depth-tth_LaTeX>0)yy_push_state(setdimen);
  GET_DIMEN;
} */
<setdimen>{ANY} {
  yy_pop_state();yyless(0);
  if(tth_debug&1024)fprintf(stderr,"Setdimen. scratchstring=%s, closing=%s, newcstr=%s, thesize=%d\n",scratchstring,closing,newcstr,thesize);
  if(thesize){
    if(*scratchstring=='%') {
      sprintf(scrstring,"\\def%s{\\tthdimen%s %f%s}",
	      newcstr,newcstr,anumber,"\\tth_hsize");
      if(strstr(closing,"<!--vbox-->")!=NULL
	 && strstr(newcstr,"\\hsize")!=NULL){
	sprintf(scratchstring,"</td><td width=\"%d\"%s>\n",
		(thesize*DEFAULTHSIZEPIX)/100,boxalign); /*Guess at width */
	TTH_OUTPUT(scratchstring);
      }
    }else if(strlen(scratchstring)){
      sprintf(scrstring,"\\def%s{\\tthdimen%s %f%s}",
	      newcstr,newcstr,anumber,scratchstring);
      if(strstr(closing,"<!--vbox-->")!=NULL
	 && strstr(newcstr,"\\hsize")!=NULL){
	sprintf(scratchstring,"</td><td width=\"%d\"%s>\n",
		thesize/SCALEDPERPIXEL,boxalign);
	TTH_OUTPUT(scratchstring);
      }
    }
    TTH_SCAN_STRING(scrstring);
  }
}
\\[a-zA-Z]*size	{
  TTH_DO_MACRO
    else{GET_DIMEN;}
}
\\hspace\*?  TTH_TEX_FN("\\hskip #1{}#tthdrop1",1);
\\vspace\*?  TTH_TEX_FN("\\vskip #1{}#tthdrop1",1);
\\hskip {
  yy_push_state(hskip);
  yy_push_state(glue);GET_DIMEN;
}
<hskip>{ANY} {
  if(*scratchstring=='%'){ /* Size is in % of hsize. Guess 100 nbsp per line!*/
    for(js2=0;js2<thesize;js2++){TTH_OUTPUT("&nbsp;");}
  }else{ /* Absolute size. Guess that a &nbsp; is 5 pixels wide */
    for(js2=0;js2<(thesize/(SCALEDPERPIXEL*5));js2++){TTH_OUTPUT("&nbsp;");}
  }
  yy_pop_state(); yyless(0);
}
\\vskip {
  yy_push_state(vskip);
  yy_push_state(glue);GET_DIMEN;
}
<vskip>{ANY} {  /*Guess that <br /> is 14 pixels */
  for(js2=0;js2<(thesize/(SCALEDPERPIXEL*14));js2++){TTH_OUTPUT("<br />");}
  yy_pop_state(); yyless(0);
}
\\hglue         |
\\[a-zA-Z]*(skip|sep)  {
  TTH_DO_MACRO
  else{
    if(horizmode) horizmode=1;
    if(tth_debug&1) fprintf(stderr,"Removing glue command:%s\n",yytext); 
    yy_push_state(glue);GET_DIMEN;
  }
 }
\\(vtop|vbox)({SP}+to|spread)* {
  if(!horizmode || horizmode==3 ||  strstr(closing,"<!--hbox") || 
     strstr(tth_texclose[tth_push_depth-1],"tthhbclose")){
    if(strstr(yytext,"vtop")){    
      TTH_CCPY(boxvalign,"</td><td valign=\"top\">");
    }else{
      TTH_CCPY(boxvalign,"</td><td>");
    }
    if(tth_debug&1024)fprintf(stderr,"Entering vbox state\n");
    yy_push_state(vbox);
    if(strstr(yytext+4,"to")||strstr(yytext+4,"spread")){GET_DIMEN;}
  }else{
    yyless(0);
    TTH_OUTPUT("<table border=\"0\"><tr><td>");
    TTH_PRETEXCLOSE("\\tthhbclose");
    if(tth_debug&1024)fprintf(stderr,"Entering vbox parclose state\n");
    yy_push_state(parclose);
    TTH_PUSH_CLOSING;
    TTH_CCAT(closing,"</td></tr></table><!--hboxt-->");
  }
}

\\tthhbclose {
  if(tth_debug&1024)fprintf(stderr,"tthhbclose Stack_ptr=%d. Closing=%s\n",tth_stack_ptr,closing);
  yy_pop_state();
  if(tth_debug&1024)fprintf(stderr,"tthhbclose pop completed\n");
  TTH_CLOSEGROUP;TTH_POP_CLOSING;
}


<vbox>(\\bgroup|\{){WSP}*(\\advance)?(\\hsize)? {
  if(tth_debug&1024)fprintf(stderr,"Starting vbox\n");
  yy_pop_state();
  /*If box does not start with explicit hsize manipulation, make it do so. */
  chscratch=strstr(yytext,"\\hsize");
  js2=1+strcspn(yytext+1,"\\");
  yyless(js2);
  if(chscratch){
/*      fprintf(stderr,"vbox:%s\n",yytext); */
  }else{
    if((ind=indexkey("\\hsize",keys,&nkeys))!=-1){/*hsize is defined*/
      if(indexkey("\\hsize",keys,&ind)!=-1){/*hsize is currently redefined*/
	/* Must be done after the yyless */
	TTH_SCAN_STRING("\\hsize=\\hsize ");/*Set size at the start of vbox*/ 
	if(tth_debug&1024)fprintf(stderr,"Vbox auto hsize reset\n"); 
      }
    }
  }
  *scratchstring=0;
  if(strstr(closing,"<!--hbox--")){
    if(!strstr(closing,"<br clear")){
      TTH_CCAT(closing,"<br clear=\"all\" />");
      if(horizmode){TTH_OUTPUT("<br />");} /* To avoid table bugs */
    }
    TTH_OUTPUT("<table border=\"0\" align=\"left\"><tr><td>");
  }else{
    if(strstr(closing,"<!--hboxt--")){
      TTH_OUTPUT(boxvalign);
      *boxvalign=0;
      TTH_CCPY(scratchstring,"\n</td><td>");
    }
    TTH_OUTPUT("<table border=\"0\"><tr><td>");
  }
  TTH_PUSH_CLOSING; 
  TTH_CCPY(closing,"\n</td></tr></table><!--vbox-->");
  TTH_CCAT(closing,scratchstring);
  if(!horizmode || horizmode==3){ /* Pass on vert mode to next box if any*/
    TTH_CCAT(tth_texclose[tth_push_depth-1],"\\tthvertbox");
  }
  horizmode=1;
}
\\hbox {TTH_SWAP("\\tth_hbox");}
\\tth_hbox   {
  if(horizmode){
    TTH_CCAT(closing,"<!--hbox-->");
  }else{
    TTH_OUTPUT("<table border=\"0\"><tr><td>");
    TTH_CCAT(closing,"</td></tr></table><!--hboxt-->");
  }
}
\\hbox{SP}+to {
  yy_push_state(hbox);
  GET_DIMEN;
}
\\line  TTH_SCAN_STRING("\\par\\hbox to\\hsize ");

<hbox>(\{|\\bgroup){WSP}*(\\hss|\\hfill)? {
  if(strstr(yytext,"\\h")){
    strcpy(boxalign," align=\"right\"");
  }
  TTH_PUSH_CLOSING; 
  TTH_CCPY(closing,"</td></tr></table><!--hbox-->\n");
  if(!horizmode){
    TTH_CCAT(closing,"<br clear=\"all\" />");
  }
  /*Special post-table state does not trigger broken table code */ 
  TTH_CCAT(tth_texclose[tth_push_depth-1],"\\tthhorizbox");
  if(horizmode&&(horizmode!=2)){TTH_OUTPUT("<br />");} 
  /* avoid broken table alignment*/ 
  if(*scratchstring == '%'){
    sprintf(scratchstring,
	    "<table align =\"left\" border=\"%d\" width=\"%d%s\"><tr><td%s>\n",
	    boxborder,thesize,"%",boxalign);
    TTH_OUTPUT(scratchstring);
  }else{
    sprintf(scratchstring,
	    "<table align=\"left\" border=\"%d\"><tr><td width=\"%d\"%s>\n",
	    boxborder,thesize/SCALEDPERPIXEL,boxalign);
    TTH_OUTPUT(scratchstring);
  }
  horizmode=1; 
  *boxalign=0;boxborder=0;
  yy_pop_state();
}
\\tthhorizbox  horizmode=2; /* fprintf(stderr,"Set Horizmode=2.\n"); */
\\tthvertbox   horizmode=3;

<hbox,vbox>{WSC} {
  fprintf(stderr,
	  "**** Error: Apparently unembraced h/vbox:%s, near line %d\n",
	  yytext,tth_num_lines);
  yyless(0);
  *boxalign=0;
  yy_pop_state();
}
<hbox,vbox>\\[a-zA-Z@]+   { /* expand a possible macro */
  TTH_DO_MACRO else{
  yyless(0);
  *boxalign=0;
  yy_pop_state();
  horizmode=1;
  }
}
\\hss |
\\hfill? {
  if(strstr(closing,"</td></tr></table>")){ 
    TTH_OUTPUT("</td><td align=\"right\">"); /* align=right a compromise. */
  }
  else{if(tth_debug&1024)fprintf(stderr,
	       "Apparent hfill/hss outside hbox. Closing=%s\n",closing);}
}
\\fbox |
((\\sbox|\\savebox)\{[^\}]*\}|\\framebox|\\makebox)(\[[^\]]*\]){0,2} {
  TTH_INC_MULTI;
  if(*(yytext+1)=='f')boxborder=1;
  if(strcspn(yytext,"[") == strlen(yytext)){
    *scrstring=0;*scratchstring=0;
  }else{
    TTH_CCPY(scratchstring,yytext+strcspn(yytext,"[")+1);
    if((chscratch=strstr(scratchstring,"["))!=NULL){
      strcpy(scrstring,chscratch+1);}else{*scrstring=0;}
    *(scratchstring+strcspn(scratchstring,"]"))=0;
  } /* Now we have the width and optional alignment. */
  switch(*scrstring){
  case 'l': strcpy(boxalign," align=\"left\"");break;
  case 'r': strcpy(boxalign," align=\"right\"");break;
  default : strcpy(boxalign," align=\"center\"");
  }
  chscratch=scrstring;
  if(*(yytext+1) =='s'){ /* Setbox case, prefix definitions.*/
    TTH_CCPY(scrstring,"\\setbox");
    TTH_CCAT(scrstring,yytext+strcspn(yytext,"{"));
    chscratch=(scrstring+strcspn(scrstring,"}")+1);
  }
  if(*scratchstring)sprintf(chscratch,"\\hbox to %s",scratchstring);
  else if(boxborder)strcpy(chscratch,"\\hbox to 0pt");/*really undefined*/
  else strcpy(chscratch,"\\hbox");

  TTH_SCAN_STRING(scrstring);
}

\\setbox[0-9]+ {
  sscanf(yytext+7,"%d",&js2);
  js2++;
  roman(js2,scratchstring);
  sprintf(scrstring,"\\setbox\\tthbox%s",scratchstring);
  TTH_SCAN_STRING(scrstring);
}

\\setbox      {
  yy_push_state(getbox); /* Get the box definition, then define */
  yy_push_state(getdef); /* Get the next cs and leave in defchar.*/
  *argchar=0; /* ensure null if no box found */
}


<getbox>(\\(h|v)?box|\\vtop)({SP}+(to|spread))? {
  TTH_CCPY(argchar,yytext);
  TTH_CCAT(argchar," ");
  if(strstr(yytext," ")){
    yy_push_state(lookforunit);yy_push_state(lookfornum);
    /* GET_DIMEN, but without resetting argchar.*/
  }
  if(tth_debug&4)fprintf(stderr,"Setting box as:%s\n",yytext);
}
<getbox>{NL} TTH_INC_LINE;
<getbox>{TSP}
<getbox>{ANY} {
  yyless(0);
  yy_pop_state();
  sprintf(dupstore,"{%s}{%s}",defchar,argchar);
  *defchar=0;*argchar=0;
  TTH_SCAN_STRING(dupstore);
  *dupstore=0;
  TTH_TEX_FN("\\edef#1{#2{#3}}#tthdrop3",3);
}

\\openup		|
 /*\\vbox{SP}+to	|*/
\\kern		        |
\\lower		        |
\\raise		        GET_DIMEN
\\rule   TTH_TEX_FN_OPT("#tthdrop3",3,"");

  /* Looking constructs */
<tokenarg>\{		{TTH_PUSH_CLOSING;TTH_CCPY(closing,argchar);
			argchar[0]=0;yy_pop_state();}
<tokenarg>{WSC}	|
<tokenarg,getnumargs>\\[a-zA-Z]+ {
      strcpy(dupstore,"{");strcat(dupstore,yytext);strcat(dupstore,"}");
      TTH_SCAN_STRING(dupstore);
      *dupstore=0;
      }
<dupsquare>\[            |
<escgroup,uncommentgroup>\{             |
<dupgroup>[^%\}\{]*\{    { 
  /* Count braces, save text in dupstore */
  TTH_INC_MULTI;
  TTH_CHECK_LENGTH;
   if(tth_debug&16) 
     fprintf(stderr,"Open brace appending - %s - to - %s -\n",yytext,dupstore);
   bracecount++;strcat(dupstore,yytext);
    }
<xpnd>\\number{SP}*     yy_push_state(number);jscratch=0;
<xpnd,hendline>\\tt[hm]dump{SP}*\{  yy_push_state(matchbrace);
 /* Prevent an expanding state from expanding:
    \hsize, natbib cites in footnotes*/
<xpnd>\\cite(t|p|author)  |
<xpnd>\\hsize {
  if(tth_debug&4)fprintf(stderr,"We don't expand:%s \n",yytext);
  strcat(defstore,yytext);strcpy(xpndstring," ");
}
<xpnd>\\[a-zA-Z@]+   {
  if(tth_debug&4)fprintf(stderr,"Attempt to expand:%s ",yytext);
  TTH_DO_MACRO
  else {
    if(tth_debug&4)fprintf(stderr,"failed");
    strcat(defstore,yytext);
    strcpy(xpndstring," ");
  }
  if(tth_debug&4)fprintf(stderr,"\n");
}
<xpnd>\\tth_[a-zA-Z@]+ { /* tth pseudo commands are unexpandable. */
    strcat(defstore,yytext);
    /* strcpy(xpndstring," "); And no termination is needed. */
}
<xpnd>\\noexpand\\[a-zA-Z]+ {
  strcat(defstore,yytext+9);    strcpy(xpndstring," "); 
}
<xpnd,getbox,macarg,lookfornum,notags>\\tthdimen[ ]?\\[a-zA-Z]+ 
 
<xpnd>#tthdrop[0-9] {
  strcat(defstore,yytext);
  yy_pop_state();
  if(nkeys < NFNMAX) {
    lkeys[nkeys]=localdef;
    mkdef(defchar,keys,defstore,defs,&narg,nargs,&nkeys);
    if(tth_debug&12){
      i=indexkey(defchar,keys,&nkeys);
      fprintf(stderr,"Defined Key %s index %d nargs %d Def %s\n",
	      defchar,i,nargs[i],defs[i]);
    }
  }
  else fprintf(stderr,"Too many functions to define %s",defchar);
  *defstore=0;*defchar=0; /* Clean up */
}
  /* If the next thing is a brace don't put the xpndstring (possible space)
     If it is not, then output the space denoting the end of previous macro*/
<xpnd>\{     strcat(defstore,yytext);*xpndstring=0;
<xpnd>{ANY}  {
    if(strcspn(yytext,"\n")==0) TTH_INC_LINE;
  strcat(defstore,xpndstring);strcat(defstore,yytext);*xpndstring=0;
}
<define,letdef>\\\\  strcat(defstore,yytext); /* Ensure \\ doesn't escape. */
<define,letdef>\\\{  strcat(defstore,yytext); /* Don't count escaped { */
<define,letdef>\{    {
   if(tth_debug&16) fprintf(stderr,"Open brace in [e]def, count=%d\n",
			    bracecount);
   bracecount++;strcat(defstore,yytext);
    }
<define,letdef>\\\}  strcat(defstore,yytext);
<define>\} {
  if(!bracecount){
    if(tth_debug&16) fprintf(stderr,"Close brace ending [e]def,count=%d\n",
			     bracecount);
    yy_pop_state();
    strcat(defstore,"#tthdrop");
    sprintf((defstore+strlen(defstore)),"%d",abs(narg));
    if(edeftype){
      if(tth_debug&4) fprintf(stderr,"Expanding definition:%s\n",defstore);
      edeftype=0;
      yy_push_state(xpnd);
      TTH_SCAN_STRING(defstore);
    }else{
      if(nkeys < NFNMAX) {
	lkeys[nkeys]=localdef;
	mkdef(defchar,keys,defstore,defs,&narg,nargs,&nkeys);
	if(tth_debug&4){
	  i=indexkey(defchar,keys,&nkeys);
	  fprintf(stderr,"Defined Key %s index %d nargs %d Def %s\n",
		  defchar,i,nargs[i],defs[i]);
	}
      }
      else fprintf(stderr,"Too many functions to define %s",defchar);
      *defchar=0;
    }
    *defstore=0;
  } else {
    if(tth_debug&16) fprintf(stderr,"Close brace in [e]def, count=%d\n",
			     bracecount);
    strcat(defstore,yytext);bracecount--;
  }
 }
<define,letdef>{NL}      TTH_INC_LINE;TTH_CHECK_LENGTH;strcat(defstore,yytext);
<define,letdef>[^\{\}]       strcat(defstore,yytext);

<optdetect>{WSP}   TTH_INC_MULTI;  /*Necessary for roots to work etc.*/
<optdetect>\[    {
  yyless(0);yy_pop_state();
  yy_push_state(macarg);yy_push_state(embracetok);yy_push_state(optag);
}
<optdetect>{ANY}  {
  yyless(0);yy_pop_state();
  sprintf(scratchstring,"#%d",jarg);
  if(margmax < NARMAX) {
    jscratch=0;
    {
      strcpy(scrstring,chopt); /* changed Aug 15 */
      mkdef(scratchstring,margkeys,scrstring,margs,&jscratch,margn,&margmax);
      if(tth_debug&8){
	i=indexkey(scratchstring,margkeys,&margmax);
	fprintf(stderr,"Used Default argument %s index %d Def:%s\n",
		scratchstring,i,margs[i]);
      }
    }/* optargs should always be defined. */
  } else fprintf(stderr,"**** Error: Too many Macro Args to define %s Line %d\n",argchar,tth_num_lines);
  if( jargmax < 0){ /* Don't understand why */
    jarg++;
  }else if(jarg == jargmax) {
    jarg=1;
    TTH_SCAN_STRING(chdef);
    yy_push_state(psub);
    if(tth_debug&8) fprintf(stderr,
		   "Using definition %s in optdetect\n",chdef);
    bracecount=0;
  } else {
    bracecount=-1;
    yy_push_state(macarg);yy_push_state(embracetok);
    jarg++;
  }
}
<macarg>\\verb\} { /* Don't add space after verb */
  strcat(dupstore,yytext);
  *(dupstore+strlen(dupstore)-1)=0;
  unput('}');
}
<optag>\\[a-zA-Z]+(\]|%) |
<macarg>\\[a-zA-Z]+(\}|%) { 
  strcat(dupstore,yytext);
  strcpy(dupstore+strlen(dupstore)-1," ");
  if(tth_debug&8) fprintf(stderr,"Macarg added space in:%s\n",yytext);
  unput(*(yytext+strlen(yytext)-1));
 }
<optag>\[ |
<macarg>\{    bracecount++;strcat(dupstore,yytext);
<optag>\] |
<macarg>\}   {
	if(bracecount == 0){
	  sprintf(argchar,"#%d",jarg);
	  if(margmax < NARMAX) {
	    jscratch=0;
	    mkdef(argchar,margkeys,dupstore+1,margs,&jscratch,margn,&margmax);
	    if(tth_debug&8){
	      i=indexkey(argchar,margkeys,&margmax);
	      fprintf(stderr,"Argument %s index %d Def:%s:\n",
		      argchar,i,margs[i]);
	    }
	  } else fprintf(stderr,"**** Error: Too many Macro Args to define %s Line %d\n",argchar,tth_num_lines);
	  *argchar=0;*dupstore=0;
	  if(jarg==1 && lopt){
	    if(tth_debug&8)fprintf(stderr,"Ended optional argument\n");
	    yy_pop_state();yy_pop_state();
	  }
	  if( jargmax < 0){
	    yy_pop_state();
	    jarg++;
	  }else if(jarg == jargmax) {
	    jarg=1;
	    yy_pop_state();
	    TTH_SCAN_STRING(chdef);
	    yy_push_state(psub);
	    if(tth_debug&8) fprintf(stderr,
		    "Using definition %s in macarg\n",chdef);
	  } else {
	    bracecount=-1;
	    yy_push_state(embracetok);
	    jarg++;
	  }
	} else {
	  strcat(dupstore,yytext);bracecount--;
	}
        }
<dupsquare>\]           |
<escgroup,uncommentgroup>\}            |
<dupgroup>[^%\}\{]*\}	{
  /* Count down braces. Save, or complete.
    storetype=
    0 Duplicate and rescan with argchar = closing of first.
    1 copy to superscript. 2 copy to subscript.
    3 Duplicate but with argchar inserted in middle and hence scanned.
    4 Rescan just one copy prefixed by argchar.
    5 Rescan one copy with argchar postfixed.
    6 Rescan two copies with argchar prefixed to first.
    Else just leave in dupstore. (Caller must clean up).
  */
  TTH_INC_MULTI;
  if(!bracecount){
    strcat(dupstore,yytext);
    if(tth_debug&16)fprintf(stderr,
	  "Ending dupgroup, dupstore= %s, storetype=%d\n",dupstore,storetype);
    if(storetype == 0){
      strcpy(dupstore2,dupstore);strcat(dupstore2,dupstore);
      TTH_PUSH_CLOSING;TTH_CCPY(closing,argchar);
      TTH_SCAN_STRING(dupstore2);
      *dupstore2=0;
      *dupstore=0;
    } else if (storetype == 1) {     /* Take the } off the end.*/	
      *(dupstore+strlen(dupstore)-1)=0;
      strcpy(supstore,dupstore);
      *dupstore=0;
    } else if (storetype == 2) {
      *(dupstore+strlen(dupstore)-1)=0;
      strcpy(substore,dupstore);
      *dupstore=0;
    } else if (storetype == 3) {
      strcpy(dupstore2,dupstore);strcat(dupstore2,argchar);
      strcat(dupstore2,dupstore);
      *argchar=0;
      if(tth_debug&16)fprintf(stderr,"Rescanning: %s\n",dupstore2);
      TTH_SCAN_STRING(dupstore2);*dupstore2=0;
      *dupstore=0;
    } else if (storetype == 4) {
      strcpy(dupstore2,argchar); *argchar=0;
      strcat(dupstore2,dupstore); *dupstore=0;
      if(tth_debug&16)fprintf(stderr,"Rescanning: %s\n",dupstore2);
      TTH_SCAN_STRING(dupstore2);*dupstore2=0;
    } else if (storetype == 5) {
      strcat(dupstore,argchar); *argchar=0;
      if(tth_debug&16)fprintf(stderr,"Rescanning: %s\n",dupstore);
      TTH_SCAN_STRING(dupstore);*dupstore=0;
    } else if (storetype == 6) {
      strcpy(dupstore2,argchar); *argchar=0;
      strcat(dupstore2,dupstore);strcat(dupstore2,dupstore); *dupstore=0;
      if(tth_debug&16)fprintf(stderr,"Rescanning: %s\n",dupstore2);
      TTH_SCAN_STRING(dupstore2);*dupstore2=0;
    }
    storetype=0;
    yy_pop_state();
  } else {
    if(tth_debug&16)
      fprintf(stderr,"appending - %s - to - %s -\n",yytext,dupstore);
    strcat(dupstore,yytext);bracecount--;}
}
     /* getsubp removed to equation file */
<verbatim,notags>\\end\{verbatim\} {
  if(verbinput){ TTH_OUTPUT(yytext);} 
  else{
    if(tth_titlestate) tth_titlestate=99;
    TTH_TEXCLOSE else{TTH_CLOSEGROUP;TTH_POP_CLOSING;yy_pop_state();}
  }
}
<verbatim,notags>\\tth_endverbinput {
  verbinput=0;
  TTH_TEXCLOSE else{TTH_CLOSEGROUP;TTH_POP_CLOSING;yy_pop_state();}
}
<rawgroup>\\end\{(raw)?html\}  |
<rawgroup>\}  {  
  TTH_TEXCLOSE else{TTH_CLOSEGROUP;TTH_POP_CLOSING;yy_pop_state();}
}
<rawgroup>\{ {
  TTH_OUTPUT(yytext);TTH_PUSH_CLOSING;
  TTH_CCPY(closing,"}");
  yy_push_state(rawgroup);}

 /* Dimensions and Numbers etc. */

<lookforunit>(true)?{WSP}*(cm|in|pc|pt|mm|bp|dd|cc|sp|em|ex|fil) {
  TTH_INC_MULTI;
  yy_pop_state();
  TTH_CCAT(argchar,yytext);
  strcpy(scratchstring,yytext+strlen(yytext)-2); /*unit is last 2 letters */
  if(!tthglue) {
    thesize = scaledpoints(anumber,scratchstring);
  }
  if(tth_debug&1024) fprintf(stderr,"Dimension %d sp, from specified %f %s\n",
			     thesize,anumber,scratchstring);
  *argchar=0; /* Don't think this is used. */
}
<lookforunit>\\tth_hsize { /* The dimension is in \hsizes */
  thesize=100*anumber;
  strcpy(scratchstring,"%");
  yy_pop_state();
  if(tth_debug&1024) fprintf(stderr,"Dimension tth_hsize: %d\n",thesize);
  *argchar=0; /* this is used. */
}
\\tth_hsize       GET_DIMEN; /* Do nothing outside for now */
<lookforunit>\\[a-zA-Z@]+   { /* expand a possible macro */
  TTH_DO_MACRO else { /* pop state if uninterpretable */
    if(tth_debug&1024) fprintf(stderr,"Unknown dimension %s\n",yytext);
    thesize=0;
    yyless(0);
    yy_pop_state();}
}
<lookforunit>\\tthdimen[ ]?\\[a-zA-Z]+  /* Rip this out of the way */
<lookforunit>{NUM} {/* We find a number. Scale instead. Shouldn't be in TeX*/
  if(! sscanf(yytext,"%f",&bnumber) ){
    fprintf(stderr,"**** Uninterpreted scaled dimension value:%s\n",yytext);
    bnumber=1.;
  }
  anumber=anumber*bnumber;
}

<lookfornum,lookforunit>{NL} TTH_INC_LINE;
<lookfornum,lookforunit>{TSP}*     /* Ignore spaces */
<lookfornum>=          /* and equal signs */
<lookfornum>{NUM}  { /* If we find a number store it.*/
  TTH_CCAT(argchar,yytext);
  if(! sscanf(argchar,"%f",&anumber) ){
    if(tth_debug&4)fprintf(stderr,"Uninterpreted dimension value:%s\n",argchar);
    anumber = 0;
  }
/*    if(tth_debug&1024)fprintf(stderr,"Got number: %f\n",anumber); */
  yy_pop_state();
}
<lookfornum>[-+]*        strcat(argchar,yytext);
     /* If this is an unknown token, pop extra lookforunit state too.*/
<lookfornum>\\[a-zA-Z]+ {
  TTH_DO_MACRO
  else{ 
    /* was TTH_CCAT(argchar,yytext); then became yyless(0) now
     presume if argchar !=0 that we need to collect it e.g. in setbox.*/
    if(strlen(argchar)){TTH_CCAT(argchar,yytext);}else  yyless(0);
    if(tth_debug&1024)fprintf(stderr,"Failed lookfornum:%s\n",yytext);
    yy_pop_state();yy_pop_state();
  }
}
<insertnum>({NUM}|\\[a-zA-Z]+)	{
  fprintf(tth_fdout,"%s%s",yytext,argchar);yy_pop_state();}
<lookforfile>{NL} TTH_INC_LINE;
<lookforfile>{TSP}*
<lookforfile>{WSC}+	{TTH_CCPY(argchar,yytext);yy_pop_state();
			if(tth_verb) fprintf(stderr,"File:%s",yytext);}
<glue>{WSP}*(plus|minus)   TTH_INC_MULTI;tthglue=1;GET_DIMEN  
 /* nested glue not allowed */
<glue>{ANY}     tthglue=0;yyless(0);yy_pop_state();

<embracetok>\\begingroup |
<embracetok>\\bgroup |
<embracetok>\{   { /* already embraced */
  strcat(dupstore,"{");
  TTH_SCAN_STRING(dupstore);
  *dupstore=0;
  yy_pop_state();
}

<embracetok>{NL} TTH_INC_LINE;
<embracetok>{TSP}
<embracetok>\\.   |
<embracetok>{WSC} |
<embracetok>\\[a-zA-Z@]+ { /* Enclose a bare token for using as argument.*/
      strcat(dupstore,"{");strcat(dupstore,yytext);strcat(dupstore,"}");
      TTH_SCAN_STRING(dupstore);
      *dupstore=0;
      yy_pop_state();
      }
<swaparg>\\bgroup |
<swaparg>\{  {
  sprintf(scratchstring,"{%s",swapchar);
  TTH_SCAN_STRING(scratchstring);*swapchar=0;yy_pop_state();
}
<swaparg>.  {
  fprintf(stderr,"**** Error: swaparg fault:%s:%s:\n",swapchar,yytext);
  yy_pop_state();}

  /************* count lines ****************/
<discardgroup,falsetext,innerfalse,ortext,matchbrace,getsubp>{NL} TTH_INC_LINE;
<verb,verbatim,notags,rawgroup>{NL}  {
  TTH_INC_LINE;
  fprintf(tth_fdout,"%s",yytext);
  strcpy(scratchstring,"\n");
  if(tth_debug&8192)fprintf(stderr,"Verbatim \\n:%d, \\n code:%d Length:%d\n",(int) *yytext,(int) *scratchstring, (int) strlen(scratchstring));
}
<exptokarg>{WSP}*\{(.\})?  { /* Final route for all cases once expanded. */
  TTH_INC_MULTI;
  if(strlen(expchar)){
    yyless(strcspn(yytext,"{"));
    TTH_PUSH_CLOSING;TTH_CCPY(closing,expchar);
    *expchar=0;yy_pop_state();
    if(tth_debug&8) {
      fprintf(stderr,"Exptok Group {, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s\n",eqdepth,eqclose,tth_flev,levdelim[eqclose]);
    }
    mkkey(eqstr,eqstrs,&eqdepth);
    tth_flev=tth_flev-99;
    eqclose++;
    tophgt[eqclose]=0;
    levhgt[eqclose]=1;
    *eqstr=0;
    active[eqclose]=1;
  }else{ 
    strcat(exptex,yytext+strcspn(yytext,"{"));
    TTH_SCAN_STRING(exptex);
    if(tth_debug&8){
      fprintf(stderr,"Expansion completed. Rescanning %s\n",exptex);
    }
    *exptex=0;
    yy_pop_state();
  }
}

<exptokarg>({WSC}|\\%)	{
  if(tth_debug&8) fprintf(stderr,
		 "Nothing to expand in exptok[arg]. Rescan:{%s}\n",yytext);
  sprintf(scratchstring,"{%s}",yytext+strlen(yytext)-1);
  TTH_SCAN_STRING(scratchstring);
}
<exptokarg>\\.[a-zA-Z@]* { /* fix for _\| etc */
  if(tth_debug&8)fprintf(stderr,"Exptokarg, expanding:%s\n",yytext);
  TTH_DO_MACRO
  else {
    strcpy(dupstore,"{");strcat(dupstore,yytext);strcat(dupstore,"}");
    TTH_SCAN_STRING(dupstore);
    *dupstore=0;
  }
}

<tokexp>({WSC}|\\%) {
  yyless(0);yy_pop_state();
  if(strlen(exptex)){TTH_SCAN_STRING(exptex); *exptex=0;}
}
<tokexp>\\.[a-zA-Z@]* { /* fix for _\| etc OUT for tokexp. */
  if(tth_debug&8)fprintf(stderr,"Tokexp, expanding:%s\n",yytext);
  TTH_DO_MACRO
  else {
    yy_pop_state();
    yyless(0);
    *dupstore=0;
    if(strlen(exptex)){TTH_SCAN_STRING(exptex); *exptex=0;}
  }
}

<disptab>\$\$	{
  if(*halstring){ /* In a display table has to be a null inline*/
  }else{
    TTH_TEXCLOSE else{
    yy_pop_state();
    /* moved into closing. fprintf(tth_fdout,"</dl>");*/
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
    if(tth_debug&33)fprintf(stderr,"Display Table end.\n");
    }
  }
}

<textbox>\$                  |
<textbox>\begin\{math\}      |
<textbox>\\\(                {
  if(tth_debug&2) 
    fprintf(stderr,"Starting textbox equation, line %d\n",tth_num_lines);
  /*  TTH_OUTPUT(TTH_TEXTBOX2);*/
  if(displaystyle)displaystyle++; 
  mkkey(eqstr,eqstrs,&eqdepth);
  TTH_PUSH_CLOSING;
  yy_push_state(equation);
  TTH_SCAN_STRING("{");
} 
 /* $ Will be superceded by equation grab for non-null eqs */
<notags>\\tth_notageq  |
\$                | 
\\begin\{math\}   |
\\\(     { 
  if(displaystyle) fprintf(stderr,"Starting displaystyle incorrect.\n");
  displaystyle=0;
  tophgt[eqclose]=0;levhgt[eqclose]=1;
  *eqstr=0;
  eqclose=0;
  mkkey(eqstr,eqstrs,&eqdepth);
  if((!tth_inlinefrac)^(strstr(TTH_NAME,"M")!=NULL)) tth_flev=tth_flev-89;
  TTH_PUSH_CLOSING;
  if(!strstr(tth_font_open[tth_push_depth],TTH_ITALO)){
    TTH_CCAT(tth_font_open[tth_push_depth],tth_font_open[0]);
    TTH_CCAT(tth_font_close[tth_push_depth],tth_font_close[0]);
  }
  yy_push_state(equation);
  TTH_SCAN_STRING("{");
 }

\\bmath           

<INITIAL,halign,textsc,uppercase,pargroup,Litemize,Lenumerate,Ldescription>\$[^$]+\$  {
  if(strcspn(yytext,"_^")==1){
    if(tth_debug&3) fprintf(stderr,"Special In line Eq:%s\n",yytext);
    /*
      yyless(1);
        unput(' '); This broke with pushback errors
      Handle subdefer appropriately for specials.
      Hence we use the following more cumbersome but safer approach.
      Really I ought to find a better way to make sure that we can
      accommodate constructs like $^1_2$ using msupsub in mathml.
      The problem seems to be the implied { which never has subscripts.
    */
    *scrstring=0;
    if(strstr(TTH_NAME,"M")){ /* MathML */    strcat(scrstring," ");}
    strcat(scrstring,yytext+1);
    TTH_SCAN_STRING(scrstring);
    *scrstring=0;
  }else{
    if(tth_debug&3) fprintf(stderr,"In line Eq:%s\n",yytext);
    yyless(1);
  }
  TTH_SCAN_STRING("$"); /* Force into other channel above.*/  
 }

<INITIAL,pargroup>\$\$[^$]*\\halign	| 
<INITIAL,pargroup>\$\$[^$]*\\halign([^$]+\$)+\$	{ 
  if(tth_debug&33)fprintf(stderr,"Display Table:\n%s\n",yytext);
  fprintf(tth_fdout,"<dl><dd>");
  yyless(2);
  yy_push_state(disptab);
  TTH_PUSH_CLOSING;  
  TTH_CCPY(closing,"</dd></dl>");
}
 /* Allowing the first half of a display to be recognized as equation is
    problematic. Instead go to halsearch state. 
    Does not permit non-output commands before the halign. TeX does.*/
<INITIAL,Litemize,Lenumerate,Ldescription,pargroup>\$\$ {
  yy_push_state(halsearch);
}

<halsearch>{WSP}  TTH_INC_MULTI;
<halsearch>.*\\halign {
  if(tth_debug&33)fprintf(stderr,"Display Table:\n%s\n",yytext);
  yyless(0);
  yy_pop_state();
  yy_push_state(disptab);
  fprintf(tth_fdout,"<dl><dd>");
  TTH_PUSH_CLOSING;  
  TTH_CCPY(closing,"</dd></dl>");
}
<halsearch>[^ ]  {
  yyless(0);
  yy_pop_state();
  TTH_SCAN_STRING("\\tth_start_equation");
}

 /* Don't recognize display equations except in certain allowed states. */
\\tth_start_equation  |
<INITIAL,Litemize,Lenumerate,Ldescription,pargroup>\$\$([^$]+\$)+\$	{
  {
    if(tth_debug&3) fprintf(stderr,"Display Eq:\n%s\n",yytext);
    if(strstr(yytext,"\\tth_start_equation")==NULL) yyless(2);
    if(strcspn(yytext,"_^")==2){
      if(strstr(TTH_NAME,"M")){ /* MathML */      unput(' ');}
    }
    TTH_SCAN_STRING("{");
    /*
    if(tth_htmlstyle&2){
      TTH_OUTPUT(closing); strcpy(closing,"</div>");
      TTH_OUTPUT("\n<div class=\"p\">\n");}*/
    horizmode=0;
    displaystyle=1;
    *eqstr=0;
    eqclose=0;
    tophgt[eqclose]=0;
    mkkey(eqstr,eqstrs,&eqdepth);
    TTH_PUSH_CLOSING;
    if(!strstr(tth_font_open[tth_push_depth],TTH_ITALO)){
      TTH_CCAT(tth_font_open[tth_push_depth],tth_font_open[0]);
      TTH_CCAT(tth_font_close[tth_push_depth],tth_font_close[0]);
    }
    yy_push_state(equation);
  }
 }

  /* Translate single characters. */
\\char\`(\\)?.  TTH_OUTPUTH(yytext+strlen(yytext)-1);

\\char{WSP}*[0-9]{2,3}   {
  TTH_INC_MULTI;
  sscanf(yytext+5,"%d",&jscratch);
  sprintf(scratchstring,"%c",jscratch);
  TTH_OUTPUTH(scratchstring);
  yy_push_state(removespace);
}
  /* Latin Characters and other non-math but output correctly in math.*/
	   
\\[\'\"^\`~]{SP}+[A-z] { /* Circumvent spaces after accents.*/
  strcpy(scratchstring,yytext);
  unput(*(scratchstring+strlen(scratchstring)-1));
  unput(*(scratchstring+1));unput(*scratchstring);
}

\~       | 
\\nobreakspace{SP}* | 
\\[ ,:>]{SP}*			TTH_OUTPUTH("&nbsp;");
\\\n			TTH_OUTPUTH("&nbsp;");TTH_INC_LINE;
\\;{SP}*			TTH_OUTPUTH("&nbsp;&nbsp;");
\\quad          TTH_OUTPUTH("&nbsp;&nbsp;&nbsp;");
\\qquad          TTH_OUTPUTH("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
\\AE		TTH_OUTPUTH("&#198;");
\\\'A		TTH_OUTPUTH("&#193;");
\\\^A		TTH_OUTPUTH("&#194;");
\\\`A		TTH_OUTPUTH("&#192;");
\\r\{A\} |
\\AA		TTH_OUTPUTH("&#197;");
\\\~A           TTH_OUTPUTH("&#195;");
\"A |		
\\\"A	        TTH_OUTPUTH("&#196;");
 /*  \\c{SP}?C    | */
\\noexpand\\c{SP}?C       	TTH_OUTPUTH("&#199;");
\\\'E		TTH_OUTPUTH("&#201;");
\\\^E		TTH_OUTPUTH("&#202;");
\\\`E		TTH_OUTPUTH("&#200;");
\"E |
\\\"E		TTH_OUTPUTH("&#203;");
\\\`I		TTH_OUTPUTH("&#204;");
\\\'I		TTH_OUTPUTH("&#205;");
\\\^I		TTH_OUTPUTH("&#206;");
\"I |
\\\"I		TTH_OUTPUTH("&#207;");
\\\~N		TTH_OUTPUTH("&#209;");
\\\`O		TTH_OUTPUTH("&#210;");
\\\'O		TTH_OUTPUTH("&#211;");
\\\^O		TTH_OUTPUTH("&#212;");
\\\O		TTH_OUTPUTH("&#216;");
\\\~O		TTH_OUTPUTH("&#213;");
\"O |
\\\"O		TTH_OUTPUTH("&#214;");
\\P		TTH_OUTPUTH("&#182;");
\\S		TTH_OUTPUTH("&#167;");
\\\'U		TTH_OUTPUTH("&#218;");
\\\^U		TTH_OUTPUTH("&#219;");
\\\`U		TTH_OUTPUTH("&#217;");
\"U |
\\\"U		TTH_OUTPUTH("&#220;");
\\\'Y		TTH_OUTPUTH("&#221;");
<verbatim,notags>&  TTH_OUTPUTH("&amp;");
\\\& 		TTH_OUTPUTH("&amp;");
\\ae		TTH_OUTPUTH("&#230;");
\\\`a		TTH_OUTPUTH("&#224;");
\\\'a		TTH_OUTPUTH("&#225;");
\\\^a		TTH_OUTPUTH("&#226;");
\\\~a		TTH_OUTPUTH("&#227;");
\"a |
\\\"a		TTH_OUTPUTH("&#228;");
\\r\{a\} |
\\aa{SP}*            TTH_OUTPUTH("&#229;");
 /*  \\c{SP}?c              | */
\\noexpand\\c{SP}?c    TTH_OUTPUTH("&#231;");
\\\^		TTH_OUTPUTH("^");
\\copyright	TTH_OUTPUTH("&#169;");
\\\'e		TTH_OUTPUTH("&#233;");
\\\^e		TTH_OUTPUTH("&#234;");
\\\`e		TTH_OUTPUTH("&#232;");
\\v{SP}?o		TTH_OUTPUTH("&#240;");
\"e |
\\\"e		TTH_OUTPUTH("&#235;");
<verbatim,notags>\> |
\>	TTH_OUTPUTH("&#62;");
<verbatim,notags>\< |
\<	TTH_OUTPUTH("&lt;");
<verbatim>[ ]   TTH_OUTPUTH("&nbsp;")
\\\`i	|
\\\`\\i{SP}*		TTH_OUTPUTH("&#236;");
\\acute{SP}*\\i   |
\\\'i	|
\\\'\\i{SP}*		TTH_OUTPUTH("&#237;");
\\\^i	|
\\\^\\i{SP}*		TTH_OUTPUTH("&#238;");
\"i |
\\\"i	|
\\\"{SP}*\\i{SP}*		TTH_OUTPUTH("&#239;");
\\\~n		TTH_OUTPUTH("&#241;");
\\\`o		TTH_OUTPUTH("&#242;");
\\\'o		TTH_OUTPUTH("&#243;");
\\\^o		TTH_OUTPUTH("&#244;");
\\\o{SP}* 		TTH_OUTPUTH("&#248;");
\\\~o		TTH_OUTPUTH("&#245;");
\"o |
\\\"o      TTH_OUTPUTH("&#246;");
\\\=		TTH_OUTPUTH("&#175;");
\\pounds{SP}*	TTH_OUTPUTH("&#163;");
\\\~		TTH_OUTPUTH("&#126;");
\\\'u		TTH_OUTPUTH("&#250;");
\\\^u		TTH_OUTPUTH("&#251;");
\\\`u		TTH_OUTPUTH("&#249;");
\"u |
\\\"u	TTH_OUTPUTH("&#252;");
\\\'y		TTH_OUTPUTH("&#253;");
\"y |
\\\"y	TTH_OUTPUTH("&#255;");
\"s             TTH_OUTPUTH("&#223;");
\\3{SP}* |
\\ss{SP}*            TTH_DO_MACRO else{ TTH_OUTPUTH("&#223;");}
\"\`             TTH_OUTPUTH(",,");
\"\'             TTH_OUTPUTH("''");
\"<             TTH_OUTPUTH("&#171;");
\">             TTH_OUTPUTH("&#187;");
\"\|
 /* Convert TeX double quotes to single-character */
\'\'            |
\`\`             TTH_OUTPUTH("\"");
(\\grave|\\acute)\{.\}    {
  if(*(yytext+1)=='g') strcpy(scratchstring,"\\`");
  else  strcpy(scratchstring,"\\'");
  strcat(scratchstring,yytext+strlen(yytext)-3);
  TTH_SCAN_STRING(scratchstring);
}
  /* Remove unwanted braces from around accented characters. */
\\[\'\^\`\"\~]{SP}*\{((\\i{SP}*)|[a-zA-Z])\} |
 /*  \\c{SP}*\{[cC]\}   | */
\\noexpand\\c{SP}*\{[cC]\}   {
  if(tth_debug&8) fprintf(stderr,"Fixing accent:%s\n",yytext);
  *dupstore2=0;
  strncat(dupstore2,yytext,2);
  strncat(dupstore2,yytext+strcspn(yytext,"{")+1,
	 strcspn(yytext,"}")-strcspn(yytext,"{")-1);
  TTH_SCAN_STRING(dupstore2);
  *dupstore2=0;
  }
  /* Unknown diacriticals must terminate safely. 
\\noexpand\\H
\\noexpand\\b 
 Above are safely defined. Below need protection.*/
\\noexpand\\v
\\noexpand\\u
\\noexpand\\d
\\noexpand\\c

\\Box  TTH_OUTPUTH(TTH_BOXCODE);
\\hbar TTH_OUTPUTH(TTH_HBAR);

 /* Various things not being used.
 \\\c		TTH_OUTPUTH("&#184;");
 \?		TTH_OUTPUTH("&#191;");
 \!   		TTH_OUTPUTH("&#161;");
 */
\\jobname {
  TTH_SCAN_STRING(tth_latex_file);
}
 /* This needs to match all the cases of comments otherwise they will
    not allow escaping of the % in that state. Not all are TTH_OUTPUT */
<tokenarg>\\% |
<getdef,getnumargs>\\% |
\\%	  TTH_OUTPUTH("%");
<matchbrace>\\%
<macarg,optag,dupgroup,dupsquare,escgroup>\\(%|\}|\{|\\)   |
<macarg,optag,dupgroup,dupsquare,escgroup,uncommentgroup>{ANY}  {
  if(strcspn(yytext,"\n")==0) {TTH_INC_LINE;TTH_CHECK_LENGTH;}
  strcat(dupstore,yytext);
}
<define>\\%      strcat(defstore,yytext); 
<escgroup,uncommentgroup>%{NL} {
  TTH_INC_LINE;
}
\\break    |
\\newline  |
 /* \\\\\*?({SP}*\[[^\]]*\])?         | */
\\crlf		TTH_SCAN_STRING("\\par");
<psub>\\tthphantom#tthdrop1  {
  if(horizmode) horizmode=1;
  jscratch=indexkey("#1",margkeys,&margmax);
  yy_pop_state();
  if(jscratch!=-1){
    strcpy(dupstore,margs[jscratch]);
    rmdef(margkeys,margs,&margmax); 
    for(js2=0;js2<2*(strlen(dupstore));js2++)TTH_OUTPUT("&nbsp;");
  }else{
    fprintf(stderr,"***** Error. No argument in \\phantom. Line %d\n",tth_num_lines);
  }
  *dupstore=0;
 }

\\\$			TTH_OUTPUTH("$");
\\\#                    TTH_OUTPUTH("#");
\\\{                    TTH_OUTPUTH("{");
\\\}                    TTH_OUTPUTH("}");
 /* In nbsp choice above \\{SP}			TTH_OUTPUTH(" "); */
\\_                     TTH_OUTPUTH("_");
\\!
\\\/			TTH_OUTPUTH(" ");
(--)|(---)              TTH_OUTPUTH("-");
\\l?dots                 TTH_OUTPUTH("..."); /* non-math dots */
 /* Commands to ignore in equations as well as text*/
\\(v|h)center
\\(no)?indent   
\\null

 /* Some problems in equations being confused with this, unless specific. */
\\[a-zA-Z]*(penalty|badness|tolerance|demerits){SP}*=? {
  fprintf(stderr,"**** Removing inappropriate parameter command %s Line %d\n",yytext,tth_num_lines);
  yy_push_state(lookfornum);*argchar=0;
 }
\\global   /* Overridden where necessary for defs.. */

 /* TeX Commands in equations*/
<equation>\\[a-zA-Z@]+   {
  TTH_DO_MACRO
  else if( (ind=indexkey(yytext,countkeys,&ncounters)) != -1) { 
    if(tth_debug&4) fprintf(stderr,"Setting counter %d, %s. ",ind,countkeys[ind]);
    yy_push_state(counterset);
  } else {
    if(!(tth_debug&32768))
      fprintf(stderr,"**** Unknown command %s in equation, Line %d\n"
	      ,yytext,tth_num_lines);
    strcat(eqstr,yytext);
  }
 }
 /* Default equation action may no longer be needed, but not sure. 21 Mar*/
<equation>{WSC}  {
  strcat(eqstr,yytext);
 }

\\end\{document\} yy_scan_string("}\\end");
 /* Latex default (unknown) environment */
\\begin\{[a-zA-Z]*\*?\} {
  TTH_DO_MACRO
  else{
    fprintf(stderr,"**** Unknown or ignored environment: %s Line %d\n"
	    ,yytext,tth_num_lines);
  }
  TTH_PUSH_CLOSING;
     /*This is balanced by the \egroup just below.*/
 }
\\end\{[a-zA-Z]*\*?\}	 {
  ind=indexkey(yytext,keys,&nkeys);
  TTH_SCAN_STRING("\\egroup");
  if(ind != -1) { /* This was defined by newenvironment */
    TTH_SCAN_STRING(defs[ind]);
    yy_push_state(psub);
    if(tth_debug&8) fprintf(stderr,"Using definition %d= %s in end\n"
			 ,ind,defs[ind]);
  }
 }
\\begin{WSP}+ {
  TTH_INC_MULTI;
  if(strstr(yytext,"\n")){TTH_INC_LINE;}
  fprintf(stderr,
   "**** Warning! Bad LaTeX Style. Space after \\begin. Line %d\n",tth_num_lines);
  unput('n');unput('i');unput('g');unput('e');unput('b');unput('\\');
}
\\end{WSP}+\{ {
  TTH_INC_MULTI;
  if(strstr(yytext,"\n")){TTH_INC_LINE;}
  fprintf(stderr,
   "**** Warning! Bad LaTeX Style. Space after \\end Line %d\n",tth_num_lines);
  unput('{');unput('d');unput('n');unput('e');unput('\\');
}

<verb>.   {
  if(*yytext == *chr1){
    TTH_TEXCLOSE else{
      TTH_CLOSEGROUP;TTH_POP_CLOSING;
      yy_pop_state();
    }
  }else{
    if(*yytext == '&') {TTH_OUTPUTH("&amp;");}
    else if(*yytext == '<') {TTH_OUTPUTH("&lt;");}
    else if(*yytext == '>') {TTH_OUTPUTH("&gt;");}
    else if(*yytext == ' ') {TTH_OUTPUTH("&nbsp;");}
    else {TTH_OUTPUTH(yytext);}
  }
 }

  /* Special escape sequences in rawgroup */
<rawgroup>\\(\#|\%|\\)   TTH_OUTPUT(yytext+1);
  /* Don't set horizmode for whitespace.*/
<textbox,uppercase,textsc>[ \t]*       TTH_OUTPUT(yytext);
 /* Default action */
<textbox,uppercase,textsc,rawgroup,verbatim,notags>.   horizmode=1;TTH_OUTPUT(yytext);
  /* Normal action. Set to horizontal mode if not space*/
[ \t]*       fprintf(tth_fdout,"%s",yytext);
 /* Default action */
  .	    horizmode=1;fprintf(tth_fdout,"%s",yytext);

  /* Delete in certain states. */
<lookforunit,lookfornum>.  yyless(0);yy_pop_state();      
<htemplate,tokenarg>.

<error>.|\n {
  if(tth_ercnt==0){
    fprintf(stderr,"%s",yytext);
    tth_ercnt=0;
    fprintf(stderr,"\n");TTH_EXIT(1);
  }else if(tth_ercnt>0){  fprintf(stderr,"%s",yytext);tth_ercnt--;
  }else{tth_ercnt=0;TTH_EXIT(tth_erlev);} ;
}

\\leavevmode    horizmode=1;
\\leavehmode    {TTH_PAR_ACTION}
\\tt[hm]unknown       yy_push_state(unknown);
\\addvspace{SP}*    yy_push_state(unknown);
\\catcode fprintf(stderr,"**** DANGER: Catcode changes not honored. Expect abnormal behavior. Line %d\n",tth_num_lines);

 /* Ignore quietly */
\\spacefactor{SP}*{NUM}
\\linebreak{SP}*(\[{NUM}\])?
\\nolinebreak{SP}*(\[{NUM}\])?
\\-
\\magnification[ =]*{NUM}?
\\magstep[0-5]
\\magstephalf
 /*\\line   | */
\\ht[0-9]+
\\wd[0-9]+
\\dp[0-9]+
\\ht                |
\\wd                |
\\dp { /* Dump the argument. Might be used instead of matchbrace. */
  TTH_TEX_FN("#tthdrop1",1);
}
\\box[0-9]+               |
\\copy[0-9]+              |
\\un(h|v)(box|copy)[0-9]+ {
  sscanf(yytext+strcspn(yytext,"0123456789"),"%d", &js2);
  js2++;
  roman(js2,scratchstring);
  sprintf(scrstring,"\\tthbox%s",scratchstring);
  TTH_SCAN_STRING(scrstring);
}

\\nobreak           |
\\usebox            |
\\box               |
\\copy              |
\\un(h|v)(box|copy) |
\\protect |
\\vfill |
\\nopagenumbers   |
\\resizebox({SP}*\{[^\}]\}){2}   |
\\raisebox{BRCG}({SP}?\[[^\]]*\]){0,2}   |
\\[vm]box   |
\\relax   |
\\newblock   |
\\maketitle   |
\\ignorespaces   |
\\smash   if(horizmode)horizmode=1;
\\vphantom\{ |
\\citation\{ |
\\bibdata\{ |
\\bibstyle\{ |
\\bibliographystyle\{ |
\\select@language{SP}*\{ |
\\tt[hm]dump{SP}*\{  |
\\hyphenation\{    TTH_INC_MULTI;yy_push_state(matchbrace);

\\tth_eof  |
\\endinput |
\\end	|
<<EOF>>		{
  if(!strcmp(yytext,"\\end")) {
    tth_stack_ptr=0; 
    if(!ftntno){
      TTH_INC_LINE;
      if(tth_debug&1024 && !(tth_stack_ptr||ftntwrap)) fprintf(stderr,"\n");
       /*Terminate the diagnostic*/
    }/*  Count the last line if it is \end */
  }
  /*Function returns here*/
  if ( --tth_stack_ptr < 0){
    TTH_CLOSEGROUP;*closing=0;
    if(ftntno){
      TTH_SCAN_STRING("\\special{html:<hr /><h3>}\\tthfootnotes:\\special{html:</h3>\n}");
      ftntno=0;
      if(tth_splitfile){ /*sf*/
	strcpy(filenext,"footnote.html");/*sf*/
	TTH_SCAN_STRING("\\tthsplittail\\tthsplitinv\\tthsplittop\\tthfileupd"); /*sf*/
      }/*sf*/
      }else{
	if(tth_debug&4096)fprintf(stderr,"ftntwrap:%d,",ftntwrap);
	if(ftntwrap < nkeys){      /* Footnote wrap-up. Search keys. */
	  if(tth_debug&4096)fprintf(stderr," %s\n",keys[ftntwrap]);
	  yy_delete_buffer( YY_CURRENT_BUFFER );/*leakfix*/
	  if(strstr(keys[ftntwrap],"tthFtNt")){
	    {TTH_PAR_ACTION};
	    fprintf(tth_fdout,"<a id=\"%s\"></a>",keys[ftntwrap]+1);
	    if(tth_debug&256)fprintf(stderr,"Footnote key %d, scanning: %s\n",
				     ftntwrap,defs[ftntwrap]);
	    yy_scan_string(defs[ftntwrap]);yy_push_state(psub);
	  } else yy_scan_string("\\end");
  	  tth_stack_ptr++;
	  /*	  tth_stack_ptr=1;*/
	  ftntwrap++;
	}else{	
	  if(tth_indexfile){
	    /* We no longer remove it because we use different name.
	    sprintf(scratchstring,"%s %s.ind%s",RMCMD,tth_latex_file,RMTERM);
	    system(scratchstring);
	    */
	    tth_indexfile=NULL;
	  }
	  if(tth_splitfile)fprintf(tth_fdout,"<hr /><a href=\"index.html\">%s</a>",TTH_HEAD);/*sf*/
	  if(tth_debug&4096)fprintf(stderr,"Terminating.\n");
	  fflush(stdout);
	  yyterminate();
	}
      }
  }else{
    if(eofrmv[tth_stack_ptr] == 11){ /*Index ref in toc*/
      if(tth_splitfile)/*sf*/
	{fprintf(tth_fdout,"<a href=\"docindex.html#tth_sEcindex\">Index</a><br />");}else/*sf*/
	  {fprintf(tth_fdout,"<a href=\"#tth_sEcindex\">Index</a><br />");}
      eofrmv[tth_stack_ptr] = 0; /* Do it only once. */
    }else{
      /*horizmode=0;  for removespace caused uppercase problem*/
      if(eofrmv[tth_stack_ptr]) yy_push_state(removespace);
    }
    if(tth_debug&16) fprintf(stderr,
			     "EOF encountered: level=%d rmv=%d\n",
			     tth_stack_ptr, eofrmv[tth_stack_ptr]);
    yy_delete_buffer( YY_CURRENT_BUFFER );
    yy_switch_to_buffer(include_stack[tth_stack_ptr] );
  }
}
<equation>\\[a-zA-Z0-9]*{SP}*= { /* Don't suppose glue command in equations */
  TTH_CCPY(argchar,yytext);
  strcpy(argchar+strlen(argchar)-1,"\n=");
  TTH_SCAN_STRING(argchar);
  *argchar=0;
}

\\footline{SP}*=?   yy_push_state(unknown);

  /* Format looks like counter or dimension setting */
\\[a-zA-Z0-9]*{SP}*= {
  TTH_CCPY(argchar,yytext);
  argchar[strcspn(yytext," =")]=0;
  if( (ind=indexkey(argchar,countkeys,&ncounters)) != -1 ){
    if(tth_debug&4) fprintf(stderr,"Setting counter %d, %s\n",ind,countkeys[ind]);
    yy_push_state(counterset);
  } else if((ind=indexkey(argchar,keys,&nkeys)) != -1 ){ /*defined command*/
    yyless(strcspn(yytext," ="));
    TTH_SCAN_STRING(argchar);
    *argchar=0;
  } else {
    if((!strstr(unknownstring,yytext)||tth_debug)&&!(tth_debug&32768)){
      fprintf(stderr,"**** Unknown parameter/dimension/glue command %s Line %d\n",yytext,tth_num_lines);
      if(!strstr(unknownstring,yytext) &&
	 strlen(unknownstring)+strlen(yytext) < TTH_UNKS_LEN)
	strcat(unknownstring,yytext);
    }
   yy_push_state(glue); /* In case glue */
   GET_DIMEN
  }
 }    

<INITIAL,titlecheck,stricttitle>\\[a-zA-Z]+font[0-9]+   |
\\[a-zA-Z@]+              { /* Not a tth native command */
  TTH_DO_MACRO
  else if( (ind=indexkey(yytext,countkeys,&ncounters)) != -1) { 
    if(tth_debug&4) fprintf(stderr,"Setting counter %d, %s\n",ind,countkeys[ind]);
    yy_push_state(counterset);
  } else {
    if((!strstr(unknownstring,yytext)||tth_debug)&&!(tth_debug&32768)){
      fprintf(stderr,"**** Unknown command %s, (%d user-defined) Line %d\n",
	    yytext,nkeys-nbuiltins,tth_num_lines); 
      if(!strstr(unknownstring,yytext)&&
	 strlen(unknownstring)+strlen(yytext) < TTH_UNKS_LEN)
	strcat(unknownstring,yytext);
    }
    yy_push_state(unknown);
  }
 }


<unknown>\{    yy_push_state(matchbrace);
<unknown>\[[^\]]*\]   TTH_INC_MULTI;
<unknown>{ANY}       yy_pop_state();yyless(0);

<psub>(\\\\|\\\#)  strcat(psubstore,yytext);
<psub>.     strcat(psubstore,yytext);
<psub>{NL}    TTH_INC_LINE;strcat(psubstore,yytext);
<psub>##    {
  strcat(psubstore,"#");
  if(tth_debug&8) fprintf(stderr,"Double # added to %s\n",psubstore);
 }
			   /* Changed * to + here 4 Nov 07 */
<psub>(\\[a-zA-Z]+)?#[1-9] { /* Add space after a command string, in case */
  if( (js2 = strcspn(yytext,"#")) ){
    strcpy(scratchstring,yytext);
    if(!strstr(yytext,"\\verb")){/*Don't add space after \verb*/
      strcpy(scratchstring+js2," ");
    }else {*(scratchstring+js2)=0;}
    strcat(psubstore,scratchstring);
  }
  jscratch=margmax-jarg+1;
  i=indexkey(yytext+js2,margkeys,&jscratch);
  if(tth_debug&8)fprintf(stderr,"%s argument search starting at %d finds %d\n",
			 yytext,jscratch,i);
  if(i != -1) {
    strcat(psubstore,margs[i]);
  } else {
    fprintf(stderr,"Could not find argument %s on macro arg stack\n",yytext);
  }
  }
<psub>#tthdrop[0-9] {
  sscanf((yytext+strlen(yytext)-1),"%d",&i);
  if(tth_debug&8) fprintf(stderr,"dropping %d args\n",i);
  for (jscratch=0;jscratch<i;jscratch++) rmdef(margkeys,margs,&margmax);
  yy_pop_state();
  TTH_SCAN_STRING(psubstore);
  if(tth_debug&8) fprintf(stderr,"Scanning substituted text:%s\n",psubstore);
  *psubstore=0;
  }
<tokenarg,lookfornum,macarg,optag>#tthdrop[0-9] |
#tthdrop[0-9] fprintf(stderr,"**** Internal Error: encountered %s\n",yytext);

<delimint>{CMNT} {TTH_INC_MULTI;}
<delimint>\\(\\|%|\$|&|\#)    |
<delimint>{ANY}  {
  /* duplicated below  if(strcspn(yytext,"\n")==0) TTH_INC_LINE; */
  if(tth_debug&8){
    fprintf(stderr,"Horizmode=%d Whitespace=%d ",horizmode,whitespace);
    fprintf(stderr,
	    "yytext:%s, Template Remaining:%s\n",yytext,chscratch);
  }
  horiztemp=1; /* Default */
  strcpy(scratchstring,yytext);
  if(strstr(yytext,"\n") != NULL) {
    TTH_CHECK_LENGTH;
    TTH_INC_LINE;
    if(!whitespace){
      strcpy(scratchstring," ");
    } else {
      *scratchstring=0;
      if(whitespace==1)strcat(dupstore," "); /* save spaces if compressed*/ 
    }
    whitespace=2;
    if(horizmode==1){horiztemp=-1;}
    else if(horizmode==-1){
      horiztemp=0;
      strcpy(scratchstring,"\\");
      TTH_SCAN_STRING("par");
      if(tth_debug&8)fprintf(stderr,"Got implied \\par in parameter\n");
      if(*scratchstring!=*chscratch){
	fprintf(stderr,
	 "**** The \\par doesn't match the template character:%s\n",chscratch);
	fprintf(stderr,
         "**** Error. Probable runaway delimited parameter. Line %d.\n"
		,tth_num_lines);
	TTH_EXIT(3);
      }
    }
    else horiztemp=0;
  }else if(*yytext == '\t' || *yytext == ' ') {
    if(!whitespace){
      strcpy(scratchstring," "); 
    }else{
      *scratchstring=0;
      if(whitespace==1)strcat(dupstore," ");
    }
    whitespace=2;
    horiztemp=horizmode;
  }else if(strstr(yytext,"\\") && strlen(yytext)==2 ) { 
    strcpy(scratchstring,yytext+1);
    strcat(dupstore,"\\");
    if(whitespace==1)whitespace=2; else whitespace=0;
  }else if(*yytext == '\\') {
    whitespace=1;
  }else if( (*yytext>63 && *yytext<91) || (*yytext>96 && *yytext<123)){
    if(whitespace==1)whitespace=1; else whitespace=0;
  }else{
    if(whitespace==1)whitespace=2; else whitespace=0;
  }
  strcat(dupstore,scratchstring);
  if(*chscratch == '#' ) { /* Nondelimited argument. */
    if(tth_debug&8) fprintf(stderr,"Non-delimited argument; jarg=%d\n",jarg);
    chs2=chscratch+2;
    chscratch=chs2;
    if(strstr(yytext,"\n")){tth_num_lines--;}/*don't count twice*/
    yyless(0);
    horiztemp=horizmode;
    *dupstore=0;
    if(jarg){ /* Not for zeroth argument */
      bracecount=-1;
      yy_push_state(macarg);
      yy_push_state(embracetok);
    } else jarg++;
  }else if(*chscratch == '{'){ /* Last argument is nondelimited */
    jargmax=jarg;  /* use standard form of macarg */
    yyless(0);
    horiztemp=horizmode;
    *dupstore=0;
    bracecount=-1;
    yy_pop_state();
    yy_push_state(macarg);
    yy_push_state(embracetok);
  } else if(*chscratch == *scratchstring){   /* Normal delimited case. */
    chscratch++;
    if((*chscratch == '#')||(*chscratch == '{')){ /* Matched pattern seg */
      sprintf(argchar,"#%d",jarg);
      if(tth_debug&8)fprintf(stderr,"Matched Pattern:%s: jarg=%d, argchar=%s\n"
			   ,dupstore,jarg,argchar);
      jscratch=0;
      /* dupstore[strlen(dupstore)-(chscratch-chs2-compression)]=0;*/
      dupstore[strlen(dupstore)-(chscratch-chs2)]=0;
      if(jarg){
	mkdef(argchar,margkeys,dupstore,margs,
	      &jscratch,margn,&margmax);
	if(tth_debug&8){
	  i=indexkey(argchar,margkeys,&margmax);
	  fprintf(stderr,"Delimited Argument:%s: index %d Def %s\n",
		  argchar,i,margs[i]);
	}
      }
      if(*chscratch == '{') { /* Completed Template */
	jarg=1;
	yy_pop_state();
	TTH_SCAN_STRING(defs[ind]);
	if(tth_debug&8)fprintf(stderr,"Using definition %s (%d) = %s.\n",
			  keys[ind],ind,defs[ind]);
	yy_push_state(psub);
      }else{ /* Look for next argument */
	jarg++;
	chs2=chscratch+2;
	chscratch=chs2;
      }
      *dupstore=0;
      /* compression=0;*/
    }
  }else{ /* Mismatch. Start over. */
    chscratch=chs2;
    if(*scratchstring == '{') { /* Nested braces protect against matching. */
      bracecount=0; storetype=10; /* Was 4 till new definitions */
      yy_push_state(dupgroup);
    }
  }
  horizmode=horiztemp;
}
<removespace>{NL} {
  TTH_CHECK_LENGTH;
  TTH_INC_LINE;
  if(horizmode==1){
    horizmode=-1;
    yy_push_state(parcheck);
    TTH_OUTPUT(yytext);
  }else if(horizmode==-1) {
    fprintf(stderr,"**** Abnormal NL, removespace. Line %d\n",tth_num_lines);
  }
}
<removespace>[ \t]
<removespace>[^ ]  {
  if(tth_debug&16)fprintf(stderr,"End of removespace:%s\n",yytext);
  yy_pop_state();yyless(0);
 }
<ruledim>{WSP}*(width|height|depth)      TTH_INC_MULTI;GET_DIMEN;
<ruledim>{ANY}   yyless(0);yy_pop_state();   

%%
 /********************************** CODE ******************************/

int main(argc,argv)
int argc;
char *argv[];
{
int raw=0,httpcont=0;
int i,ilatex=0,ititle=1;
char *spoint=0;
char ttver[]=TTH_VERSION;
char ttname[20];
time_t secs_elapsed;
time_t make_time=939087164;
char timestr[]="On 00 Jan 2000, 00:00.";
FILE *fdin=0;
int horizmode=1; /* In signoff use font tags not divs */
char main_input[TTH_CHARLEN];
char main_output[TTH_CHARLEN];
  tth_fdout=stdout; 
  if((spoint=strstr(tth_DOC,"XXXX"))){ /* Make version strings */
    strcpy(ttname,"Tt");
    strcat(ttname,TTH_NAME);
    strncpy(spoint-10-strlen(ttname),ttname,strlen(ttname));
    strncpy(spoint,ttver,strlen(ttver));
    if(strstr(TTH_NAME,"M")){ /* MathML */
      tth_mathitalic=0; /* Don't use for mml */
      tth_htmlstyle=2; /* Use default XHTML style for MathML*/
#ifdef TTM_LAPSED
      time(&secs_elapsed);
      /*fprintf(stderr,"Maketime=%ld, elapsed=%ld",(long)make_time,
	(long)secs_elapsed); */
      if(make_time!=939087164){
	if(secs_elapsed>make_time+30*24*60*60){
	  fprintf(stderr,TTM_LAPSED);
	  TTH_EXIT(1);
	}
      }
#else
      secs_elapsed=make_time;
#endif
      while((spoint=strstr(tth_DOC,"tth")))strncpy(spoint,"ttm",3);
      while((spoint=strstr(tth_DOC,"TtH")))strncpy(spoint,"TtM",3);
      while((spoint=strstr(tth_USAGE,"tth")))strncpy(spoint,"ttm",3);
      while((spoint=strstr(tth_USAGE,"TtH")))strncpy(spoint,"TtM",3);
      while((spoint=strstr(tth_DOC,"(TeX-to-HTML")))
	strncpy(spoint,"  Tex to MathML/HTML translator.       ",
		strlen("  Tex to MathML/HTML translator.       "));
    }
  }
  for (i=1;i<argc;i++){
    if(strspn(argv[i],"-") != 1){ /*Non-switch*/
      if(strlen(tth_latex_file)){
	fprintf(stderr,
       "**** Invalid switch, %s, or input file already specified.\n",argv[i]); 
	return 1;
      }
      strcpy(tth_latex_file,argv[i]);


      if(!(spoint=strstr(tth_latex_file,".tex")))
	spoint=strstr(tth_latex_file,".TEX");
      if(tth_latex_file+strlen(tth_latex_file)-spoint==4)*spoint=0;
      strcpy(main_input,tth_latex_file);
      strcat(main_input,".tex");
      strcpy(main_output,tth_latex_file);
      strcat(main_output,".html");
      fdin=fopen(main_input,"r");
      if(fdin) tth_fdout=fopen(main_output,"w");
      if(fdin && tth_fdout){
	yyin=fdin;
	fprintf(stderr,"Translating %s to %s\n",main_input,main_output);
      }else{
	fprintf(stderr,"**** Invalid switch or file: %s\n",argv[i]); 
	return 1;
      }
    }else{
      switch(*(argv[i]+1)){
      case 'a': tth_autopic=1;break;
      case 'c': httpcont=1;break;
      case 'd': tth_delimdef=0;break;
      case 'e': sscanf(argv[i]+2,"%d",&tth_epsftype);break;
      case 'f': sscanf(argv[i]+2,"%d",&tth_flev0); 
	fprintf(stderr,"Fraction level %d\n",tth_flev0);break;
      case 'g': tth_fontguess=0;break;
      case '?': {if(*(argv[i]+2)=='q'){ printf("%s",tth_DOCQ); }
                 else {printf("%s",tth_USAGE);}; return 0;};
      case 'H': case 'h': fprintf(stderr,"%s",tth_DOC); return 0;
      case 'I': case 'i': if(tth_mathitalic==1){
	  strcpy(tth_font_open[0],"<i>");
	  strcpy(tth_font_close[0],"</i>");
	  TTH_CCPY(tth_fonto_def,tth_font_open[0]);
	  TTH_CCPY(tth_fontc_def,tth_font_close[0]);
        }else{
	  /* Make all (even multi-letter) identifiers italic*/
	  strcpy(tth_font_open[0],TTH_ITALO);
	}
	break;
      case 'j': tth_indexpage=9999;
	if(*(argv[i]+2)) sscanf(argv[i]+2,"%d",&tth_indexpage); 
	fprintf(stderr,"HTML index page length %d\n",tth_indexpage);break;
      case 'k': strcpy(tth_latex_file,argv[i]+2);break;
      case 'L': case 'l':{
	if(strlen(tth_latex_file)){
	  fprintf(stderr,
	      "Do not use both -L switch and file command-line argument %s\n",
		  main_input);
	  return 1;
	}
	strcpy(tth_latex_file,argv[i]+2);
	fprintf(stderr,"Including LaTeX commands\n");
	ilatex=1;
	break;
      }
      case 'n': 
	tth_titlestate=4;
	if(*(argv[i]+2)) sscanf(argv[i]+2,"%d",&tth_titlestate);
	break;
      /*case 'n': tth_multinum=0;break; disable 3.0*/
      case 'P': case 'p':
	if(!strcmp(argv[i]+2,"NULL")){tth_allowinput=0;}
	TTH_CCPY(tth_texinput_path,argv[i]+2);break;
      case 'r': raw=1;if(*(argv[i]+2)) sscanf(argv[i]+2,"%d",&raw);break;
      case 's': tth_splitfile=1;break; /*sf*/
      case 't': tth_inlinefrac=1;break;
      case 'u': tth_unicode=1;
	if(*(argv[i]+2)) sscanf(argv[i]+2,"%d",&tth_unicode); 
	fprintf(stderr,"HTML unicode style %d\n",tth_unicode);break;
      case 'v': tth_verb=1; tth_debug=1;
	if(*(argv[i]+2)=='?'){fprintf(stderr,"%s",tth_debughelp);return 1;}
	else if(*(argv[i]+2)) sscanf(argv[i]+2,"%d",&tth_debug);
        break;
      case 'V': tth_verb=1; tth_debug=2048+256+7;break;
      case 'w': sscanf(argv[i]+2,"%d",&tth_htmlstyle); 
	fprintf(stderr,"HTML writing style %d\n",tth_htmlstyle);
	if(!tth_htmlstyle&1) ititle=0;break;
      case 'x':strcpy(tth_index_cmd,argv[i]+2);break;
      case 'y':  sscanf(argv[i]+2,"%d",&tth_istyle); 
	fprintf(stderr,"Equation layout style %d\n",tth_istyle);
	break;
    }
      if(tth_verb)fprintf(stderr,"Debug level %d\n",tth_debug);
    }
  }
  if((spoint=getenv("TTHINPUTS"))){
    TTH_CCAT(tth_texinput_path,PATH_SEP);TTH_CCAT(tth_texinput_path,spoint);}
  if(httpcont) fprintf(tth_fdout,"Content-type: text/HTML\n\n");
  if(tth_splitfile) fprintf(tth_fdout,TTH_MIME_HEAD); /*sf*/
  if(raw!=1){
    fprintf(tth_fdout,TTH_DOCTYPE);
    fprintf(tth_fdout,TTH_GENERATOR,TTH_NAME,TTH_VERSION);
    fprintf(tth_fdout,TTH_ENCODING);
    /*if(tth_htmlstyle&2) */
    fprintf(tth_fdout,"%s",TTH_P_STYLE);
    if(tth_istyle)fprintf(tth_fdout,"%s",TTH_STYLE);
    if(!(tth_htmlstyle&4))fprintf(tth_fdout,"%s",TTH_SIZESTYLE);
  }
  if(tth_flev0) tth_flev0=tth_flev0+2; /* Increment to compensate for dummy levels. */
  if(ititle && raw!=1){
    if(tth_htmlstyle&3){
      yy_push_state(stricttitle); 
    }else{
      yy_push_state(titlecheck);
    }
  }
  yy_push_state(builtins);
  if(ilatex)yy_push_state(latexbuiltins);
  /* if(tth_debug)
    fprintf(stderr,"Starting yylex\n"); */
  yylex();
  fprintf(stderr, "Number of lines processed approximately %d\n", 
	  tth_num_lines-1);
  /* Time stamp */
  time(&secs_elapsed);
  spoint=ctime(&secs_elapsed);
  strncpy(timestr+3,spoint+8,2);
  strncpy(timestr+6,spoint+4,3);
  strncpy(timestr+10,spoint+20,4);
  strncpy(timestr+16,spoint+11,5);
  if(raw==2)*timestr=0; /* Not if -r2 */
  if(raw!=1 && raw != 4){
    fprintf(tth_fdout,"\n<br /><br /><hr /><small>File translated from\n\
T<sub>%sE%s</sub>X\nby <a href=\"http://hutchinson.belmont.ma.us/tth/\">\n\
T<sub>%sT%s</sub>%s</a>,\n\
version %s.<br />%s</small>\n",TTH_SMALL,TTH_SIZEEND,TTH_SMALL,TTH_SIZEEND
		    ,TTH_NAME,TTH_VERSION,timestr);
  }
  if(raw!=1){
    if(tth_htmlstyle&3)fprintf(tth_fdout,"</div></body>");
    fprintf(tth_fdout,"</html>\n");
  }
  if(tth_debug&16) fprintf(stderr, "Exit pushdepth= %d\n",tth_push_depth);
  /* silence gcc warnings:*/ if(1==0){yy_top_state();input();}
  return 0;
} /* end main */

void tth_push(arg)
char arg[];
{
	if(tth_debug&16) fprintf(stderr,"tth_push:%s depth:%d\n",\
			arg,tth_push_depth);	
	if(tth_push_depth == TTH_MAXDEPTH) {
	  fprintf(stderr,
		  "**** Error Fatal: Attempt to exceed max nesting:%d\n",
		  tth_push_depth);
	  TTH_FATAL(6);
	}else{
	  strcpy(tth_closures[tth_push_depth],arg);
	  strcpy(tth_font_open[tth_push_depth+1],
		 tth_font_open[tth_push_depth]);
	  strcpy(tth_font_close[tth_push_depth+1],
		 tth_font_close[tth_push_depth]);
	  tth_push_depth++;
	}
	arg[0]=0;
}

void tth_pop(arg)
char arg[];
{
  if(tth_push_depth < 1){ 
    fprintf(stderr,"**** Error: Fatal. Apparently too many }s.\nCheck for TeX errors or incompatibilities before line %d,\nnext material      ",tth_num_lines);
    /*TTH_FATAL(1);*/
    yy_push_state(error);
    tth_ercnt=40;
  }else{
    tth_push_depth--;
    strcpy(arg,tth_closures[tth_push_depth]);
    if(tth_debug&16) fprintf(stderr,"tth_pop:%s depth:%d\n",\
			    arg,tth_push_depth);	
  }
}

/* ********************************************************************
   Process epsbox. If epsftype=0 put link. Arg is the file name.
   epsftype=1 Convert the ps or eps file to a gif reference. 
   epsftype=2 Ditto but inline it. epsftype=3 inline an iconized version.*/
void tth_epsf(arg,epsftype)
char *arg;
int epsftype;
{
#define NCONV 2
#define NGTYPES 3
 char *gtype[NGTYPES]={"png","gif","jpg"};
 char commandstr[150]={0};
 char filestr[150]={0};
 char filestr1[150]={0};
 char filestr2[150]={0};
 FILE *giffile;
 int sys=SUCCESS;
 int c,i,psfound;
 char *ext;
 char eqstr[1]; /*dummy here for tthfunc*/
 *eqstr=0;        /*silence warnings */ 
 ext=arg;         /*silence warnings */
if(epsftype==0){
  fprintf(tth_fdout,"<a href=\"%s\">Figure</a>",arg);
}else{
  c=0;
  for(i=1;i<=(strlen(arg)<4 ? strlen(arg) : 4);i++){
    ext=arg+strlen(arg)-i;
    if(*ext=='.'){
      c=i;
      break;
    }
    ext=ext+i;
  }
  if(c){
    if(strcmp(ext,".eps") && strcmp(ext,".EPS")
       && strcmp(ext,".ps") && strcmp(ext,".PS")
       && strcmp(ext,".pdf") && strcmp(ext,".PDF"))
      {
      fprintf(stderr,"Not a [e]ps file: %s, no conversion\n",arg);
      if(epsftype==1) fprintf(tth_fdout,"<a href=\"%s\">Figure</a>",arg);
      if(epsftype==2) fprintf(tth_fdout,"<img src=\"%s\" alt=\"%s\" />",arg,arg);
      return;
    }
  }
  /* c=length of extension.*/
  strcpy(filestr,arg);
  giffile=fopen(filestr,"r");
  psfound=0;
  if(giffile == NULL){ /* Try possible file names */
    if(tth_debug&32)fprintf(stderr,"Graphic Input File %s not found.\n",filestr);
    if(c==0){
      strcat(filestr,".eps");
      giffile=fopen(filestr,"r");
      if(giffile == NULL){
	if(tth_debug&32)fprintf(stderr,"Graphic Input File %s not found.\n",filestr);
	strcpy(filestr,arg); strcat(filestr,".ps");
	giffile=fopen(filestr,"r");
	if(giffile == NULL){
	  if(tth_debug&32)fprintf(stderr,"Graphic Input File %s not found.\n",filestr);
	  strcpy(filestr,arg); strcat(filestr,".pdf");
	  giffile=fopen(filestr,"r");
	  if(giffile == NULL){
	    if(tth_debug&32)fprintf(stderr,"Graphic Input File %s not found.\n",filestr);
	    psfound=0;
	    strcpy(filestr,arg); /*Restore original name*/
	  }else{
	    fprintf(stderr,"Found %s. ",filestr);
	    psfound=1;
	    c=4;
	  }
	}else{
	  fprintf(stderr,"Found %s. ",filestr);
	  psfound=1;
	  c=3;
	}
      }else{
	fprintf(stderr,"Found %s. ",filestr);
	psfound=1;
	c=4;
      }
    }
  }else{psfound=1;}
  strcat(filestr1,filestr); /* The file we found for input if any.*/
  filestr[strlen(filestr)-c]=0;
  sys=SUCCESS+1;
  for(c=0;c<NGTYPES;c++){ /* Check for already translated files */
    sprintf(filestr2,"%s.%s",filestr,gtype[c]);
    if(tth_debug&32)fprintf(stderr,"Trying %s\n",filestr2);
    if ((giffile=fopen(filestr2,"r")) != NULL){
      fprintf(stderr,"Graphic %s exists. No conversion.\n",filestr2);
      strcpy(filestr,filestr2);
      sys=SUCCESS;
      fclose(giffile);
      break;
    }
  }
  if(psfound){
    if(sys!=SUCCESS){ /* No existing graphic. Translate. */
      for(c=0;c<NCONV;c++){
	sprintf(filestr2,"%s.%s",filestr,gtype[c]);
	sprintf(commandstr,"ps2%s %s %s",gtype[c],filestr1,filestr2);
	if(epsftype==3){ /* Icon version of ps2pnm/gif with 3 arguments */
	  sprintf(commandstr+strlen(commandstr)," %s_icon.%s",filestr,gtype[c]);
	}
	fprintf(stderr,"Converting file %s ",filestr1);
	if(tth_debug&32)fprintf(stderr,"Command: %s",commandstr);
	sys=system(commandstr);
	if(sys==SUCCESS){
	  if((giffile=fopen(filestr2,"r"))!=NULL){
	    fclose(giffile);
	    sprintf(filestr1,"%s_icon.%s",filestr,gtype[c]);
	    strcpy(filestr,filestr2);
	    break;
	  }else{sys=SUCCESS+1;}
	}
      }
    }
  }
  if(sys == SUCCESS){
    if(epsftype==1) fprintf(tth_fdout,"<a href=\"%s\">Figure</a>",filestr);
    if(epsftype==2) fprintf(tth_fdout,"<img src=\"%s\" alt=\"%s\" />",filestr,filestr);
    if(epsftype==3) fprintf(tth_fdout,"<a href=\"%s\"><img src=\"%s\" alt=\"%s\" /></a>"
			    ,filestr,filestr1,filestr1);
  }else if(psfound){ /* This can only happen if the system call occurs. */
    fprintf(stderr,"**** System call:%s failed.\n",commandstr);
    fprintf(stderr,
	    "**** This failure is NOT in TtH; it is in an auxiliary program.\n");
    fprintf(tth_fdout,"<a href=\"%s\">Figure</a>",arg);
  }else {
    fprintf(stderr,"**** No suitable source file for %s\n",arg);
  }
}
}
/**************************************************************************/
/* handling code for defs */

static int indexkey(key,keys,nkeys)
char *key;
char *keys[];
int *nkeys;
{
  int i, j;
  j=-1;
  for(i = *nkeys-1; i>=0; i--) {
    if(!strcmp(key,keys[i])) {
      j=i;
      break;
    }
  }
  return j;
}

static void mkkey(key,keys,nkeys)
char *key;
char *keys[];
int *nkeys;
{
  size_t size;
  size=strlen(key)+1;
  keys[*nkeys]=malloc(size);
  strcpy(keys[*nkeys],key);
  (*nkeys)++;
}

static void mkdef(key,keys,def,defs,narg,nargs,nkeys)
char *key;
char *keys[];
char *def;
char *defs[];
int *narg;
int nargs[];
int *nkeys;
{
  size_t size;
  size=strlen(key)+1;
  keys[*nkeys]=malloc(size);
  strcpy(keys[*nkeys],key);
  size=strlen(def)+1;
  defs[*nkeys]=malloc(size);
  strcpy(defs[*nkeys],def);
  nargs[*nkeys]=*narg;
  (*nkeys)++;
}

static void rmkey(keys,nkeys)
char *keys[];
int *nkeys;
{
  if((*nkeys) > 0){
    (*nkeys)--;
    free(keys[*nkeys]); 
    keys[*nkeys]=0;
  } else {
    fprintf(stderr,"**** Error: No keys left to remove\n");
  }
}

static void rmdef(keys,defs,nkeys)
char *keys[];
char *defs[];
int *nkeys;
{
  if((*nkeys) > 0){
    (*nkeys)--;
    free(keys[*nkeys]); 
    keys[*nkeys]=0;
    free(defs[*nkeys]);
    defs[*nkeys]=0;
  } else {
    fprintf(stderr,"**** Error: No defs left to remove\n");
  }
}

void tth_undefine(keys,nkeys,udkey,lkeys)
char *keys[];
int *nkeys;
int udkey;
int lkeys[];
     /* Undefine all local keys (lkeys(n)=1) from udkey to nkeys-1 */
{
  /*static void rmkey();*/
  int i,ig;
  ig=0;
  for(i=(*nkeys)-1;i>=udkey;i--) {
    if(lkeys[i]){
      if(tth_debug&4)fprintf(stderr,
			     "Undefining:Key %d, %s, %s\n",i,keys[i],
			     (ig ? "Trapped." : "Freed."));
      if(ig){
	*keys[i]=0;
	lkeys[i]=0;
      }else{
	rmkey(keys,nkeys);
      }
    }else{ig=1;}
  }
}

void tth_enclose(str0,str1,str2,store) /* Enclose str1 with str0, str2 */
char *str0, *str2, *str1, *store;
{ /* Exit if string gets more than 3.5 of the 4*max */
  int lost;
  strcpy(store,str1);
  if((lost=strlen(str2)+strlen(store)- TTH_34DLEN) < 0){
    strcat(store,str2);
  }else{
   fprintf(stderr,"**** Error: Fatal. String overflow: Lengths %d,%d\n",
	   (int)strlen(store),(int)strlen(str2));
    fprintf(stderr,"Line %d\n",tth_num_lines);
    TTH_FATAL(2);
  }
  strcpy(str1,str0);
  if((lost=strlen(str1)+strlen(store)- TTH_34DLEN) < 0){
    strcat(str1,store);
  }else{
   fprintf(stderr,"**** Error: Fatal. String overflow: Lengths %d,%d\n",
	   (int)strlen(store),(int)strlen(str1));
    fprintf(stderr,"Line %d\n",tth_num_lines);
    TTH_FATAL(2);
  }
}

void tth_prefix(str0,str1,store)  /* Prefix str1 by str0, in str1 */
char *str0, *str1, *store;
{
  int lost;
  strcpy(store,str1);
  strcpy(str1,str0);
  if((lost=strlen(str1)+strlen(store)- TTH_34DLEN) < 0){
    strcat(str1,store);
  }else{
    fprintf(stderr,
      "**** Error: Fatal. Prefix string overflow: String %d, Prefix %d\n"
	    ,(int)strlen(store),(int)strlen(str1));
    fprintf(stderr,"Line %d. Check for excessive length equation.\n%s\n"
	    ,tth_num_lines," If necessary use switch -y0.");
    TTH_FATAL(2);
  }
}
/************************************************************************/
/* start delimit */
static void delimit(char *type, int heightin, char *codes)
     /* Return codes corresponding to a delimiter of given type and height*/
{
#define notypes 14
  static int top[notypes]={230,246,233,249,236,252,234,243,233,249,234,250,32,32};
  static int flat[notypes]={231,247,234,250,239,239,234,244,234,250,234,250,32,32};
  static int mid[notypes]={231,247,234,250,237,253,234,244,234,250,234,250,225,241};
  static int bot[notypes]={232,248,235,251,238,254,234,245,234,250,235,251,32,32};
  int i,j;
  char chr1[2]={0};
  char buff[20];
  int height;
  int horizmode=1; /* In equations use font tags not divs */

  /*tth_istyle case*/ 
  if(tth_istyle&1) height=0.65*heightin + 0.71;  /* 2 has to yield 2*/
  else height=0.95*heightin+heightin*heightin/16 +.11;
  /* Experimental size. Evenness fixed. If very large assume matrix. */
  if(tth_debug&32)fprintf(stderr,"Delimiter %s, heightin=%d, height=%d\n",
			  type,heightin,height);

  if     (!strcmp(type,"(")) i=0 ;
  else if(!strcmp(type,")")) i=1 ;
  else if(!strcmp(type,"[")) i=2 ;
  else if(!strcmp(type,"]")) i=3 ;
  else if(!strcmp(type,"{")) {i=4 ; height=2*(height/2)+1;}
  else if(!strcmp(type,"}")) {i=5 ; height=2*(height/2)+1;}
  else if(!strcmp(type,"|")) i=6 ;
  else if(!strcmp(type,"&#242;")) i=7 ; /* int */
  else if(!strcmp(type,"&#233;")) i=8 ; /* lceil */
  else if(!strcmp(type,"&#249;")) i=9 ; /* rceil */
  else if(!strcmp(type,"&#235;")) i=10 ; /* lfloor */
  else if(!strcmp(type,"&#251;")) i=11 ; /* rfloor */
  else if(!strcmp(type,"&#225;")) i=12 ; /* langle */
  else if(!strcmp(type,"&#241;")) i=13 ; /* rangle */
  else if(!strcmp(type,"/") || !strcmp(type,"\\")) {
    /* Old version with font size=+... and bug   sprintf(codes,
	    "</td><td align=left>%s%d%s%s%s</td><td align=center>\n",
	   TTH_SIZEGEN1,2*(height-1),TTH_SIZEGEN2,TTH_SIZEEND,type);
    */
    sprintf(codes,
	    "</td><td align=left>%s%d%s%s%s</td><td align=center>\n",
	    TTH_SIZEGEN1,100*(height),TTH_SIZEGEN2,type,TTH_SIZEEND);
    return;
  }
  else if(!strcmp(type,"&#214;")) { /* Sqrt code */
    if(tth_root_len[tth_root_depth]){ /* An index exists */
      if(heightin<=2 ){
	if(tth_istyle&1){
	  sprintf(codes,"%s%s%s%s %s%s%s%s",TTH_CELL_R,TTH_OA1,
		  TTH_FOOTNOTESIZE,tth_root_index[tth_root_depth],
		  TTH_SIZEEND,TTH_OA2,TTH_SYMBOL,TTH_large);
	  chr1[0]=214;
	  sprintf(codes+strlen(codes),
		  "%s%s%s%s%s",TTH_SYMPT(chr1),TTH_SIZEEND,TTH_SYMEND,TTH_OA3,TTH_CELL3);
	}else{ 
	  chr1[0]=230;
	  sprintf(codes,"%s\n%s%s %s%s%s%s<br />",
		  TTH_CELL_R,TTH_SCRIPTSIZE,tth_root_index[tth_root_depth],
		  TTH_SIZEEND,TTH_SYMBOL,TTH_NORMALSIZE,TTH_SYMPT(chr1));
	  chr1[0]=214;
	  sprintf(codes+strlen(codes),"%s <br />%s%s%s",
		  TTH_SYMPT(chr1),TTH_SIZEEND,TTH_SYMEND,TTH_CELL3);
	}
      }else{
	chr1[0]=230;
	sprintf(codes,"%s%s%s%s %s%s%s%s<br />",TTH_CELL_R,TTH_OA5,TTH_SMALL,
		tth_root_index[tth_root_depth],TTH_SIZEEND,
		TTH_SYMBOL,TTH_Large,TTH_SYMPT(chr1));
	chr1[0]=231;
	for(j=1;j<(height*.78-2.3);j++){ /* extra sqrt height */
	  sprintf(codes+strlen(codes),"%s<br />",TTH_SYMPT(chr1));
	}
	chr1[0]=214;
	if(tth_istyle&1) sprintf(codes+strlen(codes),
	      "%s%s\n&nbsp;%s%s%s",TTH_SYMPT(chr1),TTH_SIZEEND,TTH_SYMEND,
				 TTH_OA3,TTH_CELL3);
	else sprintf(codes+strlen(codes),"%s%s\n&nbsp;%s<br />\n%s",
		     TTH_SYMPT(chr1),TTH_SIZEEND,TTH_SYMEND,
		     TTH_CELL3);
      }
    }else{  /* Vanilla */
      if(heightin > 2){
	chr1[0]=230;
	sprintf(codes,
		"%s\n%s&nbsp;&nbsp;%s%s<br />"
		,TTH_CELL_L,TTH_Large,TTH_SYMBOL,TTH_SYMPT(chr1));
	chr1[0]=250;
	for(j=1;j < (0.78*height-2.3);j++){
	  sprintf(codes+strlen(codes),"%s&nbsp;%s%s<br />\n",
		  TTH_SYMEND,TTH_SYMBOL,TTH_SYMPT(chr1));
	}/* Accommodate Konqueror nbsp symbol bug */
	chr1[0]=214;
	sprintf(codes+strlen(codes),"%s<br />%s%s%s",
		TTH_SYMPT(chr1),TTH_SIZEEND,TTH_SYMEND,TTH_CELL3);
      }else{
	chr1[0]=214;
	sprintf(codes,
		"%s<br />%s%s%s%s<br />%s%s%s",TTH_CELL_L,TTH_SYMBOL,
		TTH_Large,TTH_SYMPT(chr1),TTH_SIZEEND,TTH_SYMEND,TTH_OA4,TTH_CELL3);
      }
    }
    *tth_root_index[tth_root_depth]=0;
    tth_root_len[tth_root_depth]=0;
    tth_root_depth--;
    return;
  }
  else if(!strcmp(type,".")) { *codes=0; return; }
  else {
    fprintf(stderr, "Incorrect delimiter::%s::\n",type); 
    i=-1;
    *codes=0;
    return;
  }

  /* Now using 8 bit codes. */
  if(height>1){
    strcpy(codes,TTH_CELL_L);
    strcat(codes,TTH_SYMBOLN);
    for (j=1 ; j <= height ; j++){
      if(j == 1) {chr1[0]=top[i]; sprintf(buff,"%s<br />",TTH_SYMPT(chr1));}
      else if(j == height) {chr1[0]=bot[i]; sprintf(buff,"%s\n",TTH_SYMPT(chr1));}
      else if(j == (height+1)/2) {
	chr1[0]=mid[i];sprintf(buff,"%s<br />\n",TTH_SYMPT(chr1));}
      else {chr1[0]=flat[i]; sprintf(buff,"%s<br />",TTH_SYMPT(chr1));}
      strcat(codes,buff);
    } 
    strcat(codes,TTH_SYMEND);
    strcat(codes,TTH_CELL3);
    if(tth_debug&512) fprintf(stderr,"codes=%s",codes);
  }else{
    if(i > 6){
      strcpy(codes,TTH_SYMBOLN);
      strcat(codes,TTH_SYMPT(type));
      strcat(codes,TTH_SYMEND);
    }else strcpy(codes,type);
  }
}
  /* end delimit */
  /*start symext*/
/**************** Construct large, possibly extended, character. */
void tth_symext(charin,charout)
char *charin,*charout;
{
  int horizmode=1; /* In equations use font tags not divs */
  char chr1[2]={0};
  chr1[0]=242;
  if(strlen(charin) == 1){
    if(charin[0]==chr1[0]) {
      strcpy(charout,TTH_SYMBOL);
      chr1[0]=243;strcat(charout,TTH_SYMPT(chr1));
      strcat(charout,"<br />");
      chr1[0]=245;strcat(charout,TTH_SYMPT(chr1));
      strcat(charout,"<br />");
      strcat(charout,TTH_SYMEND);
    }else {
      strcpy(charout,TTH_LARGE);
      strcat(charout,TTH_SYMBOL);      
      strcat(charout,TTH_SYMPT(charin));
      strcat(charout,"<br />\n") ;
      strcat(charout,TTH_SYMEND);
      strcat(charout,TTH_SIZEEND);
    }
  }else{ /* Longer than one: remove a leading space, quote and terminate. */
    if(*charin==' ')strcpy(charout,charin+1); else strcpy(charout,charin);
    if(strstr(charout,TTH_OBR)+strlen(TTH_OBR)!=charout+strlen(charout)
       && strstr(charout, /*This mess is really TTH_DIV without eqclose ref*/
		 (tth_istyle&1 ? 
		  "\n<div class=\"hrcomp\"><hr noshade=\"noshade\" size=\"1\"/></div>"
		  :"<hr noshade=\"noshade\" size=\"1\" />")
       )+strlen(
		 (tth_istyle&1 ? 
		  "\n<div class=\"hrcomp\"><hr noshade=\"noshade\" size=\"1\"/></div>"
		  :"<hr noshade=\"noshade\" size=\"1\" />")
	  )!=charout+strlen(charout)
       && strstr(charout+strlen(charout)-9,"ble>")==NULL)
      strcat(charout,"<br />\n");
  } /* Don't add an extra br to a hr or table end. */
}
  /*end symext*/
/***************** Encode 3-digit integers *************************/
void tth_encode(code,num)
char *code;
int num;
{
int i;
sprintf(code,"%03d",num);
for (i=0;i<3;i++) *(code+i)=*(code+i) + 17;
}

/*******************************************************************/
/* Find the first brace group in the string "text" and copy it to the
   string group, whose maximum length is len, value returned 0 if successful.*/
int tth_group(group,text,len)
char *text,*group;
int len;
{
  int i,j;
  int brace;
  i=strspn(text," \t\n");
  /* if(*(text+i)=='{') i++;  remove leading brace */
  j=0;
  brace=0;                /* 1 if removing braces */
  while(i+j < strlen(text)){
    if(*(text+i+j)=='{')brace++;
    else if(*(text+i+j)=='}')brace--;
    if(brace <= 0) break;
    j++;
  }
  strncpy(group,text+i,len);
  if(i+j<len) *(group+i+j+1)=0;
  return brace;
}

/*******************************************************************/
/* Convert an integer into roman numerals. */
static int roman(int num, char *rm)
{
#define CODENUM 8
  int i,j,k,m,n,p;
  int multiples[CODENUM]={1000,500,100,50,10,5,1,0};
  char codes[CODENUM]={'m','d','c','l','x','v','i',' '};
  if(abs(num) >= 4*multiples[0]){
    strcpy(rm,"A LARGE NUMBER");
    return 1;
  }
  m=0;
  i=num;
  if(i < 0){
    i=-i;
    *(rm+(m++))='-';
  }
  for(j=0;j<CODENUM-1;j++){
    k=multiples[j];
    while(i-k>=0){
      i=i-k;
      *(rm+(m++))=codes[j];
    }
    if(j<CODENUM-2){
      n=(j/2)*2+2;
      p=multiples[n];
      if(i+p>=k){
	i=i-(k-p);
	*(rm+(m++))=codes[n];
	*(rm+(m++))=codes[j];
      }
    }
  }
  *(rm+(m++))=0;
  return 0;
}
/* start b_align */    
/*************************************************************************
 Take off the Cell start and the extra bottom from single over construct.
 This is used only at the completion of the top or bottom of a fraction.
 If cell starts or ends with CELL3, cut off since they are redundant.
 If it then ends with OA4 it is a candidate for bottom removal.
 If every CELL3 appears as part of the sequence OA4 CELL3, then change
 each occurrence to just CELL3.
 */
#define BMAXLEN 1000
#define NSTS 20
static int b_align(thestring,tth_debug)
     char *thestring;
     int tth_debug;
{
  char buff1[BMAXLEN];
  char *chr,*chr1,*chr2;
  char *oastarts[NSTS];
  char *oa4null="                                             ";
  int ists=0,i;

  if(tth_debug&8192)fprintf(stderr,"b_align string:%s",thestring);
  if(strlen(thestring) > BMAXLEN) return 0; /*Too long*/
  strcpy(buff1,thestring);
  if(strstr(thestring,TTH_CELL3) == thestring) { /*Starts with CELL3 */
    strcpy(buff1,thestring+strlen(TTH_CELL3));
    if(tth_debug&2)fprintf(stderr,"String Head cut, ");
  }	
  if(strstr(buff1+strlen(buff1)-strlen(TTH_CELL3),TTH_CELL3)){/*end*/
    *(buff1+strlen(buff1)-strlen(TTH_CELL3))=0;
    if(tth_debug&2)fprintf(stderr,"String Tail cut. ");	
  }
  if((oastarts[0]=strstr(buff1+strlen(buff1)-strlen(TTH_OA4),TTH_OA4))){
    chr=buff1;
    for (ists=0; ists<NSTS; ists++) {
      if((chr1=strstr(chr,TTH_CELL3))){
	chr2=chr1-strlen(TTH_OA4);
	if(chr2-chr<0){ists=-1; break;} 
	if(strstr(chr2,TTH_OA4)!=chr2){ists=-2; break;}
	oastarts[ists+1]=chr2;
	chr=chr1+strlen(TTH_CELL3);
      }else{
	 break;
      }
    } /* We exit with ists=number of OA-CELLs or - if non-treatable. */
    for (i=0;i<=ists;i++) {
      strncpy(oastarts[i],oa4null,strlen(TTH_OA4));
    }
    if(tth_debug&2)fprintf(stderr,"String OA4 removed %d times:\n%s\n",
			   ists+1,buff1);	
  }
  strcpy(thestring,buff1);
  return (ists+1);
} /* end b_align */
/****************************************************************************
Convert a dimension into scaled points. 1pt = 2^16 = 65536 sp.
1pc =12pt = 786432 sp
1in =72.27pt =4736287 sp
1bp =72.27/72pt =1.0038 pt= 65785 sp 
1cm =1in/2.54 = 1864680 sp 
1mm = 18648 sp
1dd =1238/1157 pt = 70124 sp
1cc = 12 dd = 841489 sp
1em = width of a quad (capital M, actually the height of it)
1ex = height of 'x'.

This needs 4 byte integers.
*/
#define EMPOINTS 12
#define ENPOINTS 6
#define EXPOINTS 10
static int scaledpoints(thenumber,thedimension)
     float thenumber;
     char *thedimension;
{
int dimval;
if(strstr(thedimension,"pt")==thedimension)dimval=65536;
else if(strstr(thedimension,"pc")==thedimension)dimval=786432;
else if(strstr(thedimension,"in")==thedimension)dimval=4736287;
else if(strstr(thedimension,"bp")==thedimension)dimval=65785;
else if(strstr(thedimension,"cm")==thedimension)dimval=1864680;
else if(strstr(thedimension,"mm")==thedimension)dimval=186468;
else if(strstr(thedimension,"dd")==thedimension)dimval=70124;
else if(strstr(thedimension,"cc")==thedimension)dimval=841489;
else if(strstr(thedimension,"ex")==thedimension)dimval=EXPOINTS*65536;
else if(strstr(thedimension,"em")==thedimension)dimval=EMPOINTS*65536;
else if(strstr(thedimension,"en")==thedimension)dimval=ENPOINTS*65536;
else if(strstr(thedimension,"sp")==thedimension)dimval=1;
else dimval=1;
return ((int) (dimval*thenumber));
}

/* Add dimension 2 into dimension 1*/
static int adddimen(number1,unit1,number2,unit2)
     float *number1,*number2;
     char *unit1,*unit2;
{
  if(*unit1=='%'){/* hsize supercedes others */
    if(*unit2=='%') {
      *number1=*number1+*number2; 
    }else{
      *number1=*number1+
	(((double)scaledpoints(*number2,unit2))/SCALEDPERPIXEL)/DEFAULTHSIZEPIX;
      strcpy(unit1,"%");
    }
  }else{      
    if(*unit2=='%'){
      *number1=*number2+
	(((double)scaledpoints(*number1,unit1))/SCALEDPERPIXEL)/DEFAULTHSIZEPIX;
      strcpy(unit1,"%");
    }else{ /* Both absolute. Return absolute scaled points.*/
      *number1=scaledpoints(*number1,unit1)+scaledpoints(*number2,unit2);
      strcpy(unit1,"sp");
      return 1; /* Absolute units */
    }
  }
  return 0; /* Percentage */
}


/***********************Color table following  color.pro of dvips ********/
#define N_COLORS 76
struct tth_ct { 
  char name[20];
  float cyan;
  float magenta;
  float yellow;
  float black;
} ;
struct tth_ct tth_colortable[N_COLORS] ={
 {"black",0,0,0,1},
 {"white",0,0,0,0},
 {"red",0,1.,1.,0},
 {"green",1.,0.,1.,0},
 {"blue",1.,1.,0.,0},
 {"cyan",1.,0,0,0},
 {"magenta",0,1,0,0},
 {"yellow",0,0,1.,0},
 {"GreenYellow",0.15,0,0.69,0},
 {"Yellow",0,0,1,0},
 {"Goldenrod",0,0.10,0.84,0},
 {"Dandelion",0,0.29,0.84,0},
 {"Apricot",0,0.32,0.52,0},
 {"Peach",0,0.50,0.70,0},
 {"Melon",0,0.46,0.50,0},
 {"YellowOrange",0,0.42,1,0},
 {"Orange",0,0.61,0.87,0},
 {"BurntOrange",0,0.51,1,0},
 {"Bittersweet",0,0.75,1,0.24},
 {"RedOrange",0,0.77,0.87,0},
 {"Mahogany",0,0.85,0.87,0.35},
 {"Maroon",0,0.87,0.68,0.32},
 {"BrickRed",0,0.89,0.94,0.28},
 {"Red",0,1,1,0},
 {"OrangeRed",0,1,0.50,0},
 {"RubineRed",0,1,0.13,0},
 {"WildStrawberry",0,0.96,0.39,0},
 {"Salmon",0,0.53,0.38,0},
 {"CarnationPink",0,0.63,0,0},
 {"Magenta",0,1,0,0},
 {"VioletRed",0,0.81,0,0},
 {"Rhodamine",0,0.82,0,0},
 {"Mulberry",0.34,0.90,0,0.02},
 {"RedViolet",0.07,0.90,0,0.34},
 {"Fuchsia",0.47,0.91,0,0.08},
 {"Lavender",0,0.48,0,0},
 {"Thistle",0.12,0.59,0,0},
 {"Orchid",0.32,0.64,0,0},
 {"DarkOrchid",0.40,0.80,0.20,0},
 {"Purple",0.45,0.86,0,0},
 {"Plum",0.50,1,0,0},
 {"Violet",0.79,0.88,0,0},
 {"RoyalPurple",0.75,0.90,0,0},
 {"BlueViolet",0.86,0.91,0,0.04},
 {"Periwinkle",0.57,0.55,0,0},
 {"CadetBlue",0.62,0.57,0.23,0},
 {"CornflowerBlue",0.65,0.13,0,0},
 {"MidnightBlue",0.98,0.13,0,0.43},
 {"NavyBlue",0.94,0.54,0,0},
 {"RoyalBlue",1,0.50,0,0},
 {"Blue",1,1,0,0},
 {"Cerulean",0.94,0.11,0,0},
 {"Cyan",1,0,0,0},
 {"ProcessBlue",0.96,0,0,0},
 {"SkyBlue",0.62,0,0.12,0},
 {"Turquoise",0.85,0,0.20,0},
 {"TealBlue",0.86,0,0.34,0.02},
 {"Aquamarine",0.82,0,0.30,0},
 {"BlueGreen",0.85,0,0.33,0},
 {"Emerald",1,0,0.50,0},
 {"JungleGreen",0.99,0,0.52,0},
 {"SeaGreen",0.69,0,0.50,0},
 {"Green",1,0,1,0},
 {"ForestGreen",0.91,0,0.88,0.12},
 {"PineGreen",0.92,0,0.59,0.25},
 {"LimeGreen",0.50,0,1,0},
 {"YellowGreen",0.44,0,0.74,0},
 {"SpringGreen",0.26,0,0.76,0},
 {"OliveGreen",0.64,0,0.95,0.40},
 {"RawSienna",0,0.72,1,0.45},
 {"Sepia",0,0.83,1,0.70},
 {"Brown",0,0.81,1,0.60},
 {"Tan",0.14,0.42,0.56,0},
 {"Gray",0,0,0,0.50},
 {"Black",0,0,0,1},
 {"White",0,0,0,0}
};

/********************************  Return a named color if it exists.*/
int tth_cmykcolor(ch,c,m,y,k)
char *ch;
float *c,*m,*y,*k;
{
extern struct tth_ct tth_colortable[N_COLORS];
int i;
  i=0;
  for(i=0;i<N_COLORS;i++){
    if(!strcmp(tth_colortable[i].name,ch)){
      *c=tth_colortable[i].cyan;
      *m=tth_colortable[i].magenta;
      *y=tth_colortable[i].yellow;
      *k=tth_colortable[i].black;
      return 4;
    }
  }
  return 0;
}


/************************************* 
Convert a symbol character 8859 reference into unicode point 
If the input string chsym is of length 1, just use its 8 bit code.
If not, try to read the first positive integer from it. 
If that fails, translate every character separately.
The returned value is a pointer to the global string chuni 
containing the unicode HTML numeric ref(s) on return.
*/

char tth_chuni[TTH_CHARLEN];

char* tth_symbol_point(chsym)
     char *chsym;
{
  /* this table is based on the test/symbols.html file of MathML*/
  /* It is used if the global tth_unicode == 1 */
char *tth_sympoint[256]={
/*0*/ "&nbsp;",/*1*/ "&nbsp;",/*2*/ "&nbsp;",/*3*/ "&nbsp;",
/*4*/ "&nbsp;",/*5*/ "&nbsp;",/*6*/ "&nbsp;",/*7*/ "&nbsp;",
/*8*/ "&nbsp;",/*9*/ "&nbsp;",/*10*/ "&nbsp;",/*11*/ "&nbsp;",
/*12*/ "&nbsp;",/*13*/ "&nbsp;",/*14*/ "&nbsp;",/*15*/ "&nbsp;",
/*16*/ "&nbsp;",/*17*/ "&nbsp;",/*18*/ "&nbsp;",/*19*/ "&nbsp;",
/*20*/ "&nbsp;",/*21*/ "&nbsp;",/*22*/ "&nbsp;",/*23*/ "&nbsp;",
/*24*/ "&nbsp;",/*25*/ "&nbsp;",/*26*/ "&nbsp;",/*27*/ "&nbsp;",
/*28*/ "&nbsp;",/*29*/ "&nbsp;",/*30*/ "&nbsp;",/*31*/ "&nbsp;",
/*32*/ "&#160;",/*33*/ "&#33;",/*34*/ "&#8704;",/*35*/ "&#35;",
/*36*/ "&#8707;",/*37*/ "&#37;",/*38*/ "&#38;",/*39*/ "&#8715;",
/*40*/ "&#40;",/*41*/ "&#41;",/*42*/ "&#8727;",/*43*/ "&#43;",
/*44*/ "&#44;",/*45*/ "&#8722;",/*46*/ "&#46;",/*47*/ "&#47;",
/*48*/ "&#48;",/*49*/ "&#49;",/*50*/ "&#50;",/*51*/ "&#51;",
/*52*/ "&#52;",/*53*/ "&#53;",/*54*/ "&#54;",/*55*/ "&#55;",
/*56*/ "&#56;",/*57*/ "&#57;",/*58*/ "&#58;",/*59*/ "&#59;",
/*60*/ "&#60;",/*61*/ "&#61;",/*62*/ "&#62;",/*63*/ "&#63;",
/*64*/ "&#8773;",/*65*/ "&#913;",/*66*/ "&#914;",/*67*/ "&#935;",
/*68*/ "&#8710;",/*69*/ "&#917;",/*70*/ "&#934;",/*71*/ "&#915;",
/*72*/ "&#919;",/*73*/ "&#921;",/*74*/ "&#977;",/*75*/ "&#922;",
/*76*/ "&#923;",/*77*/ "&#924;",/*78*/ "&#925;",/*79*/ "&#927;",
/*80*/ "&#928;",/*81*/ "&#920;",/*82*/ "&#929;",/*83*/ "&#931;",
/*84*/ "&#932;",/*85*/ "&#933;",/*86*/ "&#962;",/*87*/ "&#8486;",
/*88*/ "&#926;",/*89*/ "&#936;",/*90*/ "&#918;",/*91*/ "&#91;",
/*92*/ "&#8756;",/*93*/ "&#93;",/*94*/ "&#8869;",/*95*/ "&#95;",
/*96*/ "&#63717;",/*97*/ "&#945;",/*98*/ "&#946;",/*99*/ "&#967;",
/*100*/ "&#948;",/*101*/ "&#1013;",/*102*/ "&#981;",/*103*/ "&#947;",
/*104*/ "&#951;",/*105*/ "&#953;",/*106*/ "&#966;",/*107*/ "&#954;",
/*108*/ "&#955;",/*109*/ "&#956;",/*110*/ "&#957;",/*111*/ "&#959;",
/*112*/ "&#960;",/*113*/ "&#952;",/*114*/ "&#961;",/*115*/ "&#963;",
/*116*/ "&#964;",/*117*/ "&#965;",/*118*/ "&#982;",/*119*/ "&#969;",
/*120*/ "&#958;",/*121*/ "&#968;",/*122*/ "&#950;",/*123*/ "&#123;",
/*124*/ "&#124;",/*125*/ "&#125;",/*126*/ "&#8764;",/*127*/ "&nbsp;",
/*128*/ "&nbsp;",/*129*/ "&#949;",/*130*/ "&nbsp;",/*131*/ "&nbsp;",
/*132*/ "&nbsp;",/*133*/ "&nbsp;",/*134*/ "&nbsp;",/*135*/ "&nbsp;",
/*136*/ "&nbsp;",/*137*/ "&nbsp;",/*138*/ "&nbsp;",/*139*/ "&nbsp;",
/*140*/ "&nbsp;",/*141*/ "&nbsp;",/*142*/ "&nbsp;",/*143*/ "&nbsp;",
/*144*/ "&nbsp;",/*145*/ "&nbsp;",/*146*/ "&nbsp;",/*147*/ "&nbsp;",
/*148*/ "&nbsp;",/*149*/ "&nbsp;",/*150*/ "&nbsp;",/*151*/ "&nbsp;",
/*152*/ "&nbsp;",/*153*/ "&nbsp;",/*154*/ "&nbsp;",/*155*/ "&nbsp;",
/*156*/ "&nbsp;",/*157*/ "&nbsp;",/*158*/ "&nbsp;",/*159*/ "&nbsp;",
/*160*/ "&#8364;",/*161*/ "&#978;",/*162*/ "&#8242;",/*163*/ "&#8804;",
/*164*/ "&#8725;",/*165*/ "&#8734;",/*166*/ "&#402;",/*167*/ "&#9827;",
/*168*/ "&#9830;",/*169*/ "&#9829;",/*170*/ "&#9824;",/*171*/ "&#8596;",
/*172*/ "&#8592;",/*173*/ "&#8593;",/*174*/ "&#8594;",/*175*/ "&#8595;",
/*176*/ "&#176;",/*177*/ "&#177;",/*178*/ "&#8243;",/*179*/ "&#8805;",
/*180*/ "&#215;",/*181*/ "&#8733;",/*182*/ "&#8706;",/*183*/ "&#8226;",
/*184*/ "&#247;",/*185*/ "&#8800;",/*186*/ "&#8801;",/*187*/ "&#8776;",
/*188*/ "&#8230;",/*189*/ "&#63718;",/*190*/ "&#63719;",/*191*/ "&#8629;",
/*192*/ "&#8501;",/*193*/ "&#8465;",/*194*/ "&#8476;",/*195*/ "&#8472;",
/*196*/ "&#8855;",/*197*/ "&#8853;",/*198*/ "&#8709;",/*199*/ "&#8745;",
/*200*/ "&#8746;",/*201*/ "&#8835;",/*202*/ "&#8839;",/*203*/ "&#8836;",
/*204*/ "&#8834;",/*205*/ "&#8838;",/*206*/ "&#8712;",/*207*/ "&#8713;",
/*208*/ "&#8736;",/*209*/ "&#8711;",/*210*/ "&#63194;",/*211*/ "&#63193;",
/*212*/ "&#63195;",/*213*/ "&#8719;",/*214*/ "&#8730;",/*215*/ "&#8901;",
/*216*/ "&#172;",/*217*/ "&#8743;",/*218*/ "&#8744;",/*219*/ "&#8660;",
/*220*/ "&#8656;",/*221*/ "&#8657;",/*222*/ "&#8658;",/*223*/ "&#8659;",
/*224*/ "&#9674;",/*225*/ "&#9001;",/*226*/ "&#63720;",/*227*/ "&#63721;",
/*228*/ "&#63722;",/*229*/ "&#8721;",/*230*/ "&#63723;",/*231*/ "&#63724;",
/*232*/ "&#63725;",/*233*/ "&#63726;",/*234*/ "&#63727;",/*235*/ "&#63728;",
/*236*/ "&#63729;",/*237*/ "&#63730;",/*238*/ "&#63731;",/*239*/ "&#63732;",
/*240*/ "&nbsp;",/*241*/ "&#9002;",/*242*/ "&#8747;",/*243*/ "&#8992;",
/*244*/ "&#63733;",/*245*/ "&#8993;",/*246*/ "&#63734;",/*247*/ "&#63735;",
/*248*/ "&#63736;",/*249*/ "&#63737;",/*250*/ "&#63738;",/*251*/ "&#63739;",
/*252*/ "&#63740;",/*253*/ "&#63741;",/*254*/ "&#63742;",/*255*/ "&nbsp;"
};
  /* this table is based on Unicode 3.2*/
char *tth_sympoint2[256]={
/*0*/ "&nbsp;",/*1*/ "&nbsp;",/*2*/ "&nbsp;",/*3*/ "&nbsp;"
,/*4*/ "&nbsp;",/*5*/ "&nbsp;",/*6*/ "&nbsp;",/*7*/ "&nbsp;"
,/*8*/ "&nbsp;",/*9*/ "&nbsp;",/*10*/ "&nbsp;",/*11*/ "&nbsp;",
/*12*/ "&nbsp;",/*13*/ "&nbsp;",/*14*/ "&nbsp;",/*15*/ "&nbsp;",
/*16*/ "&nbsp;",/*17*/ "&nbsp;",/*18*/ "&nbsp;",/*19*/ "&nbsp;",
/*20*/ "&nbsp;",/*21*/ "&nbsp;",/*22*/ "&nbsp;",/*23*/ "&nbsp;",
/*24*/ "&nbsp;",/*25*/ "&nbsp;",/*26*/ "&nbsp;",/*27*/ "&nbsp;",
/*28*/ "&nbsp;",/*29*/ "&nbsp;",/*30*/ "&nbsp;",/*31*/ "&nbsp;",
/*32*/ "&#160;",/*33*/ "&#33;",/*34*/ "&#8704;",/*35*/ "&#35;",
/*36*/ "&#8707;",/*37*/ "&#37;",/*38*/ "&#38;",/*39*/ "&#8715;",
/*40*/ "&#40;",/*41*/ "&#41;",/*42*/ "&#8727;",/*43*/ "&#43;",
/*44*/ "&#44;",/*45*/ "&#8722;",/*46*/ "&#46;",/*47*/ "&#47;",
/*48*/ "&#48;",/*49*/ "&#49;",/*50*/ "&#50;",/*51*/ "&#51;",
/*52*/ "&#52;",/*53*/ "&#53;",/*54*/ "&#54;",/*55*/ "&#55;",
/*56*/ "&#56;",/*57*/ "&#57;",/*58*/ "&#58;",/*59*/ "&#59;",
/*60*/ "&#60;",/*61*/ "&#61;",/*62*/ "&#62;",/*63*/ "&#63;",
/*64*/ "&#8773;",/*65*/ "&#913;",/*66*/ "&#914;",/*67*/ "&#935;",
/*68*/ "&#8710;",/*69*/ "&#917;",/*70*/ "&#934;",/*71*/ "&#915;",
/*72*/ "&#919;",/*73*/ "&#921;",/*74*/ "&#977;",/*75*/ "&#922;",
/*76*/ "&#923;",/*77*/ "&#924;",/*78*/ "&#925;",/*79*/ "&#927;",
/*80*/ "&#928;",/*81*/ "&#920;",/*82*/ "&#929;",/*83*/ "&#931;",
/*84*/ "&#932;",/*85*/ "&#933;",/*86*/ "&#962;",/*87*/ "&#8486;",
/*88*/ "&#926;",/*89*/ "&#936;",/*90*/ "&#918;",/*91*/ "&#91;",
/*92*/ "&#8756;",/*93*/ "&#93;",/*94*/ "&#8869;",/*95*/ "&#95;",
/*96*/ "&#x02C9;",/*97*/ "&#945;",/*98*/ "&#946;",/*99*/ "&#967;",
/*100*/ "&#948;",/*101*/ "&#1013;",/*102*/ "&#981;",/*103*/ "&#947;",
/*104*/ "&#951;",/*105*/ "&#953;",/*106*/ "&#966;",/*107*/ "&#954;",
/*108*/ "&#955;",/*109*/ "&#956;",/*110*/ "&#957;",/*111*/ "&#959;",
/*112*/ "&#960;",/*113*/ "&#952;",/*114*/ "&#961;",/*115*/ "&#963;",
/*116*/ "&#964;",/*117*/ "&#965;",/*118*/ "&#982;",/*119*/ "&#969;",
/*120*/ "&#958;",/*121*/ "&#968;",/*122*/ "&#950;",/*123*/ "&#123;",
/*124*/ "&#124;",/*125*/ "&#125;",/*126*/ "&#8764;",/*127*/ "&nbsp;",
/*128*/ "&nbsp;",/*129*/ "&#949;",/*130*/ "&nbsp;",/*131*/ "&nbsp;",
/*132*/ "&nbsp;",/*133*/ "&nbsp;",/*134*/ "&nbsp;",/*135*/ "&nbsp;",
/*136*/ "&nbsp;",/*137*/ "&nbsp;",/*138*/ "&nbsp;",/*139*/ "&nbsp;",
/*140*/ "&nbsp;",/*141*/ "&nbsp;",/*142*/ "&nbsp;",/*143*/ "&nbsp;",
/*144*/ "&nbsp;",/*145*/ "&nbsp;",/*146*/ "&nbsp;",/*147*/ "&nbsp;",
/*148*/ "&nbsp;",/*149*/ "&nbsp;",/*150*/ "&nbsp;",/*151*/ "&nbsp;",
/*152*/ "&nbsp;",/*153*/ "&nbsp;",/*154*/ "&nbsp;",/*155*/ "&nbsp;",
/*156*/ "&nbsp;",/*157*/ "&nbsp;",/*158*/ "&nbsp;",/*159*/ "&nbsp;",
/*160*/ "&#8364;",/*161*/ "&#978;",/*162*/ "&#8242;",/*163*/ "&#8804;",
/*164*/ "&#8725;",/*165*/ "&#8734;",/*166*/ "&#402;",/*167*/ "&#9827;",
/*168*/ "&#9830;",/*169*/ "&#9829;",/*170*/ "&#9824;",/*171*/ "&#8596;",
/*172*/ "&#8592;",/*173*/ "&#8593;",/*174*/ "&#8594;",/*175*/ "&#8595;",
/*176*/ "&#176;",/*177*/ "&#177;",/*178*/ "&#8243;",/*179*/ "&#8805;",
/*180*/ "&#215;",/*181*/ "&#8733;",/*182*/ "&#8706;",/*183*/ "&#8226;",
/*184*/ "&#247;",/*185*/ "&#8800;",/*186*/ "&#8801;",/*187*/ "&#8776;",
/*188*/ "&#8230;",/*189*/ "&#x2502;",/*190*/ "&#x2015;",/*191*/ "&#8629;",
/*192*/ "&#8501;",/*193*/ "&#8465;",/*194*/ "&#8476;",/*195*/ "&#8472;",
/*196*/ "&#8855;",/*197*/ "&#8853;",/*198*/ "&#8709;",/*199*/ "&#8745;",
/*200*/ "&#8746;",/*201*/ "&#8835;",/*202*/ "&#8839;",/*203*/ "&#8836;",
/*204*/ "&#8834;",/*205*/ "&#8838;",/*206*/ "&#8712;",/*207*/ "&#8713;",
/*208*/ "&#8736;",/*209*/ "&#8711;",/*210*/ "&#x00Ae;",/*211*/ "&#x00A9;",
/*212*/ "&#x2122;",/*213*/ "&#8719;",/*214*/ "&#8730;",/*215*/ "&#8901;",
/*216*/ "&#172;",/*217*/ "&#8743;",/*218*/ "&#8744;",/*219*/ "&#8660;",
/*220*/ "&#8656;",/*221*/ "&#8657;",/*222*/ "&#8658;",/*223*/ "&#8659;",
/*224*/ "&#9674;",/*225*/ "&#9001;",/*226*/ "&#x00Ae;",/*227*/ "&#x00A9;",
/*228*/ "&#x2122;",/*229*/ "&#8721;",/*230*/ "&#x239B;",/*231*/ "&#x239C;",
/*232*/ "&#x239D;",/*233*/ "&#x23A1;",/*234*/ "&#x23A2;",/*235*/ "&#x23A3;",
/*236*/ "&#x23A7;",/*237*/ "&#x23A8;",/*238*/ "&#x23A9;",/*239*/ "&#x23AA;",
/*240*/ "&nbsp;",/*241*/ "&#9002;",/*242*/ "&#8747;",/*243*/ "&#8992;",
/*244*/ "&#x23AE;",/*245*/ "&#8993;",/*246*/ "&#x239E;",/*247*/ "&#x239F;",
/*248*/ "&#x23A0;",/*249*/ "&#x23A4;",/*250*/ "&#x23A5;",/*251*/ "&#x23A6;",
/*252*/ "&#x23AB;",/*253*/ "&#x23AC;",/*254*/ "&#x23AD;",/*255*/ "&nbsp;"
};
 int i=-1,j=0;
 if(strlen(chsym)==1){
   i=(int)*(chsym);
   if(i<0)i=i+256;
   strcpy(tth_chuni,(tth_unicode==1 ? tth_sympoint[i] : tth_sympoint2[i]));
 }else{
   if(sscanf(chsym+strcspn(chsym,"0123456789"),"%d",&i)){
     if(i>=0 && i<256) {
       strcpy(tth_chuni,(tth_unicode==1 ? tth_sympoint[i] : tth_sympoint2[i]));
     }else {i=-1;}
   }
   if(i==-1){
     j=0;
     *tth_chuni=0;
     while(strlen(chsym+j)){
       i=(int)*(chsym+j++);
       if(i<0)i=i+256;
       strcat(tth_chuni,(tth_unicode==1 ? tth_sympoint[i] : tth_sympoint2[i]));
     }
   }
 }
 return tth_chuni;
}
/*************************************/
void tagpurge(eqstr)
     char *eqstr;
{
  char *position;
  char eqpurge[4*TTH_DLEN];
  int len;
/*    fprintf(stderr,"Title Purging %s\n",eqstr); */
  position=eqstr;
  *eqpurge=0;
  while(position<eqstr+strlen(eqstr)){
    len=strcspn(position,"<");
    strncat(eqpurge,position,len);
    position=position+len;
    position=position+strcspn(position,">")+1;
  }
  strcpy(eqstr,eqpurge);
/*    fprintf(stderr,"Purged %s\n",eqstr); */
}

/**End of TtH**/
