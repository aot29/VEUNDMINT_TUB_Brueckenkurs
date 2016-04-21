<equation>\\lefteqn { 
  if(!eqalignrow) mkkey(eqstr,eqstrs,&eqdepth);       /* Start new row */ 
  if(tth_istyle&1)eqalignrow=eqalignrow+6*(levhgt[eqclose]-1)+TTH_HGT;else
    eqalignrow=eqalignrow+levhgt[eqclose];
  levhgt[eqclose]=1; /* new */ 
  TTH_TEX_FN("{#1}\\tth_lefteq#tthdrop1",1);
}

<equation>\\stackrel   {
  TTH_TEX_FN("{\\buildrel{#1}\\over{#2}}#tthdrop2",2);
}

<equation>{NL}  TTH_CHECK_LENGTH;  TTH_INC_LINE;
 
<equation>\\cr(cr)?{WSP}*\}  {
  TTH_INC_MULTI;
  if(*halstring){ /* halign and tabular */
    TTH_SCAN_STRING("\\tth_halcr}");
  }else{
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
 /* Font faces and styles etc.*/
<equation,tokexp,exptokarg>\\mathrm  TTH_SWAP("\\rm ");
<equation,exptokarg>\\boldsymbol |
<equation,tokexp,exptokarg>\\mathbf  TTH_SWAP("\\bf ");
<equation,tokexp,exptokarg>\\mathit   TTH_SWAP("\\it ");
<equation,tokexp,exptokarg>\\mathcal  TTH_SWAP("\\it ");
<equation,tokexp,exptokarg>\\mathtt   TTH_SWAP("\\tt ");
<equation,tokexp,exptokarg>\\mathsf   TTH_SWAP("\\sffamily ");
<equation>\\mit{SP}*
<equation>\\ifmmode{WSP}* TTH_INC_MULTI; 
<equation>\\iff TTH_MATHI(219);


<equation>&   {
 /* halign */
  /*if(*halstring) {TTH_SCAN_STRING("}\\tth_mhamper{");*/
  if(*halstring) {TTH_SCAN_STRING("\\tth_mhamper");
  }else{ yy_push_state(mamper);
  }
 }
<equation>\\tth_mhamper   yy_push_state(hamper);

 /* hamper for halign */
<mamper>{WSP}  TTH_INC_MULTI;  
<mamper>{ANY}  {  
  yyless(0);yy_pop_state();
  tth_enclose(TTH_EQA1,eqstr,TTH_EQA2,eqstore);
  if(eqaligncell && !tth_LaTeX && eqalignlog){ 
    /* This ends the second cell of eqaligno. */
    strcat(eqstr,TTH_CELL_R);
  } else strcat(eqstr,TTH_EQA3);
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
    if(eqaligncell && !tth_LaTeX && eqalignlog){ 
      /* This ends the second cell of eqaligno. */
      strcat(eqstr,TTH_CELL_R);
    } else strcat(eqstr,TTH_EQA3);
    if(eqaligncell) {
      tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
      rmkey(eqstrs,&eqdepth);
    }
    mkkey(eqstr,eqstrs,&eqdepth);
    *eqstr=0;
    eqaligncell++;
  }
}

<equation>\\noalign  { 
  if(tth_debug&33) fprintf(stderr,"noalign in equation:\n");
  if(!eqalignrow) mkkey(eqstr,eqstrs,&eqdepth);
  if(tth_istyle&1)eqalignrow=eqalignrow+6*(levhgt[eqclose]-1)+TTH_HGT;else
    eqalignrow=eqalignrow+levhgt[eqclose];
  levhgt[eqclose]=1;
  strcpy(eqstr,TTH_NOALIGN);
  TTH_TEX_FN("{#1}\\special{html:</td></tr>}\\tth_eqfin#tthdrop1",1);
  }
<equation>\\\\\*?{SP}*(\[[^\]]*\])? | /* Was later. */
<equation>\\tth_cr |
<equation>\\cr(cr)? {  
  if(eqclose && (active[eqclose-1] || mtrx[eqclose-1])){ 
    /* If this is really an array-type environment. */
    if(tth_debug&16)fprintf(stderr,
	"Active tth_cr. yytext=%s eqclose=%d, active=%d\n",
			    yytext,eqclose,active[eqclose-1]);
    if(strstr(yytext,"tth_")){ /* Prefix special opening */
      sprintf(scrstring,TTH_EQ11,
	      (lefteq ? "left":(eqalignlog ?"right":"center")),colspan);
	      /*(colspan? colspan : 1)); Avoid colspan=0; not now necc.*/
      tth_enclose(scrstring,eqstr,TTH_EQA2,eqstore);
    }else{
      /* Next line ensures \cr is equivalent to \nonumber\\ */
      if(strstr(yytext,"\\cr"))if(eqalignlog <= 100) eqalignlog=eqalignlog+100;
      tth_enclose(TTH_EQA1,eqstr,TTH_EQA2,eqstore);  
    }
    if(tth_debug&16)fprintf(stderr,
   "TTH_CR, eqalignlog=%d, colspan=%d, envirchar=%s, tth_multinum=%d, tth_LaTeX=%d.\n",
	   eqalignlog,colspan,envirchar,tth_multinum,tth_LaTeX);
    if(eqaligncell){ /* If there is a preceding & (cell) prefix it. */
      tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
      rmkey(eqstrs,&eqdepth);
    }
    /* If this row is an eqalign or is not the first.*/
    if((eqalignlog&&(eqalignlog-100))||eqalignrow){
      sprintf(eqchar,((eqalignlog&&(eqalignlog-100))?TTH_EQ7:TTH_EQ10),
	      (lefteq ? "left":((eqalignlog&&(eqalignlog-100)) ?
				"right":"center")),colspan);
      tth_prefix(eqchar,eqstr,eqstore); /* Prefix its opening */
      *eqchar=0;
    }
    if(eqalignrow){                     /* If this row is not the first.*/
      tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore); /* Prefix previous row */
      rmkey(eqstrs,&eqdepth);
    }
    if(tth_LaTeX && tth_multinum && strlen(envirchar) && (eqalignlog==1) ){
      strcat(eqstr,TTH_EQ8);
      strcpy(scratchstring,"(\\theequation)");
    }else{
      if((eqalignlog>1)&&(eqalignlog-100)) strcat(eqstr,TTH_EQ9);
      *scratchstring=0;
    }
    strcat(scratchstring,"\\tth_closerow");
    TTH_SCAN_STRING(scratchstring);
    /*mtrx[eqclose-1]=0; A mistake. Should be done only at end.*/
  }else if(*halstring){ /* halign and tabular */
    TTH_SCAN_STRING("\\tth_halcr");
  }else{
    fprintf(stderr,"**** Improper \\\\ or \\cr outside array environment ignored, Line %d.\n",tth_num_lines);
  }
}

<equation>\\tth_closerow {
  if(tth_LaTeX && tth_multinum && strlen(envirchar) && (eqalignlog==1) ){
    equatno++;sprintf(envirchar,"%d",equatno);tth_multinum++;
  }
  strcat(eqstr,"</td></tr>"); /* Close the row */
  *eqchar=0;
  mkkey(eqstr,eqstrs,&eqdepth);     /* Start new row */
  *eqstr=0;
  /* eqalignrow++; old */
  if(tth_istyle&1)eqalignrow=eqalignrow+6*(levhgt[eqclose]-1)+TTH_HGT;else
    eqalignrow=eqalignrow+levhgt[eqclose];
  levhgt[eqclose]=1; /* new */
  eqaligncell=0;
  lefteq=0;
  colspan=1;
  if(eqalignlog >= 100) eqalignlog=eqalignlog-100;
}

<equation,textbox>\{ {
  if(tth_debug&16) {
    fprintf(stderr,"Start Group {, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s\n",eqdepth,eqclose,tth_flev,levdelim[eqclose]);
  }
  if(tth_flev < 0) tth_flev=tth_flev-99;
   mkkey(eqstr,eqstrs,&eqdepth);
   *eqstr=0;
   eqclose++;
   tophgt[eqclose]=0;
   levhgt[eqclose]=1;
   TTH_PUSH_CLOSING;
 }

<getsubp>\} {
  if(mtrx[eqclose-1] || active[eqclose-1] || tophgt[eqclose]){
    /* Terminate getsubp state */
    yyless(0);
    TTH_SCAN_STRING("#");
  }else{
  /* Just enter the brace termination code. */
    TTH_SCAN_STRING("\\tth_closebrace");
  }
}
<getsubp>\\tth_closebrace |
<equation,textbox>\} { 
  TTH_TEXCLOSE else{
  do{
  if(tth_debug&16) {
    if(active[eqclose]) {
    fprintf(stderr,
         "Active Group }, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s, active=%d\n"
	    ,eqdepth,eqclose,tth_flev,levdelim[eqclose],active[eqclose]);}
    else {fprintf(stderr,
	      "Close Group }, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s\n"
	       ,eqdepth,eqclose,tth_flev,levdelim[eqclose]);}
  }
  if(tophgt[eqclose] != 0){ /* If fraction */
    if(tth_debug&16)fprintf(stderr,"Fraction closing.\n");
    if(levhgt[eqclose] > 1 || (eqclose > tth_flev && TTH_COMPLEX)){ 
      /* If bottom contains a fraction or we are topped out. */
      /* Try bottom compression*/
      oa_removes=b_align(eqstr,tth_debug);
      tth_enclose(TTH_LEV1,eqstr,TTH_LEV2,eqstore);
    }else{ /* Put br at end if we are still closing a real cell */
      if((eqclose <= tth_flev) && (active[eqclose-1]!=30)) strcat(eqstr,TTH_BR);
    }
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
    rmkey(eqstrs,&eqdepth);
    TTH_CLOSEGROUP;TTH_POP_CLOSING; /* put closing before cell end */
    if(active[eqclose-1]!=30){ 
      /* CELL1/2 test for non-zero levdelim 0,+1 */
      tth_enclose(TTH_CELL1,eqstr,TTH_CELL2,eqstore); 
      if(eqclose <= tth_flev) yy_push_state(getsubp); 
      if(tth_debug&16) fprintf(stderr,"Whole fraction:%s\n",eqstr);
    }
  }else {
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
  }
  if(eqclose > tth_flev) hgt=1; else hgt=tophgt[eqclose]+levhgt[eqclose];
  if(tth_debug&16) fprintf(stderr,"eqclose=%d,tth_flev=%d,hgt=%d,%d,%d\n",
	  eqclose,tth_flev,hgt,tophgt[eqclose],levhgt[eqclose]);
  if(levhgt[eqclose-1] < hgt) levhgt[eqclose-1]=hgt;
  if(tth_debug&2 && (levdelim[eqclose][0]||levdelim[eqclose+1][0]))
    fprintf(stderr,"Delimiting:%s%d%s\n",
	    levdelim[eqclose],hgt,levdelim[eqclose+1]);
  if(levdelim[eqclose][0]){
    delimit(levdelim[eqclose],hgt,eqchar);
  }
  if(levdelim[eqclose+1][0]){
    delimit(levdelim[eqclose+1],hgt,eqchar2);
  }
  /* Cut spurious cells off end of eqchar and eqstr if necessary*/
  chscratch=eqchar+strlen(eqchar)-strlen(TTH_CELL3);
  if( (strstr(chscratch,TTH_CELL3)==chscratch) &&
      (strstr(eqstr,TTH_CELL_START)==eqstr+strspn(eqstr," \n"))){ 
    *chscratch=0;
  }
  chscratch=eqstr+strlen(eqstr)-strlen(TTH_CELL3);
  if( (strstr(eqchar2,TTH_CELL_START)==eqchar2+strspn(eqchar2," \n")) &&
      (strstr(chscratch,TTH_CELL3)==chscratch) ){
    *chscratch=0;
  } /* Section could be combined with delimit immediately above. */
  /* rely on no delimiters on active closures. False for matrix. */
  if(levdelim[eqclose+1][0] && (hgt > 1)) yy_push_state(getsubp);
  *levdelim[eqclose]=0;
  *levdelim[eqclose+1]=0;

  tth_enclose(eqchar,eqstr,eqchar2,eqstore);
  *eqchar=0;
  *eqchar2=0;
  if(active[eqclose-1]==30){ /* eqlimited section for mathop, overbrace */
    if(tth_debug&2)fprintf(stderr,"Mathop eqlimited:%s\n",eqstr);
    if(strlen(eqlimited)+strlen(eqstr)< TTH_DLEN) {
      strcat(eqlimited,eqstr);
      if(tth_debug&2)fprintf(stderr,"EQlimited=||%s||\n",eqlimited);
    }else{
      fprintf(stderr,
          "Error: Fatal! Exceeded eqlimited storage. Over/underbrace too long.\n");
      TTH_EXIT(5);
    }
    strcpy(eqstr,eqstrs[eqdepth-1]);
    yy_push_state(getsubp);
    if(levhgt[eqclose] == 1)levhgt[eqclose]=2; /* Force fraction closure */
    active[eqclose-1]=0;
  }else{
    tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
  }
  rmkey(eqstrs,&eqdepth);
  if(tth_flev <  0) tth_flev=tth_flev+99;
  active[eqclose]=0;
  mtrx[eqclose]=0;
  eqclose--;
  if(eqclose < 0) {
    fprintf(stderr,"**** Error! Fatal! Negative closure count, line:%d\n",tth_num_lines);
    TTH_EXIT(4);
  }
  } while (active[eqclose]);
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
    if(tth_inlinefrac && (levhgt[eqclose]+tophgt[eqclose]>1))
      tth_enclose(TTH_TSTY1,eqstr,TTH_TSTY2,eqstore);
    if(eqdepth==1){
      rmkey(eqstrs,&eqdepth); /*eqdepth--;*/
      tth_flev=tth_flev0;
      horizmode=1;
      if(tth_tagpurge){
	tagpurge(eqstr);
	tth_tagpurge=0;
      }
      fprintf(tth_fdout,"%s",eqstr);*eqstr=0;
    }else{
      if(displaystyle)displaystyle--;
      eqdepth--;
      if(tth_debug&2)fprintf(stderr,
			     "Equation in a textbox inside an equation.\n");
      TTH_OUTPUT(TTH_TEXTBOX1);
    }
    yy_pop_state();
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
  if(tth_debug&2) fprintf(stderr,
	 "End equation %d, %s. eqalignlog=%d, tth_eqwidth=%d\n",
		equatno,yytext,eqalignlog,tth_eqwidth);
  if(tth_multinum)tth_multinum=1;
  {
    if(eqalignlog){
      sprintf(scrstring,TTH_DISPE,tth_eqwidth);
      tth_enclose(scrstring,eqstr,TTH_DISP6,eqstore);
/*        tth_enclose(scrstring,eqstr,TTH_DISP4,eqstore); */
    }else{
      sprintf(scrstring,TTH_DISP1,tth_eqwidth);
      if(strstr(yytext,"numb")){
	tth_enclose(scrstring,eqstr,TTH_DISP4,eqstore);
      }else{
	tth_enclose(scrstring,eqstr,TTH_DISP2,eqstore);
      }
    }
    if(tth_debug&2) fprintf(stderr,
       "Leaving display eq, eqclose=%d, eqdepth=%d, tth_flev=%d\n",  
         eqclose,eqdepth,tth_flev);
    if(eqdepth==1){
      rmkey(eqstrs,&eqdepth);/*eqdepth--;*/
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
    yy_pop_state();
    tth_flev=tth_flev0; /* Necessary if textstyle has been used. */
    horizmode=1; /* Make sure we now recognize \n\n */
    displaystyle=0;
    *environment=0;
    eqalignlog=0;
    TTH_CLOSEGROUP;TTH_POP_CLOSING;
    fprintf(tth_fdout,"%s\n",eqstr);*eqstr=0;
  }
  }
}
 /* Single character fractions .*/
<equation>[\$\{]{WSP}*[0-9a-zA-Z]{WSP}*\\over{WSP}*[0-9a-zA-Z]{WSP}*[\$\}] {
  if(active[eqclose]){ /* reembrace to protect active closure */
    TTH_INC_MULTI; 
    sprintf(scratchstring,"{%s}",yytext);
    TTH_SCAN_STRING(scratchstring);
  }else  if((eqclose > tth_flev || !displaystyle)){
    TTH_INC_MULTI; 
    chscratch=yytext+strspn(yytext,"${ \t\n");
    chs2=strstr(chscratch,"\\over")+5;
    sprintf(scratchstring,"<sup>%c</sup>/<sub>%c</sub>",
	    *(chscratch),*(chs2+strspn(chs2," \t\r\n")));
    TTH_OUTPUT(scratchstring);
  }else{ /* split to prevent treatment */
    strcpy(scratchstring,yytext);
    jscratch=strspn(yytext,"${ \t");
    yyless(jscratch);
    *(scratchstring+jscratch)=0;
    TTH_SCAN_STRING(scratchstring);
  }
 }

<equation>{WSP}+\\(over|above|atop|choose) {
  TTH_INC_MULTI; 
  yyless(strspn(yytext," \t\r\n"));
}
<equation>\\(over|above|atop|choose){WSP}* {
  TTH_INC_MULTI; 
  if(tth_debug&16)fprintf(stderr,
	  "Over Close Group, depth=%d, eqclose=%d, levhgt=%d\n",
	  eqdepth,eqclose,levhgt[eqclose]);
  if(levhgt[eqclose] > 1 || (eqclose > tth_flev && TTH_COMPLEX)) {
    /* Remove unnecessary cell and bottoms from single cells*/
    oa_removes=b_align(eqstr,tth_debug);
    tth_enclose(TTH_LEV1,eqstr,TTH_LEV2,eqstore);
  }else { /* Fix a strange alignment problem. Removed 15 Oct 2003
    if((tth_istyle&1) && !strstr(yytext,"atop") && !strstr(yytext,"choose"))
      tth_prefix("&nbsp;",eqstr,eqstore); */
  }
  if(strstr(yytext,"atop") || strstr(yytext,"choose"))
     strcat(eqstr,TTH_ATOP);
  else strcat(eqstr,TTH_DIV);
  mkkey(eqstr,eqstrs,&eqdepth);
  *eqstr=0;
  tophgt[eqclose]=levhgt[eqclose]+1;
  levhgt[eqclose]=1; 
  if(strstr(yytext,"choose")){
    strcat(levdelim[eqclose],"(");
    tth_push_depth--;
    TTH_PRETEXCLOSE("\\tth_chooseclose");
    tth_push_depth++;
  }
 } 
<equation,getsubp>\\tth_chooseclose  strcpy(levdelim[eqclose+1],")");
     /*TTH_SCAN_STRING("\\right)"); doesn't work. Imbalances closures.*/

 /* End of Fraction*/

 /* Sub/p scripts. */
 /* Dont make prime a superscript, it becomes too small.
   This case will not be used if we are doing a full cell (getsubsup). */
<equation>\^\\prime{SP}*	TTH_MATHI(162); 
<equation>\^		{
  strcat(eqstr,TTH_SUP1);yy_push_state(exptokarg);
  TTH_CCPY(expchar,TTH_SUP2);
  }
<equation>\_		{
  strcat(eqstr,TTH_SUB1);yy_push_state(exptokarg);
  TTH_CCPY(expchar,TTH_SUB2);
  }
 /* Version that uses tabular:*/
<equation>\\begin{WSP}*\{array\}(\[.\])? {
  TTH_INC_MULTI; 
  TTH_SCAN_STRING("\\begin{tabular}");
}
<equation>\\eqalign(no)*{WSP}*\{	|
<equation>\\(border)?matrix{WSP}*\{ { /*border not really supported*/
  TTH_INC_MULTI; 
  TTH_HAL_PUSH;*halstring=0;
  if(strstr(yytext,"eq") != NULL) eqalignlog++;/*make both levels 1*/
  TTH_EQA_PUSH;
  /*This instead of the previous makes level 1 only. Intended for lone
   \eqno, but breaks the standard layout. So don't do it.*/
  /*  if(strstr(yytext,"eq") != NULL) eqalignlog++;*/
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
  tth_push_depth--;
  TTH_PRETEXCLOSE("\\tth_cr\\tth_matrixclose");
  tth_push_depth++;
  mtrx[eqclose-1]=1;
  if(tth_debug&16)fprintf(stderr,"Set Matrix: eqclose=%d,eqdepth=%d\n",eqclose,eqdepth);/**/
 }
<equation>\\tth_matrixclose {
  if(tth_debug&16) fprintf(stderr,"Matrix close %d, levhgt=%d, rows=%d\n",
			   eqclose,levhgt[eqclose],eqalignrow);
  if(tth_istyle&1) levhgt[eqclose]=(eqalignrow+6*(levhgt[eqclose]-1)+TTH_HGT)/6; else       levhgt[eqclose]=levhgt[eqclose]+eqalignrow;
  tth_prefix(eqstrs[eqdepth-1],eqstr,eqstore);
  rmkey(eqstrs,&eqdepth);
  if(eqalignlog){
    /* For 50% but just first line */
    tth_enclose(TTH_EQ3,eqstr,TTH_EQ2,eqstore);
  }else{
    tth_enclose(TTH_EQ1,eqstr,TTH_EQ2,eqstore);
  }
  TTH_EQA_POP;
  TTH_HAL_POP;
  /* Enclose unless this is the end of an eqalign type construct. */
  if(eqaind || !eqalignlog)tth_enclose(TTH_CELL5,eqstr,TTH_CELL5,eqstore);
  active[eqclose-1]=0;
}

<equation>\\cases  {
  TTH_TEX_FN("\\mbox{\\left\\lbrace\\matrix{#1}\\right.}#tthdrop1",1);
}
<equation>\\pmatrix {
  TTH_TEX_FN("\\left(\\matrix{#1}\\right)#tthdrop1",1);
}

 /*  textboxes. Because of problems as subscript, removed this to builtins. 
     <equation,exptokarg>\\textrm    |
     but this does not generally seem to be a good plan.
     But the approach below breaks with unenclosed subscript texts.
 */
<equation,exptokarg>\\raisebox\{[^\}]*\}({SP}?\[[^\]]*\]){0,2}{SP}* |
<equation,exptokarg>\\[hvmf]box{WSP}* |
<equation,exptokarg>\\textrm    |
<equation,exptokarg>\\textmd    |
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
  if(tth_debug&2)fprintf(stderr,
    "Start textbox. eqclose %d. push_depth %d. Line %d\n"
			 ,eqclose,tth_push_depth,tth_num_lines);
  if(!displaystyle) yy_push_state(textbox);  
  TTH_SWAP(scratchstring);
  /* This had to be moved into tth_tbone */
  /*TTH_PRETEXCLOSE("\\tth_boxclose");*/
}
<exptokarg>\\tth_tbox {
  if(tth_debug&2)fprintf(stderr,
      "Start textbox exptokarg. Displaystyle %d. eqclose %d, push_depth %d, Line %d\n"
			 ,displaystyle,eqclose,tth_push_depth,tth_num_lines);
  yy_pop_state(); 
  if(!displaystyle)yy_push_state(textbox);
  yy_push_state(exptokarg); 
  TTH_SWAP(scratchstring);
}
<equation,textbox>\\tth_boxclose  { /* box closure*/
    if(tth_debug&2) fprintf(stderr,"Box closure, eqclose=%d\n",eqclose);
    if(!displaystyle) yy_pop_state(); /* textbox state end */
  }
<equation,textbox>\\tth_tbone  {
  if(tth_debug&8)fprintf(stderr,"tbone at push_depth %d\n",tth_push_depth);
  TTH_OUTPUT(TTH_TEXTBOX1);
  tth_push_depth--;TTH_PRETEXCLOSE("\\tth_boxclose");tth_push_depth++;
}
<equation,tokexp,exptokarg,textbox>\\hbox{SP}+to {GET_DIMEN;} /* Override new handling */

<equation>\$            |
<equation>(\\end|\\begin)\{math\} |
<equation>\\(\)|\()          {
  /* Deal with single $ or inline in display equations or boxes.*/
  if(displaystyle==1){ /* Open inline in box enclose it.*/
    if(tth_debug&2)fprintf(stderr,"Inline inside displaystyle.\n");
    TTH_SCAN_STRING("{$");
    displaystyle++;
  }else if(displaystyle==2){
    if(!strstr(tth_font_open[tth_push_depth],TTH_ITAL1)){
      strcat(tth_font_open[tth_push_depth],tth_font_open[0]);
      strcat(tth_font_close[tth_push_depth],tth_font_close[0]);   
    }
    displaystyle++;
  }else if(displaystyle==3){ /* End enclosure inserted. */
    if(tth_debug&2)fprintf(stderr,"End Inline inside displaystyle.\n");
    TTH_SCAN_STRING("}");
    displaystyle=1;
  }else if(strstr(tth_texclose[tth_push_depth],"tth_boxclose")) {
    if(tth_debug&2) fprintf(stderr,"Inline inside box.\n");
    if(!strstr(tth_font_open[tth_push_depth],TTH_ITAL1)){
      strcat(tth_font_open[tth_push_depth],tth_font_open[0]);
      strcat(tth_font_close[tth_push_depth],tth_font_close[0]); 
    }
  }else{
    TTH_SCAN_STRING("}\\tth_endinline");
  }
 }
		/* Math greek and symbols */
<equation>\\alpha{SP}*	TTH_MATHS("a");
<equation>\\beta{SP}*	TTH_MATHS("b");
<equation>\\gamma{SP}*	TTH_MATHS("g");
<equation>\\delta{SP}*	TTH_MATHS("d");
<equation>\\epsilon{SP}*	TTH_MATHS("e");
 /* <equation>\\varepsilon{SP}*	TTH_MATHS("e"); */ 
<equation>\\varepsilon{SP}* {
  if(tth_unicode){
    TTH_MATHI(129); /*Kludge for coding translation */
  }else{
    TTH_MATHS("e");
  }
}			  
<equation>\\zeta{SP}*	TTH_MATHS("z");
<equation>\\eta{SP}*   	TTH_MATHS("h")
<equation>\\theta{SP}*	TTH_MATHS("q");
<equation>\\vartheta{SP}*   TTH_MATHS("J");
<equation>\\iota{SP}*	TTH_MATHS("i");
<equation>\\kappa{SP}*	TTH_MATHS("k");
<equation>\\lambda{SP}*	TTH_MATHS("l");
<equation>\\lambdar{SP}*	TTH_MATHS("l");
<equation>\\mu{SP}*     	TTH_MATHS("m");
<equation>\\nu{SP}*     	TTH_MATHS("n");
<equation>\\xi{SP}*     	TTH_MATHS("x");
<equation>\\pi{SP}*      TTH_MATHS("p");
<equation>\\varpi{SP}*	TTH_MATHS("v");
<equation>\\rho{SP}*    	TTH_MATHS("r");
<equation>\\varrho{SP}*	TTH_MATHS("r");
<equation>\\sigma{SP}*	TTH_MATHS("s");
<equation>\\varsigma	TTH_MATHS("V");
<equation>\\tau{SP}*    	TTH_MATHS("t");
<equation>\\upsilon{SP}*	TTH_MATHS("u");
<equation>\\phi{SP}*    	TTH_MATHS("f");
<equation>\\varphi{SP}*	TTH_MATHS("j");
<equation>\\chi{SP}*    	TTH_MATHS("c");
<equation>\\psi{SP}*    	TTH_MATHS("y");
<equation>\\omega{SP}*	TTH_MATHS("w");
<equation>\\Gamma{SP}*	TTH_MATHS("G");
<equation>\\Delta{SP}*	TTH_MATHS("D");
<equation>\\Theta{SP}*	TTH_MATHS("Q");
<equation>\\Lambda	TTH_MATHS("L");
<equation>\\Xi{SP}*	TTH_MATHS("X");
<equation>\\Pi{SP}*     	TTH_MATHS("P");
<equation>\\Sigma{SP}*	TTH_MATHS("S");
<equation>\\Upsilon{SP}*	TTH_MATHS("U");
<equation>\\Phi{SP}*    	TTH_MATHS("F");
<equation>\\Psi{SP}*    	TTH_MATHS("Y");
<equation>\\Omega{SP}*	TTH_MATHS("W");

<equation>\\ell{SP}*     TTH_MATHC("<i>l</i>");
<equation>\\aleph{SP}*	TTH_MATHI(192);
<equation>\\imath{SP}*	TTH_MATHS("i"); 
<equation>\\jmath{SP}*	TTH_MATHC("j"); 
<equation>\\wp{SP}*  	TTH_MATHI(195);
<equation>\\cal{SP}*(R|\{R\}) |
<equation>\\Re{SP}*  	TTH_MATHI(194);
<equation>\\cal{SP}*(I|\{I\}) |
<equation>\\Im{SP}*  	TTH_MATHI(193);
<equation>\\partial{SP}*     TTH_MATHI(182);
<equation>\\infty{SP}*  	TTH_MATHI(165);
<equation>\\angle{SP}*  	TTH_MATHI(208);
<equation>\'{SP}*	TTH_MATHI(162);
<equation>\\prime{SP}*	TTH_MATHI(162);
<equation>\\emptyset{SP}*	TTH_MATHI(198);
<equation>\\nabla{SP}*	TTH_MATHI(209);
<equation>\\surd{SP}*	TTH_MATHI(214);
<equation>\|            |
<equation>\\vert{SP}* 	TTH_MATHS("|");
<equation>\\parallel{SP}* |
<equation>\\\|           |
<equation>\\Vert{SP}* 	TTH_MATHS("||");
<equation>\\lbrack{SP}*  TTH_MATHC("[");
<equation>\\rbrack{SP}*  TTH_MATHC("]");
<equation>\\lbrace{SP}*  TTH_MATHC("{");
<equation>\\rbrace{SP}*  TTH_MATHC("}");
<equation>\\rceil{SP}*   TTH_MATHI(249);
<equation>\\rfloor{SP}*  TTH_MATHI(251);
<equation>\\lceil{SP}*   TTH_MATHI(233);
<equation>\\lfloor{SP}*  TTH_MATHI(235);
<equation>\\langle{SP}*		TTH_MATHI(225);
<equation>\\rangle{SP}*		TTH_MATHI(241);
\\textbackslash{SP}*            |
<equation>\\backslash{SP}* 	|
<equation>\\setminus{SP}* 	TTH_MATHC("\\"); 
<equation>\\forall{SP}*	TTH_MATHS("\"");
<equation>\\exists{SP}*	TTH_MATHS("$");
<equation>\\neg{SP}*  	TTH_MATHI(216);
<equation>\\clubsuit{SP}*	TTH_MATHI(167);
<equation>\\diamondsuit{SP}*	TTH_MATHI(168);
<equation>\\heartsuit{SP}*	TTH_MATHI(169);
<equation>\\spadesuit{SP}*	TTH_MATHI(170);

<equation>-      TTH_MATHS("-");
  /*Risky. <equation>\+      TTH_MATHS("+"); */
<equation>\\top{SP}*         TTH_MATHC("T"); 
<equation>\\bot{SP}* 	|
<equation>\\perp{SP}*	TTH_MATHS("^");
<equation>\\circ{SP}*	TTH_MATHI(176);
<equation>\\\~{SP}*     	TTH_MATHC("&#126;"); 
<equation>\\sim{SP}*		TTH_MATHS(" ~ ");
<equation>\\pmod |     /* Incorrect for now; needs parens.*/
<equation>\\bmod{SP}*	TTH_MATHC(" mod ");
<equation>\<		TTH_MATHC(" &lt; ");
<equation>\>		TTH_MATHC(" &gt; ");
<equation>\<\<		|
<equation>\\ll{SP}*		TTH_MATHC(" &lt;&lt; ");
<equation>\>\>		|
<equation>\\gg{SP}*		TTH_MATHC(" &gt;&gt; ");
<equation>\\ast{SP}*		TTH_MATHS("*");
<equation>\\star{SP}*	TTH_MATHS("*");
<equation>\\diamond{SP}*	TTH_MATHI(224);
<equation>\\bullet{SP}*     	TTH_MATHI(183);
<equation>\\cdot{SP}*		TTH_MATHC("&#183;"); 
 /*<equation>\\cdot	TTH_MATHI(215);*/
<equation>\\cup{SP}* 	TTH_MATHI(200);
<equation>\\cap{SP}* 	TTH_MATHI(199);
<equation>\\pm{SP}*		TTH_MATHI(177);
<equation>\\mp{SP}*		TTH_MATHS("-&#177;");
<equation>\\lor{SP}* 	|
<equation>\\vee{SP}*		TTH_MATHI(218);
<equation>\\land{SP}*        |
<equation>\\wedge{SP}*	TTH_MATHI(217);
<equation>\\oplus{SP}*	TTH_MATHI(197);
<equation>\\otimes{SP}*	TTH_MATHI(196);
<equation>\\oslash{SP}*	TTH_MATHI(198);

<getsubp>\\tthtensor{WSP}*    TTH_INC_MULTI;/* Don't mess up if it is in wrong place*/
<equation>\\tthtensor{SP}* {
  if(eqclose <= tth_flev-1 && displaystyle){
    /*If we end with a CELL3, cut it off. */
    if( ((jscratch=strlen(eqstr)) >= (js2=strlen(TTH_CELL3))) && 
	strcmp(eqstr+jscratch-js2,TTH_CELL3) == 0){
      *(eqstr+jscratch-js2)=0;
    }
    strcat(eqstr,TTH_CELL_L);
    if(levhgt[eqclose] == 1)levhgt[eqclose]=2;
    if(hgt < 2) hgt=2;
    yy_push_state(getsubp);
  }
}

<equation>\\int{SP}* 	{
 if(eqclose > tth_flev-1 || !displaystyle ){
   TTH_MATHI(242); /* TTH_OUTPUT(" "); perhaps not */
 }else{
   delimit("&#242;",2,eqchar);
   strcat(eqstr,eqchar);
   *eqchar=0;
   if(levhgt[eqclose] == 1)levhgt[eqclose]=2;
   hgt=3;
   yy_push_state(getsubp);
 }
 }
<equation>\\oint{SP}*\\limits{SP}* 	|
<equation>\\oint{SP}* {
  if(eqclose > tth_flev-1){
    TTH_MATHC("(");TTH_MATHI(242);TTH_MATHC(")");
  }else{
    TTH_OINT;
    yy_push_state(getsubp);
  }
 }

<equation>\\bigcap{SP}*  TTH_LIMITOP(199);
<equation>\\bigcup{SP}*  TTH_LIMITOP(200);
<equation>\\bigvee{SP}*  TTH_LIMITOP(218);
<equation>\\bigwedge{SP}*  TTH_LIMITOP(217);
<equation>\\bigotimes{SP}*  TTH_LIMITOP(196);
<equation>\\bigoplus{SP}*  TTH_LIMITOP(197);
<equation>\\sum{SP}*  TTH_LIMITOP(229);
<equation>\\prod{SP}* TTH_LIMITOP(213);
<equation>\\int{SP}*\\limits{SP}* 	TTH_LIMITOP(242);
<equation>\\limits{SP}*  /* Drop a limits command if not combined */

<equation>\\bigcap{SP}*\\nolimits{SP}*  TTH_MATHI(199);
<equation>\\bigcup{SP}*\\nolimits{SP}*  TTH_MATHI(200);
<equation>\\bigvee{SP}*\\nolimits{SP}*  TTH_MATHI(218);
<equation>\\bigwedge{SP}*\\nolimits{SP}*  TTH_MATHI(217);
<equation>\\bigotimes{SP}*\\nolimits{SP}*  TTH_MATHI(196);
<equation>\\bigoplus{SP}*\\nolimits{SP}*  TTH_MATHI(197);
<equation>\\sum{SP}*\\nolimits{SP}*  TTH_MATHI(229);
<equation>\\prod{SP}*\\nolimits{SP}* TTH_MATHI(213);

<equation>\\div{SP}*  	TTH_MATHI(184);
<equation>\\times{SP}*		TTH_MATHC("&times;"); 
 /*<equation>\\times	TTH_MATHI(180);*/
<equation>\\le(ss)?sim{SP}*		TTH_MATHC(" &lt;~"); 
<equation>\\g(e|tr)sim{SP}*		TTH_MATHC(" &gt;~"); 

<equation>\\mid{SP}*    TTH_MATHC(" ");TTH_MATHC("|");TTH_MATHC(" ");
<equation>\\leq{SP}*	TTH_MATHC(" ");TTH_MATHI(163);TTH_MATHC(" ");
<equation>\\le{SP}*	TTH_MATHC(" ");TTH_MATHI(163);TTH_MATHC(" ");
<equation>\\ge{SP}*     TTH_MATHC(" ");TTH_MATHI(179);TTH_MATHC(" ");
<equation>\\geq{SP}*    TTH_MATHC(" ");TTH_MATHI(179);TTH_MATHC(" ");
<equation>\\equiv{SP}*	TTH_MATHC(" ");TTH_MATHI(186);TTH_MATHC(" ");
<equation>\\approx{SP}*	TTH_MATHC(" ");TTH_MATHI(187);TTH_MATHC(" ");
<equation>\\not{SP}*={SP}*        |
<equation>\\neq{SP}*	TTH_MATHC(" ");TTH_MATHI(185);TTH_MATHC(" ");
<equation>\\ne{SP}*	TTH_MATHC(" ");TTH_MATHI(185);TTH_MATHC(" ");
<equation>\\not\\subset{SP}*	TTH_MATHC(" ");TTH_MATHI(203);TTH_MATHC(" ");
<equation>\\subset{SP}*	TTH_MATHC(" ");TTH_MATHI(204);TTH_MATHC(" ");
<equation>\\subseteq{SP}*  TTH_MATHC(" ");TTH_MATHI(205);TTH_MATHC(" ");
<equation>\\supset{SP}*	TTH_MATHC(" ");TTH_MATHI(201);TTH_MATHC(" ");
<equation>\\supseteq{SP}*  TTH_MATHC(" ");TTH_MATHI(202);TTH_MATHC(" ");
<equation>\\in{SP}*	TTH_MATHC(" ");TTH_MATHI(206);TTH_MATHC(" ");
<equation>\\not\\in{SP}* |
<equation>\\notin{SP}*	TTH_MATHC(" ");TTH_MATHI(207);TTH_MATHC(" ");
<equation>\\ni{SP}*  |
<equation>\\owns{SP}*    TTH_MATHC(" ");TTH_MATHI(39);TTH_MATHC(" ");
<equation>\\simeq{SP}*  |
<equation>\\cong{SP}*    TTH_MATHC(" ");TTH_MATHI(64);TTH_MATHC(" ");
<equation>\\propto{SP}*	TTH_MATHC(" ");TTH_MATHI(181);TTH_MATHC(" ");
<equation>\\gets          |
<equation>\\leftarrow	    TTH_MATHI(172);
<equation>\\longleftarrow   TTH_MATHI(172);
   /* A slight kludge */
<equation>\\longmapsto |
<equation>\\mapsto |
<equation>\\to  |
<equation>\\rightarrow	    TTH_MATHI(174);
<equation>\\longrightarrow  TTH_MATHI(174);
<equation>\\uparrow	    TTH_MATHI(173);
<equation>\\downarrow	    TTH_MATHI(175);
<equation>\\updownarrow	    TTH_MATHC(yytext);
<equation>\\Updownarrow	    TTH_MATHC(yytext);
<equation>\\longleftrightarrow |
<equation>\\leftrightarrow  TTH_MATHI(171);
<equation>\\Leftarrow	    TTH_MATHI(220);
<equation>\\Longleftarrow   TTH_MATHI(220);
<equation>\\Rightarrow	    TTH_MATHI(222);
<equation>\\Longrightarrow  TTH_MATHI(222);
<equation>\\RA		    TTH_MATHC(yytext);
<equation>\\Longleftrightarrow |
 /* moved before if code <equation>\\iff TTH_MATHI(219); */
<equation>\\Leftrightarrow  TTH_MATHI(219);
<equation>\\Uparrow	    TTH_MATHI(221);
<equation>\\Downarrow	    TTH_MATHI(223);
 /* <equation>\\dots{SP}*	TTH_MATHI(188); Not in math mode */
<equation>\\dotsb{SP}*	TTH_MATHI(188);
<equation>\\dotsc{SP}*	TTH_MATHI(188);
<equation>\\dotsi{SP}*	TTH_MATHI(188);
<equation>\\ldots{SP}*	TTH_MATHI(188);
<equation>\\cdots{SP}*	TTH_MATHI(188);
<equation>\\ddots{SP}*   TTH_OUTPUT("<sup><big>&#183;</big></sup>&#183;<sub><big>&#183;</big></sub>");
<equation>\\vdots{SP}*   TTH_OUTPUT(":");
<equation>\\atsign{SP}*		TTH_MATHC("@");
\\dag |
<equation>\\dagger       TTH_OUTPUT(TTH_DAG);
\\ddag |
<equation>\\ddagger       TTH_OUTPUT(TTH_DDAG);

<equation>\\arccos{SP}*		TTH_MATHC("arccos");  
<equation>\\arcsin{SP}*		TTH_MATHC("arcsin");  
<equation>\\arctan{SP}*		TTH_MATHC("arctan");  
<equation>\\arg{SP}*		TTH_MATHC("arg");  
<equation>\\cos{SP}*		TTH_MATHC("cos");  
<equation>\\cosh{SP}*		TTH_MATHC("cosh");  
<equation>\\cot{SP}*		TTH_MATHC("cot");  
<equation>\\coth{SP}*		TTH_MATHC("coth");  
<equation>\\csc{SP}*		TTH_MATHC("csc");  
 /* <equation>\\deg{SP}*        TTH_MATHC("&deg;");  Incorrect TeX */
<equation>\\deg{SP}*		TTH_MATHC("deg");
<equation>\\dim{SP}*		TTH_MATHC("dim");  
<equation>\\exp{SP}*		TTH_MATHC("exp");  
<equation>\\hom{SP}*		TTH_MATHC("hom");  
<equation>\\ker{SP}*		TTH_MATHC("ker");  
<equation>\\lg{SP}*		TTH_MATHC("lg");  
<equation>\\ln{SP}*		TTH_MATHC("ln");  
<equation>\\log{SP}*		TTH_MATHC("log");  
<equation>\\sec{SP}*		TTH_MATHC("sec");  
<equation>\\sin{SP}*		TTH_MATHC("sin");  
<equation>\\sinh{SP}*		TTH_MATHC("sinh");  
<equation>\\tan{SP}*		TTH_MATHC("tan");   
<equation>\\tanh{SP}*		TTH_MATHC("tanh");  

<equation>\\Pr{SP}*(\\(no)?limits{SP}*)?	|
<equation>\\inf{SP}*(\\(no)?limits{SP}*)?     |
<equation>\\gcd{SP}*(\\(no)?limits{SP}*)?	|
<equation>\\det{SP}*(\\(no)?limits{SP}*)?	|
<equation>\\max{SP}*(\\(no)?limits{SP}*)?     |
<equation>\\min{SP}*(\\(no)?limits{SP}*)?     |
<equation>\\sup{SP}*(\\(no)?limits{SP}*)?     |
<equation>\\liminf{SP}*(\\(no)?limits{SP}*)?	|
<equation>\\limsup{SP}*(\\(no)?limits{SP}*)?	|
<equation>\\lim{SP}*(\\(no)?limits{SP}*)?	{
  if(strstr(yytext,"nolimit")){js2=0;}else{js2=1;}
  *(yytext+1+strcspn(yytext+1," \\"))=0;
  if(eqclose >tth_flev-1 || js2==0){          TTH_MATHC(yytext+1);
  }else{
    strcat(eqstr,TTH_CELL3);
    strcat(eqlimited,yytext+1);
    oa_removes=0;
    yy_push_state(getsubp);
    if(levhgt[eqclose] == 1) levhgt[eqclose]=2; /* Force fraction closure */
  }
 }
<equation>\\mathop{WSP}*\{ |
<equation>\\(over|under)brace{WSP}*\{ {
 if(eqclose > tth_flev-1 || !displaystyle ){
   unput('{');
 }else{
  TTH_INC_MULTI; 
  strcat(eqstr,TTH_CELL3);
  mkkey(eqstr,eqstrs,&eqdepth);
  eqclose++;
  if(tth_flev<0)tth_flev=tth_flev-99;
  TTH_PUSH_CLOSING;
  active[eqclose-1]=30;
    /*TTH_PRETEXCLOSE("\\tth_eqlimited");*/
  oa_removes=0;
  if(*(yytext+1) == 'o'){
    TTH_CCPY(closing,TTH_OBRB);
    strcpy(eqstr,TTH_OBR);
  }else if(*(yytext+1) == 'u'){
    TTH_CCPY(closing,TTH_OBR);
    strcpy(eqstr,TTH_OBRB); 
  }else {
    strcpy(eqstr,"");
    unput(' ');
  }
  mkkey(eqstr,eqstrs,&eqdepth);
  *eqstr=0;
  tophgt[eqclose]=1;
  levhgt[eqclose]=1;
  active[eqclose]=1;
  unput('{');
 }
}
<equation>\\tth_eqlimited  { /* not done eqlimited section for mathop, overbrace */
    if(tth_debug&2)fprintf(stderr,"Mathop eqlimited:%s\n",eqstr);
    if(strlen(eqlimited)+strlen(eqstr)< TTH_DLEN) {
      strcat(eqlimited,eqstr);
      if(tth_debug&2)fprintf(stderr,"EQLIMITED=||%s||\n",eqlimited);
    }else{
      fprintf(stderr,
          "Error: Fatal! Exceeded eqlimited storage. Over/underbrace too long.\n");
      TTH_EXIT(5);
    }
    *eqstr=0;
    /*strcpy(eqstr,eqstrs[eqdepth-1]);*/
    yy_push_state(getsubp);  /*Does not work here */
    if(levhgt[eqclose] == 1)levhgt[eqclose]=2; /* Force fraction closure */
    /*active[eqclose-1]=0;*/
}
 /* end of symbols */

<equation>\\ensuremath    /* Nothing needs doing */
<equation>\\overrightarrow	TTH_SWAP("\\buildrel\\rightarrow\\over ");
<equation>\\overleftarrow	TTH_SWAP("\\buildrel\\leftarrow\\over ");

 /* Above accents expressed with braces. Removed {WSP} 11 Apr */
<equation>\\bar\{.\} { /* single character bar; convert to \sar */
  *(yytext+1)='s';
  TTH_SCAN_STRING(yytext);
 }
<equation>\\qrt\{       |
<equation>\\(wide)?hat\{   |
<equation>\\vec\{   |
<equation>\\(wide)?tilde\{ |
<equation>\\dd?ot\{   |
<equation>\\sar\{   |    /* single character bar tth special; see above */
<equation>\\bar\{	|    /* using a rule for multiple characters barred.*/ 
<equation>\\overline\{ {
  if(tth_debug&2) {
    fprintf(stderr,"Start Overaccent {, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s.\n",eqdepth,eqclose,tth_flev,levdelim[eqclose]);
  }
  if(*(yytext+2)=='d') *(yytext+1)='2';
  if(strstr(yytext,"wide")==yytext+1) yytext=yytext+4; /* skip wide */
  if(eqclose > tth_flev && *(yytext+1)=='q'){TTH_OUTPUT(scratchstring);}
  if(eqclose > tth_flev && tth_istyle&2 && *(yytext+1)!='q'){
    /* Testing of stylesheet aproach for inline use: -w2 not Netscape. */
    switch(*(yytext+1)){
    case 'h':      TTH_OUTPUT("<span class=\"overacc1\">");TTH_MATHI(217);
      TTH_OUTPUT("</span>");break;
    case 't':TTH_OUTPUT("<span class=\"overacc1\">~</span>");break;
    case 'o': case 'b': case 's': 
      TTH_OUTPUT("<span class=\"overacc2\">");TTH_MATHI(190);
      TTH_OUTPUT("</span>");break;
    case 'd':TTH_OUTPUT("<span class=\"overacc1\">&#183; </span>");break;
    case '2':TTH_OUTPUT("<span class=\"overacc1\">&#183;&#183; </span>");break;
    case 'v':
      TTH_OUTPUT("<span class=\"overacc2\">");TTH_MATHI(174);
      TTH_OUTPUT("</span>");break;
    }
  }else{ /*Display or non-style in-line*/
    mkkey(eqstr,eqstrs,&eqdepth);
    eqclose++;
    *eqstr=0;
    if(tth_flev<0)tth_flev=tth_flev-99;
    TTH_PUSH_CLOSING;
    if(eqclose > tth_flev){ /* Inline levels will be enclosed in [()]. */
      TTH_CCPY(closing,"");
      switch(*(yytext+1)){
      case 'o': case 'b': case 's': TTH_MATHS("`");break;
      case 'd': TTH_CCPY(closing,"\\dot");break;
      case '2': TTH_CCPY(closing,"\\ddot");break;
      case 't': TTH_CCPY(closing,"\\tilde");break;
      case 'h': TTH_MATHC("^");break;
      case 'v': TTH_CCPY(closing,"\\vec");break;
      case 'q': /* output moved above to fix inline */ break;
      default : fprintf(stderr,"Overaccent error:%s,%d\n",yytext,*(yytext+1));
      }
    }else{ /* Display case*/ 
      TTH_CCPY(closing,TTH_OA3);
      switch(*(yytext+1)){
      case 'o': strcpy(eqstr,TTH_DIV);
	strcat(eqstr,TTH_OA5);TTH_CCPY(closing,TTH_OA3);
	break;
      case 'b': case 's': TTH_OUTPUT(TTH_OA1);
	TTH_OUTPUT((tth_istyle&1 ? "-":"_"));TTH_OUTPUT(TTH_OA2);break;
      case 'd': TTH_OUTPUT(TTH_OA1); 
	if(tth_istyle&1) {TTH_MATHI(215);} else {TTH_OUTPUT(".");}
	TTH_OUTPUT(TTH_OA2);break;
      case '2': TTH_OUTPUT(TTH_OA1);
	if(tth_istyle&1) {TTH_MATHI(215);TTH_MATHI(215);} else 
	  {TTH_OUTPUT("..");} TTH_OUTPUT(TTH_OA2);break;
	  /* case '2': strcpy(eqstr,"..<br />");break; */
      case 't':TTH_OUTPUT(TTH_OA1);TTH_OUTPUT("~");strcat(eqstr,TTH_OA2);break;
      case 'h':TTH_OUTPUT(TTH_OA1);TTH_OUTPUT("^");strcat(eqstr,TTH_OA2);break;
      case 'v':TTH_OUTPUT(TTH_OA1);TTH_MATHI(174);TTH_OUTPUT(TTH_OA2);break;
	/* case 'v': TTH_MATHI(174);strcat(eqstr,"<br />");break; */
      case 'q': {
      if(tth_debug&2)fprintf(stderr,"qrtlen=%d\n",qrtlen);
      sprintf(eqstr,"</td><td nowrap=\"nowrap\" align=\"left\">%s&nbsp;&nbsp;",TTH_OA1);
      for(i=0;i<qrtlen2;i++) strcat(eqstr,"&nbsp;");
      if(tth_istyle&1){
	TTH_OUTPUT(TTH_SYMBOL);
	chr1[0]=190;
	for(i=0;i<0.6*qrtlen-.22;i++) strcat(eqstr,TTH_SYMPT(chr1));
	TTH_OUTPUT(TTH_SYMEND);
      }else       for(i=0;i<qrtlen;i++) strcat(eqstr,"_");
      TTH_OUTPUT(TTH_OA2);
      strcat(eqstr,TTH_large);
      TTH_OUTPUT(scratchstring);
      strcat(eqstr,TTH_SIZEEND);
      break;
      }
      default : fprintf(stderr,"Overaccent error:%s,%d\n",yytext,*(yytext+1));
      }
    }
    mkkey(eqstr,eqstrs,&eqdepth);
    *eqstr=0;
    tophgt[eqclose]=1; /* Was 2 since it is symmetrical */
    levhgt[eqclose]=1;
    active[eqclose]=1;
  }
  unput('{');
}

  /* Implementing sqrt as a command with optional argument.*/
<equation>\\sqrt TTH_SCAN_STRING("\\expandafter\\tthsqrtexp");
<equation>\\tthsqrtexp  TTH_TEX_FN_OPT("\\tth_sqrt#tthdrop2",2,"");
<psub>\\tth_sqrt#tthdrop2 {
  if((jscratch=indexkey("#1",margkeys,&margmax))!=-1)
    strcpy(scrstring,margs[jscratch]);
  else fprintf(stderr,"Error getting sqrt 1st argument");
  qrtlen2=strlen(scrstring);
  if((jscratch=indexkey("#2",margkeys,&margmax))!=-1){
    chr1[0]=214;
    if((js2=strlen(margs[jscratch]))==1 && !qrtlen2){ /* Single character */
      if(qrtlen2){ /* optional argument root of */
	sprintf(scratchstring,"<sup>%s%s%s</sup>",
		TTH_FOOTNOTESIZE,scrstring,TTH_SIZEEND);
	TTH_OUTPUT(scratchstring);
      }
      sprintf(dupstore,"{\\surd %s}",margs[jscratch]);
      TTH_SCAN_STRING(dupstore);
      *dupstore=0;
    }else if(strcspn(margs[jscratch],"{}\\")==js2
	     && !(tth_istyle&1)     /* Only for non-compressed */
	     && !qrtlen2    /* And non index */
	     ){/* multiple char qrt case.*/
      sprintf(scratchstring,"%s%s%s",TTH_SYMBOL,TTH_SYMPT(chr1),TTH_SYMEND);
      sprintf(dupstore,"\\qrt{%s}",margs[jscratch]);
      qrtlen=strlen(dupstore)-6;
      js2=0;
      chscratch=dupstore+5;
      while((jscratch=strcspn(chscratch," )(^_")) != strlen(chscratch)){
	js2++;
	chscratch=chscratch+jscratch+1;
	if(!strcspn((chscratch-1),"^_"))js2++;
      }
      qrtlen=qrtlen-(0.5*js2);
      TTH_SCAN_STRING(dupstore);*dupstore=0;
    }else{ /* Default case, embedded groups or commands.  Or index*/
      if(qrtlen2){
	sprintf(scratchstring,
	   "<sup>%s%s%s</sup>%s%s%s",TTH_FOOTNOTESIZE,scrstring,TTH_SIZEEND,
		TTH_SYMBOL,TTH_SYMPT(chr1),TTH_SYMEND);
      }else{
	sprintf(scratchstring,"%s%s%s",TTH_SYMBOL,TTH_SYMPT(chr1),TTH_SYMEND);
      }
      if(eqclose > tth_flev-1 ) { /* put in braces if topped out */
	TTH_OUTPUT(scratchstring);
	TTH_MATHC("{");
	TTH_PUSH_CLOSING;
	/* TTH_CCPY(closing,"}"); Came in wrong order after fraction. 
	 so fixed in the dupstore call.*/
	if(tth_debug&2) {
	  fprintf(stderr,
	      "Start Sqrt {, eqdepth=%d, eqclose=%d, tth_flev=%d, levdelim=%s.\n"
		  ,eqdepth,eqclose,tth_flev,levdelim[eqclose]);
	}
	mkkey(eqstr,eqstrs,&eqdepth);
	*eqstr=0;
	if(tth_flev < 0) tth_flev=tth_flev-99;
	eqclose++;
	tophgt[eqclose]=0;
	levhgt[eqclose]=1;
	sprintf(dupstore,"%s}\\}",margs[jscratch]);	
      }else{ /* use overline */
	sprintf(dupstore,"{\\overline{%s}\\tth_makeroot}",margs[jscratch]);
	tth_root_depth++;
	/* pass to delimit code via global stack. */
	TTH_SCAN_STRING(dupstore); /* defer the contents scan. Do index */
	tth_flev=tth_flev-99;  /* No built-up in index */
	/* use double braces to ensure inline enclosure works correctly. */
	sprintf(dupstore,"{{%s}\\tth_rootindex}",scrstring);
      }
      TTH_SCAN_STRING(dupstore);
      *dupstore=0;
    }
    yy_pop_state();
    rmdef(margkeys,margs,&margmax);    /* Dump two arguments */
    rmdef(margkeys,margs,&margmax);
  }else{fprintf(stderr,"Error finding sqrt argument");}
} /* end of tth_sqrt*/
<equation>\\tth_rootindex  {
    TTH_CCPY(tth_root_index[tth_root_depth],eqstr);
    tth_root_len[tth_root_depth]=strlen(eqstr);
    *eqstr=0;
    tth_flev=tth_flev+99;
}
<equation>\\tth_makeroot   strcpy(levdelim[eqclose],"&#214;");


 /* Above accents etc without braces: embrace following token (and rescan). */
<equation>\\sqrt{WSP}*   |
<equation>\\(wide)?hat{WSP}*   |
<equation>\\vec{WSP}*   |
<equation>\\(wide)?tilde{WSP}* |
<equation>\\dd?ot{WSP}*   |
<equation>\\bar{WSP}*	|
<equation>\\overline{WSP}*   {  /* overline needs leading WSP */
  TTH_INC_MULTI; 
  strcpy(dupstore,yytext);
  *(dupstore+strcspn(dupstore," \t\r\n"))=0;
  /* yy_push_state(embracetok); OLD */
  *expchar=0;TTH_CCPY(exptex,dupstore);*dupstore=0;
  yy_push_state(exptokarg); /* overaccent */
 }
<equation>\\eqno[^\$]*\$\$ { /*This is default.*/
  TTH_INC_MULTI;
  if((tth_flev > 0 )){
    strcpy(scrstring,yytext+5);
    *(scrstring+strlen(scrstring)-2)=0;
    sprintf(scratchstring,"}\\special{html:%s}%s\\tth_endnumbered",
	    (eqalignlog ? TTH_DISP5 : TTH_DISP3),scrstring);
    /*fprintf(stderr,"Ending eqno: %s\n",scratchstring); */
    TTH_SCAN_STRING(scratchstring);
  }else{
    yyless(5);  TTH_MATHC("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
  }
 }
<equation>\\eqno     { /* Fallback only */
  if((tth_flev > 0 ) && (eqaligncell)) {
    tth_enclose(TTH_EQ1,eqstr,TTH_EQ4,eqstore);
    strcat(eqstr,TTH_CELL4);
  }
  TTH_MATHC("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
 }
<equation>\\[Bb]ig[lmr]?{WSP}* {
  TTH_INC_MULTI; 
  TTH_SCAN_STRING("\\left.\\tth_size2\\right");
 }
<equation>\\[Bb]igg[lmr]?{WSP}* {
  TTH_INC_MULTI; 
  TTH_SCAN_STRING("\\left.\\tth_size3\\right");
 }
<equation>\\tth_size2  levhgt[eqclose]=2;
<equation>\\tth_size3  levhgt[eqclose]=3;
<equation>\\left{WSP}*     {
  TTH_INC_MULTI;yy_push_state(bigdel);strcpy(scratchstring,"{");}
<equation>\\right{WSP}*    {
  TTH_INC_MULTI;yy_push_state(bigdel);strcpy(scratchstring,"}");}

<equation>\\global         ;
<equation>\\bmath          ;
<equation>\\textstyle {
  if(eqdepth>2){ /* Problem with implied grouping of an eq insufficient.
                    to end dupgroup. So avoid such situations.*/
    tth_flev=tth_flev-99;
    TTH_CCPY(argchar,"\\tth_endtextstyle");
    storetype=5;
    yy_push_state(dupgroup);
  }
}
<equation>\\tth_endtextstyle  tth_flev=tth_flev+99;
<equation>\\displaystyle
<equation>\\scriptstyle
<equation>\\smash

  /* Default equation actions. */
  /* Was single character. IE gave problems. */
<equation>[a-zA-Z]+  {
    strcat(eqstr,tth_font_open[tth_push_depth]);
    strcat(eqstr,yytext);
    strcat(eqstr,tth_font_close[tth_push_depth]);
 }

<equation>{SP}*      TTH_MATHC(" ");
<equation>[ ]=[ ]           |
<equation>\\(%|$|&|#|\\|_)  |
<equation>[()\[\]]          |
<equation>[+\-\*=/\.,:;\?!] |
<equation>[0-9]*  { 
  if(*(yytext) == '\\'){ chscratch=yytext+1;} else {chscratch=yytext;}
  if(*chscratch=='&')chscratch="&amp;";
  /* If the font has been changed, use it for non-letters too */
  if(!tth_mathitalic || strcmp(tth_font_open[tth_push_depth],TTH_ITAL1)!=0 ){
    strcat(eqstr,tth_font_open[tth_push_depth]);
    strcat(eqstr,chscratch);
    strcat(eqstr,tth_font_close[tth_push_depth]);
  }else{
    strcat(eqstr,chscratch);
  }
}
<equation>{WSP}*={WSP}*     TTH_INC_MULTI; TTH_SCAN_STRING(" = ");



  /**** tth pseudo-TeX ******/
<equation>#tthbigsup {
  if(tth_debug&8) fprintf(stderr,"#tthbigsup, eqhgt=%d\n",eqhgt);
  strcat(eqstr,TTH_BR);
  *expchar=0;
  if(strlen(eqlimited)){
    tth_symext(eqlimited,eqstr+strlen(eqstr));
    *eqlimited=0;
    for(i=0;i<oa_removes;i++){TTH_CCAT(expchar,TTH_OA4);}
    oa_removes=0;
  }else{
    for(i=1;i<=eqhgt-2;i++){
      strcat(eqstr,TTH_BRN);
    }
  }
  if(!strlen(expchar)){TTH_CCAT(expchar,TTH_NULL_BOTTOM);}  /* IE fix */
  TTH_CCAT(expchar,TTH_CELL3); /* make compatible with cell trim code. */
  yy_push_state(exptokarg); /* tthbigsup code */
 }
<equation>\\tth_eqfin { /* Finish an eq group and attach to previous key */
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

<getsubp>{WSP}*   {
 TTH_INC_MULTI;
} 
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
\\tthscriptsize {
  if(tth_htmlstyle&4){
    TTH_OUTPUT("<span class=\"smaller\">");TTH_PRECLOSE("</span>");
  }else{
    TTH_OUTPUT("<small>");TTH_PRECLOSE("</small>");
  }
}
<getsubp>. { /* No more subp's */
  if(*yytext != '#') yyless(0);
  storetype=0;
  yy_pop_state();
  if(strlen(supstore) || strlen(substore)){ /* Need to deal with subp */
    strcpy(dupstore,"{\\tthscriptsize{");
    strcat(dupstore,supstore);
    strcat(dupstore,"}}#tthbigsup{\\tthscriptsize{");
    strcat(dupstore,substore);
    strcat(dupstore,"}}");
    if(tth_istyle&1) eqhgt=0.8*hgt+0.7; else eqhgt=hgt;
    if(tth_debug&8)fprintf(stderr,"Scanning subpscripts:%s\n",dupstore);
    TTH_SCAN_STRING(dupstore);
    *dupstore=0;
    *argchar=0;
    *supstore=0;
    *substore=0;
    strcpy(expchar,"<!--sup\n-->"); /* make non-null */
    yy_push_state(exptokarg); /* scanning subpscripts */
  }else if(strlen(eqlimited)){ /* No delimiters but a limited symbol */
    tth_symext(eqlimited,eqstr+strlen(eqstr));
    for(i=0;i<oa_removes;i++){strcat(eqstr,TTH_OA4);}
    oa_removes=0;
    strcat(eqstr,"</td><td nowrap=\"nowrap\">");
    *eqlimited=0;
  }  
 }

 /* New big, left, right, delimiters section */

<bigdel>(\\\{|\\lbrace)   { 
  yy_pop_state();strcpy(levdelim[eqclose+1],"{");unput(*scratchstring);}
<bigdel>(\\\}|\\rbrace)   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"}");unput(*scratchstring);}
<bigdel>\(   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"(");unput(*scratchstring);}
<bigdel>\)   {
  yy_pop_state();strcpy(levdelim[eqclose+1],")");unput(*scratchstring);}
<bigdel>(\[|\\lbrack)   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"[");unput(*scratchstring);}
<bigdel>(\]|\\rbrack)   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"]");unput(*scratchstring);}
<bigdel>\\lceil   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&#233;");unput(*scratchstring);}
<bigdel>\\rceil   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&#249;");unput(*scratchstring);}
<bigdel>\\lfloor   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&#235;");unput(*scratchstring);}
<bigdel>\\rfloor   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&#251;");unput(*scratchstring);}
<bigdel>\\langle   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&#225;");unput(*scratchstring);}
<bigdel>\\rangle   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"&#241;");unput(*scratchstring);}
<bigdel>(\||\\vert)   {
  yy_pop_state();strcpy(levdelim[eqclose+1],"|");unput(*scratchstring);}
<bigdel>(\/|\\backslash)   {
  yy_pop_state();*levdelim[eqclose+1]=*yytext;unput(*scratchstring);}
<bigdel>\.   yy_pop_state();*levdelim[eqclose+1]=0;unput(*scratchstring);
<bigdel>. { /* unknown bigdelimiter; make blank and then rescan. */
  yy_pop_state();yyless(0);
  TTH_SCAN_STRING(scratchstring);
}



