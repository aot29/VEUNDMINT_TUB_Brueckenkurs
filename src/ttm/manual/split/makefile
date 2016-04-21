LATEX=latex
TTH=../../tth -a
# If latex is not installed, try the following fall-back:
#LATEX=echo
#TTH=../tth

index.html : ../tth_manual.tex
	$(TTH) -s -e2 <../tth_manual.tex -L../tth_manual -p../ | ../../tools/tthsplit

tidy :
	rm -f *.log *.idx *.ilg *.toc *.out *.dvi *.lyx *.tms *.tid *.tin *.ind

clean :
	rm -f *.log *.idx *.ilg *.html *.toc *.out *.dvi *.lyx *.tms *.tid *.tin *.ind *.aux