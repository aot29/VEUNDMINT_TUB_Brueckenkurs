/*
Concatenate reference files produced by TtH
Copyright 2000 I.H.Hutchinson.
*/
#ifdef MSDOS
#define RMCMD "del"
#define COPY "copy"
#else 
#define RMCMD "rm"
#define COPY "cp"
#endif

#define LINELEN 256
#include <stdio.h>
#include <string.h>
#define TEMPFILE "refs.temp"
main(argc,argv)
int argc;
char *argv[];
{
int ifile,ifinal;
char *ch,*ch2;
char cmdline[LINELEN];
char bound[LINELEN];
char buff[LINELEN];
FILE *tempfile, *reffile;
 if(argc > 1){ 
   printf( "Usage: tthrfcat \n Concatenate refs.html files (destructively) from TtH.\n"); 
   return 1;
 }
 if((tempfile=fopen(TEMPFILE,"w"))!=NULL){
   fprintf(stderr,"%s opened\n",TEMPFILE);
 }else{
   fprintf(stderr,"Can't open %s\n",TEMPFILE);
   return 2;
 }
 for(ifile=0;ifile<100;ifile++){
   if(ifile) sprintf(bound,"refs%d.html",ifile);
   else strcpy(bound,"refs.html");
   if((reffile=fopen(bound,"r"))!=NULL){
     fprintf(stderr,"Read %s ",bound);

     do {
       ch2=fgets(buff,LINELEN,reffile);
       ch=strstr(buff,"</title>");
	 if(!ifile){ /* Put all the top stuff only from first file */
	   fputs(buff,tempfile);
	 }
     } while (ch2!=NULL && ch == NULL); /* in header lines down to </title> */

     while(fgets(buff,LINELEN,reffile) != NULL){
       if(!strstr(buff,"</head>") && !strstr(buff,"<body>") || !ifile) 
	 if(strstr(buff,"</html>") || strstr(buff,"</body>") ){
	   break; /*from while*/
	 }else{
	   fputs(buff,tempfile);
	 }
     }
     fclose(reffile);
     if(ifile) {
       fprintf(stderr,"... removed\n");
       sprintf(cmdline,"%s %s",RMCMD,bound);
       system(cmdline);
     }else fprintf(stderr,"\n");
   }else{
     fputs(buff,tempfile);
     if(!strstr(buff,"</html>"))fputs("</html>",tempfile);
     ifinal=ifile;
     break;
   }
 }
 fclose(tempfile);
 if(ifinal > 1){
   sprintf(bound,"%s %s refs.html",COPY,TEMPFILE);
   system(bound);
   sprintf(bound,"%s %s",RMCMD,TEMPFILE);
   system(bound);
 }else{
   fprintf(stderr,"Nothing to be done. Removing temporary file.\n");
   sprintf(bound,"%s %s",RMCMD,TEMPFILE);
   system(bound);
 }
}



