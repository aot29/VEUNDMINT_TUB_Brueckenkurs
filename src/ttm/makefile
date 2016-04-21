MINGW=mingw
GCC=gcc -O
TARS= tars/tthgoldC.tgz tars/tthgoldL.tar.gz  tars/ttmC.tar.gz\
 tars/ttmL.tar.gz  tars/tthgoldW.exe tars/ttmW.exe

unopt : tth.c
	gcc -o tth -Wall tth.c
	sleep 1s
	date > unopt

# The full tth.lex and ttm.lex are constructed from 3 files.

tth.lex : tthg.lex mathstringsh.lex equationh.lex makefile
	sed -e "/mathstringshl/ r mathstringsh.lex" -e "/equationhl/r equationh.lex" tthg.lex >tth.lex

ttm.lex : tthg.lex mathstringsm.lex equationm.lex makefile
	sed -e "/mathstringshl/ r mathstringsm.lex"\
 -e "/equationhl/r equationm.lex"\
 -e "s/static void delimit();//"\
 -e "s/static int b_align();//"\
 -e "s/[.]html/.xml/"\
 -e "/-f? limit/d"\
 -e "/-i use/d"\
 -e "/-t display/d"\
 -e "/-y? equa/d"\
 -e "/-w? HTML/,/-w2 XHTML/d"\
 -e "/oa_removes/c\\" -e ""\
 -e "/start b_align/,/end b_align/c\\" -e ""\
 -e "/start symext/,/end symext/c\\" -e ""\
 -e "/start delimit/,/end delimit/c\\" -e "" tthg.lex >ttm.lex

ttm.c : ttm.lex
	flex -ottm.c ttm.lex

ttm : ttm.c
	gcc -o ttm -Wall ttm.c

tth.c : tth.lex
	flex -otth.c tth.lex

tth : tth.c
	$(GCC) -o tth -Wall tth.c

# The tars are individual packages. Win32, Linux, C.

tars: manual $(TARS)

tars/tthgoldW.exe : tth.exe gui
	zip -r tars/tthgoldW tthgold/*.* tthgold/babel -x */*.c
	cat SFXWiz32-gcc.exe tars/tthgoldW.zip >tars/tthgoldW.exe
	zip -A tars/tthgoldW.exe

tars/tthgoldL.tar.gz : tthstatic 
	tar czvhf tars/tthgoldL.tar.gz tthgold/tth tthgold/tthprep\
 tthgold/tthprep.sty tthgold/gold_man.tex tthgold/gold_man.html\
 tthgold/tth_man.tex tthgold/tth_man.html tthgold/README.txt tthgold/tthsplit\
 tthgold/amslatex.sty tthgold/babel/* tthgold/latex2gif\
 tthgold/tth.gif tthgold/tth.1 tthgold/tthrfcat\
 tthgold/tthntbib.sty  tthgold/tthxspac.sty tthgold/license.txt

tars/tthgoldC.tgz : tth.c
	tar czvhf tars/tthgoldC.tgz tthgold/tth.c tthgold/tthprep\
 tthgold/tthprep.bat tthgold/tthprep.sty tthgold/gold_man.tex\
 tthgold/gold_man.html tthgold/tth_man.tex tthgold/tth_man.html\
 tthgold/README.txt tthgold/tthsplit.c tthgold/amslatex.sty\
 tthgold/babel/* tthgold/latex2gif\
 tthgold/tth.gif tthgold/tth.1 tthgold/tthrfcat.c\
 tthgold/tthntbib.sty tthgold/tthxspac.sty tthgold/license.txt

tth.exe : tth.c tth.res
	@echo Using $(MINGW) to create tth.exe 
	$(MINGW) -o tth.exe tth.res tth.c

tthgold/tth.exe : tth.c
	@echo Using $(MINGW) to create tth.exe
	$(MINGW) -o tth.exe tth.res tth.c

tars/ttmW.exe :  TtMdir/readme.ttm ttm.exe manual/ttm_manual.html
	rm -f tars/ttmW.zip
	zip -r tars/ttmW.zip TtMdir/*.*
	cat SFXWiz32-gcc.exe tars/ttmW.zip >tars/ttmW.exe
	zip -A tars/ttmW.exe

tars/ttmC.tar.gz : ttmC/* manual/ttm_manual.html ttm.c
	tar czvhf tars/ttmC.tar.gz ttmC/*

tars/ttmL.tar.gz :  ttmstatic ttmL/* ttm manual/ttm_manual.html
	tar czvhf tars/ttmL.tar.gz ttmL/*

ttmL/ttm_manual.html : manual/ttm_manual.html

ttmstatic : ttm.c
	gcc -static -o ttmstatic ttm.c

tthstatic : tth.c
	gcc -static -o tthstatic tth.c

ttm.exe : ttm ttm.c ttm.res makefile
	$(MINGW) -o ttm.exe ttm.res ttm.c

manual : split tth manual/ttm_manual.html
	make -C manual

manual/ttm_manual.html : split tth manual/tth_manual.tex
	make -C manual ttm_manual.html

gui :
	make -C tth-gui

split :
	make -C tools

transfer : tth.lex tth.exe CHANGES
	date >transfer
	scp CHANGES hutch@silas:~/tth/CHANGES
	scp tth.lex hutch@silas:~/tth/tth.lex
	scp tth.exe hutch@silas:~/tth/tth.exe
	scp manual/tth_manual.tex hutch@silas:~/tth/
	ssh silas /home/hutch/bin/maketth

ttmtransfer : ttm.exe ttmstatic tars/ttmW.exe tars/ttmL.tar.gz tars/ttmC.tar.gz
	scp tars/ttmW.exe hutch@silas:~/tth/TtM/ttmW.exe
	scp tars/ttmL.tar.gz hutch@silas:~/tth/TtM/ttmL.tar.gz
	scp tars/ttmC.tar.gz hutch@silas:~/tth/TtM/ttmC.tar.gz
	scp ttmstatic hutch@silas:~/tth/TtM/ttm

clean :
	rm -f ttmstatic
	rm -f tthstatic
	rm -f ttm.c
	rm -f tth.c
	rm -f opt unopt
	rm -f tars/*.gz tars/*.zip tars/*.tgz tars/*.exe
	rm -f tth tth tth.exe ttm ttm.exe 
	rm -f tth.lex ttm.lex
	make -C manual clean
	make -C tth-gui clean
	make -C tools clean
	make -C tthfunc clean

version : tthg.lex
	sed -n -e "/define TTH_VERSION/p" tthg.lex | sed -e 's/#define TTH_VERSION "//' -e 's/"//' > version

tarball : clean version
	@cd ..; tar --exclude-vcs --exclude=*.tar.gz -czf tth/tth`cat tth/version`.tar.gz tth; echo Made distribution tar ball.