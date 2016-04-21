LATEX=latex
TTH=../tth -a
# If latex is not installed, try the following fall-back:
#LATEX=echo
#TTH=../tth

all : tth_manual.html ttm_manual.html split/index.html

tth_manual.html : tth_manual.tex makefile
	$(LATEX) tth_manual
	$(TTH) tth_manual

ttm_manual.html : ttm_manual.tex
	$(LATEX) ttm_manual
	$(TTH) ttm_manual

ttm_manual.tex : tth_manual.tex
	./tth2ttm

split/index.html : tth_manual.tex
	make -C split

tidy :
	rm -f *.log *.idx *.ilg *.toc *.out *.dvi *.lyx *.tms *.tid *.tin *.ind

clean :
	rm -f *.log *.idx *.ilg *.html *.toc *.out *.dvi *.lyx *.tms *.tid *.tin *.ind *.aux