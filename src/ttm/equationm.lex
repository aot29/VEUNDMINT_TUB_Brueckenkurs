<equation>\\lefteqn {
  if(!eqalignrow) mkkey(eqstr,eqstrs,&eqdepth);       /* Start new row */
  if(tth_istyle)eqalignrow=eqalignrow+6*(levhgt[eqclose]-1)+TTH_HGT;else
    eqalignrow=eqalignrow+levhgt[eqclose];
  levhgt[eqclose]=1; /* new */
  TTH_TEX_FN("{#1}\\tth_lefteq#tthdrop1",1);
}

<equation>\\stackrel   {
  mtrx[0]=0; /* This is a null op to silence a warning. */
  TTH_TEX_FN("{\\buildrel{#1}\\over{#2}}#tthdrop2",2);
}

<equation>{NL}  TTH_CHECK_LENGTH;  tth_num_lines++;

<equation>\\cr(cr)?{WSP}*\}  {
  if(*halstring){ /* halign and tabular */
    TTH_SCAN_STRING("\\tth_halcr}");
  }else{
    if(strcspn(yytext,"\n") < strlen(yytext)) tth_num_lines++;
    unput('}');
  }
} /* see also at \begin{array} = \matrix */

 /* Version that uses tabular code: */
<equation>\\end\{array\}  TTH_SCAN_STRING("\\end{tabular}");

<equation>\\end\{eqnarray\*?\} {
  if(tth_debug&2)fprintf(stderr,"end eqnarray, eqdepth=%d, eqclose=%d, tth_multinum=%d, eqalignlog=%d.\n",eqdepth,eqclose,tth_multinum,eqalignlog);
  TTH_SCAN_STRING("}}\\tth_endeqnarray"); 
}
<equation>\\nonumber  if(eqalignlog <= 100) eqalignlog=eqalignlog+100;
<equation,exptokarg>\\mathrm  TTH_SWAP("\\rm ");
<equation,exptokarg>\\boldsymbol |
<equation,exptokarg>\\mathbf  TTH_SWAP("\\bf ");
<equation,exptokarg>\\mathit   TTH_SWAP("\\it ");
<equation,exptokarg>\\mathcal  TTH_SWAP("\\it ");
<equation,exptokarg>\\mathtt   TTH_SWAP("\\tt ");
<equation,exptokarg>\\mathsf   TTH_SWAP("\\sffamily ");
<equation>\\mit{SP}*
<equation>\\ifmmode{WSP}* 
<equation>\\iff TTH_MATHO("&Leftrightarrow;");

<equation>&   {
  if(*halstring) {yy_push_state(hamper); /* halign */
  }else{ yy_push_state(mamper);
  }
 }
<mamper>{WSP} 
<mamper>{ANY}  {  
  yyless(0);yy_pop_state();
  tth_enclose(TTH_EQA1,eqstr,TTH_EQA2,eqstore);
  strcat(eqstr,TTH_EQA3);
  if(eqaligncell) {
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
  }
  mkkey(eqstr,eqstrs,&eqdepth);
  *eqstr=0;
  eqaligncell++;
}
<equation,mamper>\\multispan   TTH_TEX_FN("\\tthemultispan{#1}#tthdrop1",1);
<equation,mamper>\\multicolumn   TTH_TEX_FN("\\tthemultispan{#1}#tthdrop2",2);
  /*  interior in array */
<mamper>\\tthemultispan\{[0-9]+\} {
  yy_pop_state();  
  chscratch=strstr(yytext,"multi");
  TTH_CCPY(argchar,chscratch+strcspn(chscratch,"{")+1);
  *(argchar+strcspn(argchar,"}"))=0;
  tth_enclose(TTH_EQA1,eqstr,TTH_EQA2,eqstore);
  sprintf(eqstr+strlen(eqstr),"%s\"%s\"%s\n",TTH_EQA4,argchar,">");
  if(eqaligncell) {
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
  }
  mkkey(eqstr,eqstrs,&eqdepth);
  *eqstr=0;
  eqaligncell++;
 }
<equation>\\tthemultispan\{[0-9]+\} { /* line start in array */
  chscratch=strstr(yytext,"multi");
  TTH_CCPY(argchar,chscratch+strcspn(chscratch,"{")+1);
  *(argchar+strcspn(argchar,"}"))=0;
  sscanf(argchar,"%d",&colspan);
 }
<mamper>\\[a-zA-Z@]+   { /* expand first */
  TTH_DO_MACRO
  else{
    yyless(0);yy_pop_state();
    tth_enclose(TTH_EQA1,eqstr,TTH_EQA2,eqstore);
    strcat(eqstr,TTH_EQA3);
    if(eqaligncell) {
      tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
      rmkey(eqstrs,&eqdepth);
    }
    mkkey(eqstr,eqstrs,&eqdepth);
    *eqstr=0;
    eqaligncell++;
  }
}
<equation>\\noalign  { /* Ought probably to switch out of equation mode.*/
  if(!eqalignrow) mkkey(eqstr,eqstrs,&eqdepth);       /* Start new row */
  /* eqalignrow++; old */
  if(tth_istyle)eqalignrow=eqalignrow+6*(levhgt[eqclose]-1)+TTH_HGT;else
    eqalignrow=eqalignrow+levhgt[eqclose];
  levhgt[eqclose]=1; /* new */
  strcpy(eqstr,TTH_NOALIGN); /* add codes to span cells.*/
  TTH_TEX_FN("{#1}\\tth_eqfin#tthdrop1",1);
}
<equation>\\\\\*?{SP}*(\[[^\]]*\])? | /* Was later. */
<equation>\\tth_cr |
<equation>\\cr(cr)? {  
  if(eqclose && active[eqclose-1]){ 
    /* If this is really an array-type environment. */
    if(tth_debug&16)fprintf(stderr,
	"Active tth_cr. eqclose=%d, active=%d\n",eqclose,active[eqclose-1]);
    tth_enclose(TTH_EQA1,eqstr,TTH_EQA2,eqstore);  
    if(tth_debug&16)fprintf(stderr,
   "TTH_CR, eqalignlog=%d, colspan=%d, envirchar=%s, tth_multinum=%d, tth_LaTeX=%d.\n",
			   eqalignlog,colspan,envirchar,tth_multinum,tth_LaTeX);
    if(eqaligncell){ /* If there is a preceding & (cell) prefix it. */
      tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
      rmkey(eqstrs,&eqdepth);
    }
    /* If this row is in an eqalign or is not the first.*/
    if(eqalignlog||eqalignrow){
      sprintf(eqchar,"<mtr><mtd columnalign=\"%s\" columnspan=\"%d\">",
	      (lefteq ? "left":(eqalignlog ?"right":"center")),colspan);
      tth_prefix(eqchar,eqstr,eqstore); /* Prefix its opening */
      *eqchar=0;
    }
    if(eqalignrow){                     /* If this row is not the first.*/
      tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore); /* Prefix previous row */
      rmkey(eqstrs,&eqdepth);
    }
    if(tth_LaTeX && tth_multinum && strlen(envirchar) && (eqalignlog==1) ){
      strcat(eqstr,"</mtd><mtd columnalign=\"right\">");
      strcat(eqstr,"&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;");
      strcpy(scratchstring,"(\\theequation)");
    }else *scratchstring=0;
    strcat(scratchstring,"\\tth_closerow");
    TTH_SCAN_STRING(scratchstring);
  }else if(*halstring){ /* halign and tabular */
    TTH_SCAN_STRING("\\tth_halcr");
  }else{
    fprintf(stderr,"**** Improper \\\\ or \\cr outside array environment ignored, Line ~%d.\n",tth_num_lines);
  }
}
<equation>\\tth_closerow {
  if(tth_LaTeX && tth_multinum && strlen(envirchar) && (eqalignlog==1) ){
    equatno++;sprintf(envirchar,"%d",equatno);tth_multinum++;
  }
  strcat(eqstr,"</mtd></mtr>\n"); /* Close the row */
  *eqchar=0;
  mkkey(eqstr,eqstrs,&eqdepth);     /* Start new row */
  *eqstr=0;
  eqalignrow++;
  eqaligncell=0;
  lefteq=0;
  colspan=1;
  if(eqalignlog >= 100) eqalignlog=eqalignlog-100;
}

<equation,textbox>\{ {
  if(tth_debug&16) {
    fprintf(stderr,"Start Group {, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s.\n",eqdepth,eqclose,tth_flev,levdelim[eqclose]);
  }
  if(tth_flev < 0) tth_flev=tth_flev-99;
   mkkey(eqstr,eqstrs,&eqdepth);
   *eqstr=0;
   eqclose++;
   tophgt[eqclose]=0;
   levhgt[eqclose]=1;
   TTH_PUSH_CLOSING;
   /* Fixing subpscripts on a \left operator. Hope it does not break too much*/
   *scratchstring=0;
   TTH_SUBDEFER(scratchstring);
 }

<equation,textbox>\} { /* Could be the closure of various things. Hence complicated.*/
  TTH_TEXCLOSE else{
  if(active[eqclose-1] == 10) { /* Matrix closure */
    TTH_SCAN_STRING("\\tth_cr}");    /* Assume that there was NO final cr */
    active[eqclose-1]=11;
  }else{
  do{
  if(tth_debug&16) {
    if(active[eqclose]) 
    {fprintf(stderr,
         "Active Group }, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s, active=%d\n"
	     ,eqdepth,eqclose,tth_flev,levdelim[eqclose],active[eqclose]);}
    else fprintf(stderr,
	    "Close Group }, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s\n"
	    ,eqdepth,eqclose,tth_flev,levdelim[eqclose]);
  }
  if(active[eqclose-1] == 11) {
    if(tth_debug&16) fprintf(stderr,"Matrix close %d, levhgt=%d, rows=%d\n",
			    eqclose,levhgt[eqclose],eqalignrow);
    levhgt[eqclose]=levhgt[eqclose]+eqalignrow;
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
    if(eqalignlog){
      if(tth_debug&32)fprintf(stderr,"eqstr=%s\n",eqstr);
      tth_enclose(TTH_EQ3,eqstr,TTH_EQ2,eqstore);
    }else{
      tth_enclose(TTH_EQ1,eqstr,TTH_EQ2,eqstore);
    }
    TTH_EQA_POP;
    TTH_HAL_POP; /* Jun 2001 */
    /* Enclose unless this is the end of an eqalign type construct. */
    if(eqaind || !eqalignlog)tth_enclose(TTH_CELL5,eqstr,TTH_CELL5,eqstore);
    /* tth_enclose(TTH_CELL5,eqstr,TTH_CELL5,eqstore); */
    active[eqclose-1]=0;
  }
/* box closure
  if(active[eqclose-1]==20){ 
    if(tth_debug&16) fprintf(stderr,"Box closure, eqclose=%d\n",eqclose);
    active[eqclose-1]=0;
    yy_pop_state();
    TTH_OUTPUT(TTH_TEXTBOX2); 
  } textbox state end */
  if(active[eqclose-1]==40){ /* end with a r-paren. choose. */
    levdelim[eqclose][0]=')';
    eqclose--;
    active[eqclose]=0;
  }
  if(tophgt[eqclose] != 0){ /* If fraction */
    if(tth_debug&16)fprintf(stderr,"Fraction closing.\n");
    tth_enclose(TTH_LEV1,eqstr,TTH_LEV2,eqstore);
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
    TTH_CLOSEGROUP;TTH_POP_CLOSING; /* put closing before cell end */
    if(active[eqclose-1]!=30){
      tth_enclose(TTH_CELL1,eqstr,TTH_CELL2,eqstore);
    }
  }else {
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
  }
  if(eqclose > tth_flev) hgt=1; else hgt=tophgt[eqclose]+levhgt[eqclose];
  if(levhgt[eqclose-1] < hgt) levhgt[eqclose-1]=hgt;
  /* Delimiters in levdelim,i, and i+1.*/
  if(levdelim[eqclose][0]) 
    sprintf(eqchar,"<mrow>%s%s%s",TTH_MO,levdelim[eqclose],TTH_MOC);
  else   if(levdelim[eqclose+1][0]) strcpy(eqchar,"<mrow>");
  if(levdelim[eqclose+1][0]) 
    sprintf(eqchar2,"%s%s%s</mrow>",TTH_MO,levdelim[eqclose+1],TTH_MOC);
  else   if(levdelim[eqclose][0]) strcpy(eqchar2,"</mrow>");
  tth_enclose(eqchar,eqstr,eqchar2,eqstore);
  *eqchar=0;
  *eqchar2=0;
  if(active[eqclose-1]==30){ /* eqlimited section for mathop, overbrace */
    if(tth_debug&2)fprintf(stderr,"Mathop eqlimited:%s\n",eqstr);
    if(strlen(eqlimited)+strlen(eqstr)< TTH_DLEN) {
      strcat(eqlimited,eqstr);
      *eqstr=0;
    }else{
      fprintf(stderr,
          "Error: Fatal! Exceeded eqlimited storage. Over/underbrace too long.\n");
      TTH_EXIT(5);
    }
    yy_push_state(getsubp);
    if(levhgt[eqclose] == 1)levhgt[eqclose]=2; /* Force fraction closure */
    active[eqclose-1]=0;
  }else{
    if((tophgt[eqclose] != 0 || levdelim[eqclose+1][0]) && eqclose <= tth_flev){
      if(tth_debug&16)fprintf(stderr,"Fenced built-up close brace\n");
      /* if(eqclose <= tth_flev) Removed Oct 31*/
	yy_push_state(getsubp); 
    }else{
      	yy_push_state(getsubp);
	/*	test of universal getsubp */
      /*        tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore); 
		rmkey(eqstrs,&eqdepth); */
    }
  }
  *levdelim[eqclose]=0;
  *levdelim[eqclose+1]=0;
  if(tth_flev <  0) tth_flev=tth_flev+99;
  active[eqclose]=0;
  eqclose--;
  if(eqclose < 0) {
    fprintf(stderr,"**** Error! Fatal! Negative closure count, line:%d\n",tth_num_lines);
    TTH_EXIT(4);
  }
  } while (active[eqclose]);
  }
  if(tth_debug&16) fprintf(stderr,
   "Completing Close Group, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s\n"
	    ,eqdepth,eqclose,tth_flev,levdelim[eqclose]);
  }
}

<equation>\$\$ {  /* Cope with ambiguous style at equation end */
  if(displaystyle){
    if(tth_debug&2)fprintf(stderr,"$$ in displaystyle\n");
    TTH_SCAN_STRING("}\\tth_endequation");
  }else{
    yyless(1);
    TTH_SCAN_STRING("}\\tth_endinline");
  }
 }

<equation>\\tth_endinline {
  TTH_TEXCLOSE else{
    if(tth_debug&2) fprintf(stderr,"Leaving inline eq, eqclose=%d, eqdepth=%d, tth_flev=%d, levhgt=%d, tophgt=%d\n",  
	      eqclose,eqdepth,tth_flev,levhgt[eqclose],tophgt[eqclose]);
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
    if(eqdepth==1){
      tth_enclose(TTH_TSTY1,eqstr,TTH_TSTY2,eqstore);
      if(tth_tagpurge){
	tagpurge(eqstr);
	tth_tagpurge=0;
      }
      fprintf(tth_fdout,"%s",eqstr);
      eqdepth--;
      tth_flev=tth_flev0;
    }else{
      if(displaystyle)displaystyle--;
      eqdepth--;
      /*fprintf(stderr,
	  "**** Danger: Abnormal eqdepth %d on equation exit, line %d\n",
	  eqdepth,tth_num_lines);*/
      if(tth_debug&2)fprintf(stderr,
	  "Equation in a textbox inside an equation.\n");
      TTH_OUTPUT(TTH_TEXTBOX1);
    }
    yy_pop_state();
    horizmode=1;
  }
}
 /* Force all equations to end enclosed. */
<equation>\\end\{equation\*?\} { 
  if(strstr(yytext,"*")==NULL){    /* end{equation} */
    if(tth_multinum < 2) { 
      TTH_SCAN_STRING("}\\tth_numbereq");
    }else {
      /* end of equation which needs to unincrement*/
      equatno--;
      TTH_SCAN_STRING("}\\tth_endequation");
    }
  }else {TTH_SCAN_STRING("}\\tth_endequation");} /* embracing essential */
}
<equation>\\end\{displaymath\} |
<equation>\\\]     TTH_SCAN_STRING("}\\tth_endequation");

<equation>\\tth_numbereq {
      strcat(eqstr,TTH_DISP3);
      TTH_SCAN_STRING("(\\theequation)\\tth_endnumbered");
}
<equation>\\tth_endeqnarray  equatno--;TTH_SCAN_STRING("\\tth_endequation");
<equation>\\tth_endequation |     
<equation>\\tth_endnumbered {
  TTH_TEXCLOSE else{
  eqaligncell=0;
  if(tth_debug&2) fprintf(stderr,"End equation %d, %s\n",equatno,yytext);
  if(tth_multinum)tth_multinum=1;
  {
    if(strstr(yytext,"numb")){
      tth_enclose(TTH_DISP1,eqstr,TTH_DISP4,eqstore);
    }else tth_enclose(TTH_DISP1,eqstr,TTH_DISP2,eqstore);
    yy_pop_state();
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
    fprintf(tth_fdout,"%s",eqstr);
    tth_flev=tth_flev0; /* Necessary if textstyle has been used. */
    horizmode=1; /* Make sure we now recognize \n\n */
    if(tth_debug&2) fprintf(stderr,
       "Leaving display eq, eqclose=%d, eqdepth=%d, tth_flev=%d\n",  
         eqclose,eqdepth,tth_flev);
    if(eqdepth==1){
      eqdepth--;
    }else{
      fprintf(stderr,
   "**** Error: Fatal Abnormal eqdepth %d on display equation exit, line %d\n",
	      eqdepth,tth_num_lines);TTH_EXIT(2);
    }
    if(eqclose > 0) { 
      fprintf(stderr,
    "**** Error: Fatal Abnormal eqclose %d on Display Equation End, line %d\n",
	      eqclose,tth_num_lines);TTH_EXIT(3);
    }
    fprintf(tth_fdout,"\n");
    displaystyle=0;
    *environment=0;
    eqalignlog=0;
  }
  }
}
 /* Fears about mathml differences.
<equation>\\end\{displaymath\} |
<equation>\\end\{equation\*?\} |
<equation>\\\]              {  In this
    tth_enclose(TTH_LEV1,eqstr,TTH_LEV2,eqstore);  mathml always enclose*/

 /* Single character fractions. Removed from ml*/

<equation>{WSP}+\\(over|above|atop|choose) {
  yyless(strspn(yytext," \t\r\n"));
  if(strstr(yytext,"\n") != NULL) tth_num_lines++;
}
<equation>\\(over|above|atop|choose) {
  if(tth_debug&16)fprintf(stderr,
	  "Over Close Group, depth=%d, eqclose=%d, levhgt=%d\n",
	  eqdepth,eqclose,levhgt[eqclose]);
  tth_enclose(TTH_LEV1,eqstr,TTH_LEV2,eqstore);
  if((strstr(yytext,"atop") != NULL) || (strstr(yytext,"choose") != NULL)  )
    tth_enclose(TTH_CHOOSE,eqstr,TTH_ATOP,eqstore);
  else tth_enclose(TTH_FRAC,eqstr,TTH_DIV,eqstore);
  mkkey(eqstr,eqstrs,&eqdepth);
  *eqstr=0;
  tophgt[eqclose]=levhgt[eqclose]+1;
  levhgt[eqclose]=1; 
  if(strstr(yytext,"choose")){
    strcat(levdelim[eqclose],"(");
    active[eqclose]=40;
    eqclose++;
  }    
 } 
 /* End of Fraction*/

 /* Sub/p scripts. */
<equation>\^		{
  strcat(eqstr,TTH_SUP1);yy_push_state(exptokarg);
  TTH_CCPY(expchar,TTH_SUP2);
  }
<equation>\_		{
  strcat(eqstr,TTH_SUB1);yy_push_state(exptokarg);
  TTH_CCPY(expchar,TTH_SUB2);
  }
 /* Version that does not use tabular code:
<equation>\\begin{WSP}*\{(array|tabular)\}(\[.\])?{WSP}*\{ {
  TTH_SCAN_STRING("\\matrix{\\tthdump{");  }
 */
 /* Version that uses tabular:*/
<equation>\\begin{WSP}*\{array\}(\[.\])? {
  TTH_SCAN_STRING("\\begin{tabular}");
}
<equation>\\eqalign(no)*{WSP}*\{	|
<equation>\\(border)?matrix{WSP}*\{ { /*border not really supported*/
  TTH_INC_MULTI;
  TTH_HAL_PUSH;*halstring=0;
  TTH_EQA_PUSH;
  if(strstr(yytext,"eq") != NULL) eqalignlog++;/*make both levels 1*/
  TTH_PUSH_CLOSING;
  if(strstr(yytext,"eq") == NULL) eqalignlog=0;
  /*if(strstr(yytext,"eq") != NULL) eqalignlog++; else eqalignlog=0;*/
  if(tth_debug&2) {
    fprintf(stderr,
     "Matrix {, eqdepth=%d, eqclose=%d, eqalignlog=%d, tth_flev=%d, levdelim=%s.\n"
	    ,eqdepth,eqclose,eqalignlog,tth_flev,levdelim[eqclose]);
  }
  mkkey(eqstr,eqstrs,&eqdepth);
  eqclose++;
  *eqstr=0;
  levhgt[eqclose]=1;
  tophgt[eqclose]=0;
  eqaligncell=0;
  eqalignrow=0;
  active[eqclose-1]=10;
 }
<equation>\\cases  {
  TTH_TEX_FN("\\left\\lbrace\\matrix{#1}\\right.#tthdrop1",1);
}
<equation>\\pmatrix {
  TTH_TEX_FN("\\left(\\matrix{#1}\\right)#tthdrop1",1);
}

 /* textboxes*/
<equation,exptokarg>\\raisebox\{[^\}]*\}({SP}?\[[^\]]*\]){0,2}{SP}* |
<equation,exptokarg>\\[hvmf]box{WSP}* |
<equation,exptokarg>\\textmd    |
<equation,exptokarg>\\textrm    |
<equation,exptokarg>\\textnormal {
  TTH_INC_MULTI;
  strcpy(scratchstring,"\\tth_tbone");strcat(scratchstring,"\\rm ");  TTH_SCAN_STRING("\\tth_tbox");
}
<equation,exptokarg>\\textbf  {
  strcpy(scratchstring,"\\tth_tbone");strcat(scratchstring,"\\bf ");  TTH_SCAN_STRING("\\tth_tbox");
}
<equation,exptokarg>\\textsl |
<equation,exptokarg>\\textit {
  strcpy(scratchstring,"\\tth_tbone");strcat(scratchstring,"\\it ");  TTH_SCAN_STRING("\\tth_tbox");
}
<equation,exptokarg>\\texttt {
  strcpy(scratchstring,"\\tth_tbone");strcat(scratchstring,"\\tt ");  TTH_SCAN_STRING("\\tth_tbox");
}
<equation,exptokarg>\\textsf {
  strcpy(scratchstring,"\\tth_tbone");strcat(scratchstring,"\\sffamily ");  TTH_SCAN_STRING("\\tth_tbox");
}
<equation,exptokarg>\\textsc {
  strcpy(scratchstring,"\\tth_tbone");strcat(scratchstring,"\\scshape ");  TTH_SCAN_STRING("\\tth_tbox");
}
<equation>\\tth_tbox {
  yy_push_state(textbox);
  TTH_SWAP(scratchstring);
/*    active[eqclose]=20; */
  TTH_PRETEXCLOSE("\\tth_boxclose");
}
<exptokarg>\\tth_tbox {
  yy_pop_state();
  yy_push_state(textbox);
  yy_push_state(exptokarg);
  TTH_SWAP(scratchstring);
/*    active[eqclose]=20; */
  TTH_PRETEXCLOSE("\\tth_boxclose");
}
<equation,textbox>\\tth_boxclose  { /* box closure*/
    if(tth_debug&2) fprintf(stderr,"Box closure, eqclose=%d\n",eqclose);
    yy_pop_state(); /* textbox state end */
    /*      TTH_OUTPUT(TTH_TEXTBOX2); */ /*Alternative box end option */
  }
<equation,textbox>\\tth_tbone  {
  TTH_OUTPUT(TTH_TEXTBOX1);TTH_PRECLOSE(TTH_TEXTBOX2);
}
<equation,exptokarg,textbox>\\hbox{SP}+to {GET_DIMEN;} /* Override new handling */

<equation>\$            |
<equation>\\end\{math\} |
<equation>\\\)          {
  /* Ignore single $ in display equations or boxes.*/
  if(displaystyle==1){
    if(tth_debug&2)fprintf(stderr,"Inline inside displaystyle.\n");
  }else if(strstr(tth_texclose[tth_push_depth],"tth_boxclose")) {
/*   if(active[eqclose-1]==20) { */
    if(tth_debug&2) fprintf(stderr,"Inline inside box.\n");
  }else{
    TTH_SCAN_STRING("}\\tth_endinline");
  }
 }
		/* Math greek and symbols */
<equation>\\alpha{SP}*	|
<equation>\\beta{SP}*	|
<equation>\\gamma{SP}*	|
<equation>\\delta{SP}*	|
<equation>\\zeta{SP}*	|
<equation>\\eta{SP}*   	|
<equation>\\theta{SP}*	|
<equation>\\iota{SP}*	|
<equation>\\kappa{SP}*	|
<equation>\\lambda{SP}*	|
<equation>\\lambdar{SP}*	|
<equation>\\mu{SP}*     	|
<equation>\\nu{SP}*     	|
<equation>\\xi{SP}*     	|
<equation>\\pi{SP}*      |
<equation>\\rho{SP}*    	|
<equation>\\sigma{SP}*	|
<equation>\\tau{SP}*    	|
<equation>\\phi{SP}*    	|
<equation>\\chi{SP}*    	|
<equation>\\psi{SP}*    	|
<equation>\\omega{SP}*	|
<equation>\\Gamma{SP}*	|
<equation>\\Delta{SP}*	|
<equation>\\Theta{SP}*	|
<equation>\\Lambda	|
<equation>\\Xi{SP}*	|
<equation>\\Pi{SP}*     	|
<equation>\\Sigma{SP}*	|
<equation>\\Phi{SP}*    	|
<equation>\\Psi{SP}*    	|
<equation>\\Omega{SP}*  | 
<equation>\\aleph{SP}*  | 
<equation>\\imath{SP}*  | 
<equation>\\jmath{SP}*  | 
<equation>\\ell{SP}* {
  strcpy(scratchstring,yytext);
  strcpy((scratchstring+strcspn(scratchstring," \t")),";");
  *scratchstring='&';
  TTH_SUBDEFI(scratchstring);
}
<equation>\\epsilon{SP}*	TTH_SUBDEFI("&epsi;");
<equation>\\varepsilon{SP}*	TTH_SUBDEFI("&epsiv;");
<equation>\\vartheta{SP}*   TTH_SUBDEFI("&thetav;");
<equation>\\varpi{SP}*	TTH_SUBDEFI("&piv;");
<equation>\\varrho{SP}*	TTH_SUBDEFI("&rhov;");
<equation>\\varsigma{SP}*	TTH_SUBDEFI("&sigmav;");
<equation>\\varphi{SP}*	TTH_SUBDEFI("&phiv;");
<equation>\\upsilon{SP}*	TTH_SUBDEFI("&upsi;");
<equation>\\Upsilon{SP}*	TTH_SUBDEFI("&Upsi;");
<equation>\\clubsuit{SP}*	TTH_SUBDEFI("&clubs;");
<equation>\\diamondsuit{SP}*	TTH_SUBDEFI("&diams;");
<equation>\\heartsuit{SP}*	TTH_SUBDEFI("&hearts;");
<equation>\\spadesuit{SP}*     TTH_SUBDEFI("&spades;");
<equation>\\emptyset{SP}* TTH_SUBDEFI("&empty;");


<equation>\\wp{SP}*  		TTH_MATHO("&weierp;");
<equation>\\cal{SP}*(R|\{R\}) |
<equation>\\Re{SP}*	TTH_MATHO("&real;");
<equation>\\cal{SP}*(I|\{I\}) |
<equation>\\Im{SP}*	TTH_MATHO("&Im;");
<equation>\\partial{SP}*	TTH_MATHO("&part;");
<equation>\\infty{SP}*        	TTH_MATHI("&infin;");
<equation>\\angle{SP}*         	TTH_MATHO("&angle;");
<equation>\\prime{SP}* |
<equation>\'{SP}*		TTH_MATHO("'");
<equation>\\surd{SP}* 	TTH_MATHO("&radic;");
<equation>\\backslash{SP}*     	TTH_MATHO("&bsol;");
<equation>\\exists{SP}*		TTH_MATHO("&exist;");
<equation>\\neg{SP}*    	TTH_MATHO("&not;");
<equation>\\\~{SP}*     	TTH_MATHO("&tilde;");
<equation>\<		TTH_MATHO("&lt;");
<equation>\>		TTH_MATHO("&gt;");
<equation>\\ll{SP}*	|
<equation>\<\<		TTH_MATHO(" &lt;&lt; ");
<equation>\\gg{SP}*	|
<equation>\>\>		TTH_MATHO("&gt;&gt;");
<equation>\\lor{SP}* 	TTH_MATHO("&or;");

<equation>\\perp{SP}*	TTH_MATHO("&bottom;");
<equation>\|  |
<equation>\\vert{SP}* 	TTH_SUBDEFONS("&verbar;")
<equation>\\\|           |
<equation>\\Vert{SP}* 	TTH_SUBDEFONS("&Verbar;")
<equation>\\sim{SP}*	TTH_MATHO("~") /* tilde doesn't work amaya */
 /* mo gave imbalanced delimiters defeat by surrounding.*/
<equation>\\cdot{SP}*	TTH_MATHO("&middot;")
<equation>\\wedge{SP}*	TTH_MATHO("&and;")
<equation>\\circ{SP}*	TTH_MATHO("&SmallCircle;")

     /* Entities called the same in mathml as in tex*/
<equation>\\mho{SP}*   |
<equation>\\Diamond{SP}*   |
<equation>\\triangle{SP}*   |
<equation>\\flat{SP}*   |
<equation>\\natural{SP}*   |
<equation>\\sharp{SP}*   |
<equation>\\nearrow{SP}*   |
<equation>\\searrow{SP}*   |
<equation>\\nwarrow{SP}*   |
<equation>\\swarrow{SP}*   |
<equation>\\rightleftharpoons{SP}*   |
<equation>\\longmapsto{SP}*   |
<equation>\\rightharpoonup{SP}*   |
<equation>\\rightharpoondown{SP}*   |
<equation>\\leftharpoonup{SP}*   |
<equation>\\leftharpoondown{SP}*   |
<equation>\\hookleftarrow{SP}*   |
<equation>\\hookrightarrow{SP}*   |
<equation>\\models{SP}*   |
<equation>\\mid{SP}*   |
<equation>\\bowtie{SP}*   |
<equation>\\smile{SP}*   |
<equation>\\frown{SP}*   |
<equation>\\doteq{SP}*   |
<equation>\\asymp{SP}*   |
<equation>\\vdash{SP}*   |
<equation>\\dashv{SP}*   |
<equation>\\sqsupset{SP}*   |
<equation>\\sqsubset{SP}*   |
<equation>\\sqsupseteq{SP}*   |
<equation>\\sqsubseteq{SP}*   |
<equation>\\wr{SP}*   |
<equation>\\amalg{SP}*   |
<equation>\\ddagger{SP}*   |
<equation>\\dagger{SP}*   |
<equation>\\succ{SP}*   |
<equation>\\succeq{SP}* |
<equation>\\prec{SP}*   |
<equation>\\preceq{SP}* |
<equation>\\nabla{SP}*  | 
<equation>\\parallel{SP}* |
<equation>\\rceil{SP}*   |
<equation>\\rfloor{SP}*  |
<equation>\\lceil{SP}*   |
<equation>\\lfloor{SP}*  |
<equation>\\setminus{SP}* |
<equation>\\forall{SP}*	|
<equation>\\ni{SP}*  |
<equation>\\cong{SP}*  |
<equation>\\equiv{SP}*	|
<equation>\\top{SP}*    |
<equation>\\bot{SP}* 	|
<equation>\\ast{SP}*	|
<equation>\\star{SP}*	|
<equation>\\bullet{SP}*     	|
<equation>\\o?i?i?int{SP}* 	|
<equation>\\cup{SP}* 	|
<equation>\\cap{SP}* 	|
<equation>\\mp{SP}*	|
<equation>\\vee{SP}*	|
<equation>\\lan{SP}*	|
<equation>\\oplus{SP}*	|
<equation>\\otimes{SP}*	|
<equation>\\oslash{SP}*	{
  strcpy(scratchstring,yytext);
  strcpy((scratchstring+strcspn(scratchstring," \t")),";");
  *scratchstring='&';
  TTH_SUBDEFO(scratchstring);
}

  /* Unicode form that mozilla understands (maybe not).
<equation>\\succ{SP}*   TTH_MATHO("&#x227B;");
<equation>\\succeq{SP}* TTH_MATHO("&#x227D;");
<equation>\\prec{SP}*   TTH_MATHO("&#x227A;");
<equation>\\preceq{SP}* TTH_MATHO("&#x227C;");*/

<equation>\\pmod |     /* Incorrect for now; needs parens.*/
<equation>\\bmod{SP}*	TTH_SUBDEFO("mod");
<equation>\\div{SP}*  	TTH_MATHO("&divide;");
<equation>\\times{SP}*		TTH_MATHO("&times;"); 
<equation>\\le(ss)?sim{SP}*		TTH_MATHO("&lt;~"); 
<equation>\\g(e|tr)sim{SP}*		TTH_MATHO("&gt;~"); 

<equation>\\leq{SP}*  |
<equation>\\le{SP}*	TTH_MATHO("&le;");
<equation>\\geq{SP}*  |
<equation>\\ge{SP}*	TTH_MATHO("&ge;");
<equation>\\approx{SP}*	TTH_MATHO("&ap;");
<equation>\\not{SP}*={SP}*        |
<equation>\\neq{SP}*	|
<equation>\\ne{SP}*	TTH_MATHO("&ne;");
<equation>\\subset{SP}*	TTH_MATHO("&sub;");
<equation>\\subseteq{SP}*  TTH_MATHO("&sube;");
<equation>\\owns{SP}*    |
<equation>\\supset{SP}*	TTH_MATHO("&sup;");
<equation>\\supseteq{SP}*  TTH_MATHO("&supe;");
<equation>\\in{SP}*	TTH_MATHO("&isin;");
<equation>\\notin{SP}*	TTH_MATHO("&notin;");
<equation>\\simeq{SP}*  TTH_MATHO("&ap;");
<equation>\\propto{SP}*	TTH_MATHO("&prop;");
<equation>\\leftarrow   TTH_MATHO("&larr;");
<equation>\\longleftarrow   TTH_MATHO("&larr;");

   /* A slight kludge */
<equation>\\mapsto |
<equation>\\to  |
<equation>\\rightarrow	    TTH_MATHO("&rarr;");
<equation>\\longrightarrow  TTH_MATHO("&rarr;");
<equation>\\uparrow	    TTH_SUBDEFONS("&uarr;");
<equation>\\downarrow	    TTH_SUBDEFONS("&darr;");
<equation>\\updownarrow	    TTH_SUBDEFONS("&updownarrow;");
<equation>\\Updownarrow	    TTH_SUBDEFONS("&Updownarrow;");
<equation>\\longleftrightarrow |
<equation>\\leftrightarrow  TTH_MATHO("&leftrightarrow;");
<equation>\\Leftarrow	    TTH_MATHO("&lArr;");
<equation>\\Longleftarrow   TTH_MATHO("&lArr;");
<equation>\\Rightarrow	    TTH_MATHO("&rArr;");
<equation>\\Longrightarrow  TTH_MATHO("&rArr;");
<equation>\\RA		    
<equation>\\Longleftrightarrow TTH_MATHO("&Longleftrightarrow;");
<equation>\\Leftrightarrow  TTH_MATHO("&Leftrightarrow;");
<equation>\\Uparrow	    TTH_SUBDEFONS("&uArr;");
<equation>\\Downarrow	    TTH_SUBDEFONS("&dArr;");
<equation>\\pm{SP}*	TTH_MATHO("&PlusMinus;");
<equation>\\diamond{SP}*	TTH_MATHO("&loz;");
<equation>\\langle{SP}*	TTH_SUBDEFONS("&lang;");
<equation>\\rangle{SP}*	TTH_SUBDEFONS("&rang;");

 /* was mldr */
<equation>\\colon{SP}*	TTH_MATHO(":");
<equation>\\dotsb{SP}*	TTH_MATHO("&#x2026;");
<equation>\\dotsc{SP}*	TTH_MATHO("&#x2026;");
<equation>\\dotsi{SP}*	TTH_MATHO("&#x2026;");
<equation>\\l?dots{SP}*	TTH_MATHO("&#x2026;");
<equation>\\cdots{SP}*	TTH_MATHO("&#x2026;");
<equation>\\ddots{SP}*  TTH_MATHO("&dtdot;");
<equation>\\vdots{SP}*   TTH_OUTPUT(":");
<equation>\\atsign{SP}*		TTH_MATHI("@");

<equation>\\arccos{SP}*		TTH_MATHI("arccos");  
<equation>\\arcsin{SP}*		TTH_MATHI("arcsin");  
<equation>\\arctan{SP}*		TTH_MATHI("arctan");  
<equation>\\arg{SP}*		TTH_MATHI("arg");  
<equation>\\cos{SP}*		TTH_MATHI("cos");  
<equation>\\cosh{SP}*		TTH_MATHI("cosh");  
<equation>\\cot{SP}*		TTH_MATHI("cot");  
<equation>\\coth{SP}*		TTH_MATHI("coth");  
<equation>\\csc{SP}*		TTH_MATHI("csc");  
 /* <equation>\\deg{SP}*        TTH_MATHI("&deg;");  Incorrect TeX */
<equation>\\deg{SP}*		TTH_MATHI("deg");
<equation>\\dim{SP}*		TTH_MATHI("dim");  
<equation>\\exp{SP}*		TTH_MATHI("exp");  
<equation>\\hom{SP}*		TTH_MATHI("hom");  
<equation>\\ker{SP}*		TTH_MATHI("ker");  
<equation>\\lg{SP}*		TTH_MATHI("lg");  
<equation>\\ln{SP}*		TTH_MATHI("ln");  
<equation>\\log{SP}*		TTH_MATHI("log");  
<equation>\\sec{SP}*		TTH_MATHI("sec");  
<equation>\\sin{SP}*		TTH_MATHI("sin");  
<equation>\\sinh{SP}*		TTH_MATHI("sinh");  
<equation>\\tan{SP}*		TTH_MATHI("tan");   
<equation>\\tanh{SP}*		TTH_MATHI("tanh");  

<equation>\\prod{SP}*\\nolimits{SP}*  	TTH_SUBDEFO("&Pi;");
<equation>\\prod{SP}*(\\limits{SP}*)? {
    mkkey(eqstr,eqstrs,&eqdepth);  *eqstr=0; TTH_LIMITOP("<mo>&Pi;</mo>");
}
 /* Limited Symbols */
<equation>\\bigvee{SP}*(\\limits{SP}*)?  |
<equation>\\bigwedge{SP}*(\\limits{SP}*)? |
<equation>\\coprod{SP}*(\\limits{SP}*)?  |
<equation>\\bigcirc{SP}*(\\limits{SP}*)? |
<equation>\\odot{SP}*(\\limits{SP}*)? |
<equation>\\ominus{SP}*(\\limits{SP}*)? |
<equation>\\triangleright{SP}*(\\limits{SP}*)? |
<equation>\\triangleleft{SP}*(\\limits{SP}*)? |
<equation>\\bigtriangledown{SP}*(\\limits{SP}*)? |
<equation>\\bigtriangleup{SP}*(\\limits{SP}*)? |
<equation>\\uplus{SP}*(\\limits{SP}*)?  |
<equation>\\sqcap{SP}*(\\limits{SP}*)? |
<equation>\\sqcup{SP}*(\\limits{SP}*)?  |
<equation>\\bigcap{SP}*(\\limits{SP}*)? |
<equation>\\bigcup{SP}*(\\limits{SP}*)?  |
<equation>\\bigsqcup{SP}*(\\limits{SP}*)?  |
<equation>\\bigotimes{SP}*(\\limits{SP}*)? |
<equation>\\bigoplus{SP}*(\\limits{SP}*)? |
<equation>\\bigodot{SP}*(\\limits{SP}*)? |
<equation>\\biguplus{SP}*(\\limits{SP}*)? |
<equation>\\sum{SP}*(\\limits{SP}*)?  |
<equation>\\o?i?i?int{SP}*\\limits{SP}* 	|
<equation>\\Pr{SP}*(\\limits{SP}*)? {
  mkkey(eqstr,eqstrs,&eqdepth);  *eqstr=0;
  *(yytext+1+strcspn(yytext+1," \\"))=0;
  strcpy(scratchstring,"<mo>&");strcat(scratchstring,yytext+1);
  strcat(scratchstring,";</mo>");
  TTH_LIMITOP(scratchstring);
}
 /* NoLimited Symbols */
<equation>\\bigvee{SP}*\\nolimits{SP}*  |
<equation>\\bigwedge{SP}*\\nolimits{SP}* |
<equation>\\coprod{SP}*\\nolimits{SP}*  |
<equation>\\bigcirc{SP}*\\nolimits{SP}* |
<equation>\\odot{SP}*\\nolimits{SP}* |
<equation>\\ominus{SP}*\\nolimits{SP}* |
<equation>\\triangleright{SP}*\\nolimits{SP}* |
<equation>\\triangleleft{SP}*\\nolimits{SP}* |
<equation>\\bigtriangledown{SP}*\\nolimits{SP}* |
<equation>\\bigtriangleup{SP}*\\nolimits{SP}* |
<equation>\\uplus{SP}*\\nolimits{SP}*  |
<equation>\\sqcap{SP}*\\nolimits{SP}* |
<equation>\\sqcup{SP}*\\nolimits{SP}*  |
<equation>\\bigcap{SP}*\\nolimits{SP}* |
<equation>\\bigcup{SP}*\\nolimits{SP}*  |
<equation>\\bigsqcup{SP}*\\nolimits{SP}*  |
<equation>\\bigotimes{SP}*\\nolimits{SP}* |
<equation>\\bigoplus{SP}*\\nolimits{SP}* |
<equation>\\bigodot{SP}*\\nolimits{SP}* |
<equation>\\biguplus{SP}*\\nolimits{SP}* |
<equation>\\sum{SP}*\\nolimits{SP}*  |
<equation>\\o?i?i?int{SP}*\\nolimits{SP}* 	|
<equation>\\Pr{SP}*\\nolimits{SP}* {
  *(yytext+1+strcspn(yytext+1," \\"))=0;
  strcpy(scratchstring,"&");strcat(scratchstring,yytext+1);
  strcat(scratchstring,";");
  TTH_SUBDEFO(scratchstring);
}
<equation>\\inf{SP}*(\\limits{SP}*)?     |
<equation>\\gcd{SP}*(\\limits{SP}*)?	|
<equation>\\det{SP}*(\\limits{SP}*)?	|
<equation>\\max{SP}*(\\limits{SP}*)?     |
<equation>\\min{SP}*(\\limits{SP}*)?     |
<equation>\\sup{SP}*(\\limits{SP}*)?     |
<equation>\\liminf{SP}*(\\limits{SP}*)?	|
<equation>\\limsup{SP}*(\\limits{SP}*)?	|
<equation>\\lim{SP}*(\\limits{SP}*)?	{
  mkkey(eqstr,eqstrs,&eqdepth);  *eqstr=0;
  *(yytext+1+strcspn(yytext+1," \\"))=0;
  strcpy(scratchstring,"<mo>");strcat(scratchstring,yytext+1);
  strcat(scratchstring,"</mo>");
  TTH_LIMITOP(scratchstring);
}

<equation>\\overbrace {
  sprintf(scratchstring,
    "\\mathop{\\mathop{#1}^{\\special{html:<mo stretchy=\"true\">&OverBrace;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation>\\underbrace {
  sprintf(scratchstring,
    "\\mathop{\\mathop{#1}_{\\special{html:<mo stretchy=\"true\">&UnderBrace;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation>\\mathop{WSP}*\{ {
  mkkey(eqstr,eqstrs,&eqdepth);
  eqclose++;
  if(tth_flev<0)tth_flev=tth_flev-99;
  TTH_PUSH_CLOSING;
  active[eqclose-1]=30;
  strcpy(eqstr,"");
  unput(' ');
  mkkey(eqstr,eqstrs,&eqdepth);
  if(tth_debug&2) fprintf(stderr,
	   "Entering mathop scan. Depth=%d, eqstrs:%s,%s,%s\n",
	  eqdepth,eqstrs[eqdepth-1],eqstrs[eqdepth-2],eqstrs[eqdepth-3]);
  *eqstr=0;
  tophgt[eqclose]=1;
  levhgt[eqclose]=1;
  active[eqclose]=1;
  unput('{');
}

 /* end of symbols */

<equation>\\ensuremath    /* Nothing needs doing */

 /* Above accents expressed with braces. Removed {WSP} 11 Apr */
<equation,exptokarg>\\breve    {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&breve;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\grave    {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&grave;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\acute    {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&acute;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\check    {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&vee;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\hat    {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&Hat;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\widehat    {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo stretchy=\"true\">&Hat;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\vec   {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&rarr;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\tilde {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>~</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1); /* or &rdquo; */
}
<equation,exptokarg>\\widetilde {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo stretchy=\"true\">&tilde;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1); /* or &rdquo; */
}
<equation,exptokarg>\\dot   {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&middot;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\ddot   {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&middot;&middot;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
 /* Problem with Mozilla not recognizing.*/
 /* Bar does not stretch*/
<equation,exptokarg>\\bar {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo>&OverBar;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\overline {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo stretchy=\"true\">&OverBar;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\overrightarrow {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo stretchy=\"true\">&rightarrow;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
<equation,exptokarg>\\overleftarrow {
  sprintf(scratchstring,
    "{\\mathop{#1}^{\\special{html:<mo stretchy=\"true\">&leftarrow;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}
 /* Unicode bar I used was &#x0332; */
<equation,exptokarg>\\underbar |
<equation,exptokarg>\\underline {
  sprintf(scratchstring,
    "{\\mathop{#1}_{\\special{html:<mo stretchy=\"true\">&OverBar;</mo>}}}#tthdrop1");
  TTH_TEX_FN(scratchstring,1);
}

  /* Implementing sqrt as a command with optional argument.*/
<equation>\\sqrt TTH_SCAN_STRING("\\expandafter\\tthsqrtexp");
<equation>\\tthsqrtexp  TTH_TEX_FN_OPT("\\tthsqrt#tthdrop2",2,"");

 /* <equation>\\sqrt  TTH_TEX_FN_OPT("\\tthsqrt#tthdrop2",2,""); */

<equation>\\root[^\\]*\\of{WSP}*(\{([^\{\}\\]*\})?)? {
  strcpy(dupstore,"\\sqrt[");
  strcpy(scratchstring,yytext+5+strspn(yytext+5," \t\r\n"));
  if((chscratch=strstr(scratchstring,"\\of"))) *chscratch=0;
  strcat(dupstore,scratchstring);
  strcat(dupstore,"]");
  if((chs2=strstr(++chscratch,"{"))){
    strcat(dupstore,chs2);
    TTH_SCAN_STRING(dupstore);
    *dupstore=0;
  }else{
    *expchar=0;TTH_CCPY(exptex,dupstore);*dupstore=0;
    yy_push_state(exptokarg); /* root */
  } 
}
<equation>\\eqno[^\$]*\$\$ { /*This is default. Puts number at left*/
  TTH_INC_MULTI;
  if((tth_flev > 0 )){
    strcpy(scrstring,yytext+5);
    *(scrstring+strlen(scrstring)-2)=0;
    sprintf(scratchstring,"}\\special{html:%s}%s\\tth_endnumbered",
	    (eqalignlog ? TTH_DISP5 : TTH_DISP3),scrstring);
    /*fprintf(stderr,"Ending eqno: %s\n",scratchstring); */
    TTH_SCAN_STRING(scratchstring);
  }else{
    yyless(5);
  TTH_OUTPUT("</mrow><mrow>\n<mtext>&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;</mtext>");
  }
 }
<equation>\\eqno     { /* Fall back*/
  TTH_OUTPUT("</mrow><mrow>\n<mtext>&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;</mtext>");
 }
<equation>\\[Bb]ig[lmr]?{WSP}* {
  TTH_SCAN_STRING("\\left.\\tth_size2\\right");
 }
<equation>\\[Bb]igg[lmr]?{WSP}* {
  TTH_SCAN_STRING("\\left.\\tth_size3\\right");
 }
<equation>\\tth_size2  levhgt[eqclose]=2;
<equation>\\tth_size3  levhgt[eqclose]=3;
<equation>\\left{WSP}*   yy_push_state(bigdel);strcpy(scratchstring,"{");
<equation>\\right{WSP}*  yy_push_state(bigdel);strcpy(scratchstring,"}");

<equation>\\[a-eg-z]*box  {
  fprintf(stderr,"Dangerous %s in equation.\n",yytext);}
<equation>\\global         ;
<equation>\\bmath          ;
<equation>\\textstyle    /* if(tth_flev>0) tth_flev=tth_flev-99; breaks some equations */
<equation>\\displaystyle  
<equation>\\scriptstyle

  /* Font sizes can't use the HTML in MML equations but ought to be fixed*/
<equation,textbox>\\tiny{SP}*  	
<equation,textbox>\\scriptsize{SP}*
<equation,textbox>\\footnotesize{SP}*
<equation,textbox>\\small{SP}*
<equation,textbox>\\normalsize{SP}*
<equation,textbox>\\large{SP}*
<equation,textbox>\\Large{SP}*
<equation,textbox>\\LARGE{SP}*
<equation,textbox>\\(H|h)uge{SP}*

  /* Default equation actions. */
<equation>[a-zA-Z]+  {  /* letter words are assumed identifiers. */
  strcpy(scratchstring,yytext);
  tth_enclose(TTH_MI,scratchstring,TTH_MIC,eqstore);
  strcat(eqstr,scratchstring);
}
<equation>[a-zA-Z]+{WSP}*(\^|\_) {
  strcpy(scratchstring,yytext);
  *(scratchstring+strcspn(scratchstring,"^_"))=0; 
  yyless(strcspn(yytext,"^_"));
  tth_enclose(TTH_MI,scratchstring,TTH_MIC,eqstore);
  TTH_SUBDEFER(scratchstring);
}   
<equation>[0-9]*  { /* Number words assumed numbers */
  strcat(eqstr,TTH_MN);    strcat(eqstr,yytext);
  strcat(eqstr,TTH_MNC);
}
<equation>[0-9]+{WSP}*(\^|\_) {
  strcpy(scratchstring,yytext);
  *(scratchstring+strcspn(scratchstring,"^_"))=0; 
  yyless(strcspn(yytext,"^_"));
  tth_enclose(TTH_MN,scratchstring,TTH_MNC,eqstore);
  TTH_SUBDEFER(scratchstring);
}   

 /* <equation>{SP}*={SP}*   TTH_MATHI(" = "); */
<equation>{SP}*      /* Removed TTH_MATHI(" ");*/
<equation>\\&    TTH_MATHI("&amp;");
<equation>\\(%|$|#|\\|_)        TTH_MATHI(yytext+1);

<equation>[+\-\*/=\.]*{WSP}*(\^|\_) {
  strcpy(scratchstring,yytext);
  *(scratchstring+strcspn(scratchstring,"^_"))=0; 
  yyless(strcspn(yytext,"^_"));
  tth_enclose(TTH_MO,scratchstring,TTH_MOC,eqstore);
  TTH_SUBDEFER(scratchstring);
}

<equation>[()\[\]]  {
  strcat(eqstr,TTH_MONS);strcat(eqstr,yytext);strcat(eqstr,TTH_MOC);
}
<equation>[()\[\]]*{WSP}*(\^|\_) {
  strcpy(scratchstring,yytext);
  *(scratchstring+strcspn(scratchstring,"^_"))=0; 
  yyless(strcspn(yytext,"^_"));
  tth_enclose(TTH_MONS,scratchstring,TTH_MOC,eqstore);
  TTH_SUBDEFER(scratchstring);
}

<equation>\\\{          |
<equation>\\lbrace{SP}* {
  strcpy(scratchstring,TTH_MONS);strcat(scratchstring,"{");strcat(scratchstring,TTH_MOC);
  TTH_SUBDEFER(scratchstring);
}
<equation>\\\}          |
<equation>\\rbrace{SP}* {
  strcpy(scratchstring,TTH_MONS);strcat(scratchstring,"}");strcat(scratchstring,TTH_MOC);
  TTH_SUBDEFER(scratchstring);
}
 /* <equation>\n  TTH_OUTPUT(yytext); */
  /**** tth pseudo-TeX ******/
<equation>#tthbigsup {
  if(tth_debug&8) fprintf(stderr,"#tthbigsup, eqhgt=%d, EQSUBSUP=%d\n",eqhgt,
TTH_INT_VALUE(EQSUBSUP));
  strcat(eqstr,TTH_BR);  /* whatever divides the two subpscripts */
  if(TTH_INT_VALUE(EQSUBSUP)){
     TTH_CCPY(expchar,TTH_MSUBSUP2); 
  }else TTH_CCPY(expchar,TTH_MUNOV2);
  TTH_INT_POP(EQSUBSUP);
  yy_push_state(exptokarg); /* tthbigsup code */
}
<equation>\\tth_eqfin { /* Finish an eq group and attach to previous key */
  TTH_OUTPUT("</mtd></mtr>\n");
  tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore); /* prefix previous row.*/
  rmkey(eqstrs,&eqdepth);
  mkkey(eqstr,eqstrs,&eqdepth);     /* Start new row */
  *eqstr=0;
 }
<equation>\\tth_lefteq {
  lefteq=1;
  colspan=3;
 }

 /* End of Equation code. */

<getsubp>{WSP}*
<getsubp>\\limits
<getsubp>(\^|\_) { /* unenclosed subp. Embrace or expand it */
  *expchar=0;strcpy(exptex,yytext);yy_push_state(exptokarg);
  if(tth_debug&8)fprintf(stderr,"Expanding big subpscript\n");
 }
<getsubp>\^\{ {
  storetype=1;
  yy_push_state(dupgroup);
  *dupstore=0;
 }
<getsubp>\_\{ {
  storetype=2;
  yy_push_state(dupgroup);
  *dupstore=0;
 }
<getsubp>\\[a-zA-Z@]+              {
  TTH_DO_MACRO
    else{
      yyless(0);TTH_SCAN_STRING("#");
    }
 }
<getsubp>#tthbigsup    { /* Needed for universal getsubp otherwise not. */
  yy_pop_state();yyless(0);
      tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore); 
      rmkey(eqstrs,&eqdepth);
}
<getsubp>. { /* No more subp's */
  if(tth_debug&10)fprintf(stderr,
		"Entering getsubp. yytext=%s, eqlimited=%s, eqstr=%s \n\
substore=%s, supstore=%s, storetype=%d\n",
			 yytext,eqlimited,eqstr,substore,supstore,storetype);
  if(*yytext != '#') yyless(0);
  storetype=0;
  yy_pop_state();
  /* Enclose the thing to be subpscripted in mrow unless eqlimited, 
     1st time only, if not already enclosed.*/
  if((strlen(substore)||strlen(supstore))&&!strlen(eqlimited)
     &&(strstr(eqstr,"<mrow")!=eqstr)){
     tth_enclose("<mrow>",eqstr,"</mrow>",eqstore);
  }
  if(strlen(supstore) && strlen(substore)){ /* Need to deal with both. */
    if(strlen(eqlimited)){ /* a symbol with limits. */
      if(tth_debug&8)fprintf(stderr,"Limited symbol. eqlimited=%s\n"
			     ,eqlimited);
      tth_prefix(TTH_MLIMIT,eqstr,eqstore);
      strcat(eqstr,eqlimited);
      TTH_INT_SETPUSH(EQSUBSUP,0) ;
      *eqlimited=0;
    }else{
      tth_prefix(TTH_MSUBSUP,eqstr,eqstore);
      TTH_INT_SETPUSH(EQSUBSUP,1) ;
    }
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
    strcpy(dupstore,"{");
    strcat(dupstore,substore);
    strcat(dupstore,"}#tthbigsup{");
    strcat(dupstore,supstore);
    strcat(dupstore,"}");
    eqhgt=hgt;
    if(tth_debug&8)fprintf(stderr,"Scanning subpscripts:%s\n",dupstore);
    TTH_SCAN_STRING(dupstore);
    strcpy(expchar," "); /* make non-null so active */
    yy_push_state(exptokarg); /* scanning subpscripts */
    strcat(eqstr,"<mrow>");
  }else if(strlen(supstore)){
    /* If the super or subscript starts as an HTML special, assume it is
       required to insert it raw without an enclosing mrow*/
    if(!(strstr(supstore,"\\special{html")==supstore))
      {TTH_CCPY(expchar,TTH_EQA2);}
    if(strlen(eqlimited)){ /* a symbol with limits. */ 
      tth_prefix(TTH_MOVER,eqstr,eqstore);
      strcat(eqstr,eqlimited);
      TTH_CCAT(expchar,TTH_MOVER2);
      *eqlimited=0;
    }else{
      tth_prefix(TTH_MSUP,eqstr,eqstore);
      TTH_CCAT(expchar,TTH_MSUP2); 
    }
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
    if(!(strstr(supstore,"\\special{html")==supstore))  
      strcat(eqstr,TTH_EQA1);
    yy_push_state(exptokarg);
    strcpy(dupstore,"{");
    strcat(dupstore,supstore);
    strcat(dupstore,"}");
    TTH_SCAN_STRING(dupstore);
/*      if(tth_debug&8)fprintf(stderr,"eqstr=:%s.",eqstr); */
    if(tth_debug&8)fprintf(stderr,"Scanning superscript:%s\n",dupstore);
  }else if(strlen(substore)){
    if(!(strstr(substore,"\\special{html")==substore))
      {TTH_CCPY(expchar,TTH_EQA2);}
    if(strlen(eqlimited)){ /* a symbol with limits. */ 
      tth_prefix(TTH_MUNDER,eqstr,eqstore);
      strcat(eqstr,eqlimited);
      TTH_CCAT(expchar,TTH_MUNDER2);
      *eqlimited=0;
    }else{
      tth_prefix(TTH_MSUB,eqstr,eqstore);
      TTH_CCAT(expchar,TTH_MSUB2); 
    }
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
    if(!(strstr(substore,"\\special{html")==substore))
      strcat(eqstr,TTH_EQA1);
    yy_push_state(exptokarg);
    strcpy(dupstore,"{");
    strcat(dupstore,substore);
    strcat(dupstore,"}");
    TTH_SCAN_STRING(dupstore);
  }else {
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
    strcat(eqstr,eqlimited);
    *eqlimited=0;
  }  
  /* was in non-zero case */
  *dupstore=0;
  *argchar=0;
  *supstore=0;
  *substore=0;
}

 /* New big, left, right, delimiters section */

<bigdel>\\\{|\\lbrace   { 
  yy_pop_state();strcpy(levdelim[eqclose+1],"{");unput(*scratchstring);}
<bigdel>\\\}|\\rbrace   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"}");unput(*scratchstring);}
<bigdel>\(   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"(");unput(*scratchstring);}
<bigdel>\)   {
  yy_pop_state();strcpy(levdelim[eqclose+1],")");unput(*scratchstring);}
<bigdel>\[|\\lbrack   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"[");unput(*scratchstring);}
<bigdel>\]|\\rbrack   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"]");unput(*scratchstring);}
<bigdel>\\lceil   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&lceil;");unput(*scratchstring);}
<bigdel>\\rceil   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&rceil;");unput(*scratchstring);}
<bigdel>\\lfloor   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&lfloor;");unput(*scratchstring);}
<bigdel>\\rfloor   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&rfloor;");unput(*scratchstring);}
<bigdel>\\langle   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&langle;");unput(*scratchstring);}
<bigdel>\\rangle   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&rangle;");unput(*scratchstring);}
<bigdel>\||\\vert   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"|");unput(*scratchstring);}
<bigdel>\/|\\backslash   {
  yy_pop_state();*levdelim[eqclose+1]=*yytext;unput(*scratchstring);}
<bigdel>\.   yy_pop_state();strcpy(levdelim[eqclose+1]," ");unput(*scratchstring);
<bigdel>. { /* unknown bigdelimiter; make blank and then rescan. */
  yy_pop_state();yyless(0);
  TTH_SCAN_STRING(scratchstring);
}
 /* Mathml additions */
<psub>\\tthsqrt#tthdrop2 { 
 /* Called by sqrt using optional+mandatory 2 arguments. */
  qrtlen=0;
  qrtlen2=0; /* silence warnings */
  TTH_CCPY(scratchstring,margs[indexkey("#1",margkeys,&margmax)]);
  if(strlen(scratchstring)){
    strcpy(dupstore2,"\n\\special{html:<mroot><mrow>}{");
    strcat(dupstore2,margs[indexkey("#2",margkeys,&margmax)]);
    strcat(dupstore2,"}\\special{html:</mrow><mrow>}{");
    strcat(dupstore2,scratchstring);
    strcat(dupstore2,"}\\special{html:</mrow>\n</mroot>}");
  }else{
    strcpy(dupstore2,"\\special{html:<msqrt><mrow>}{");
    strcat(dupstore2,margs[indexkey("#2",margkeys,&margmax)]);
    strcat(dupstore2,"}\\special{html:</mrow></msqrt>}");
  }
  TTH_SCAN_STRING(dupstore2);
  *dupstore2=0;
  rmdef(margkeys,margs,&margmax); 
  rmdef(margkeys,margs,&margmax);
  yy_pop_state();
}
<equation>\~       | 
<equation>\\nobreakspace{SP}*           TTH_MATHI("&nbsp;");
<equation>\\[ ,:>]{SP}*			TTH_MATHI("&ensp;");
<equation>\\\n			TTH_MATHI("&emsp;");tth_num_lines++;
<equation>\\;{SP}*			TTH_MATHI("&ensp;&ensp;");
<equation>\\quad          TTH_MATHI("&emsp;&emsp;&emsp;");
<equation>\\qquad          TTH_MATHI("&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;");

<equation>[/]   TTH_SUBDEFONS(yytext);
<equation>[+\-\*/=\.,:;\?!]  TTH_MATHO(yytext);
 /* Explicit single non-alpha/numeric character: Guess at operator*/
<equation>[^a-zA-z0-9] TTH_MATHO(yytext);

