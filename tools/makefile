# Builds the multi-language version
#
# Will be integrated in the continuous integration server (when it's there)
# Remember to always use tabs instead of spaces
#
# invoke as:
#
# cd VEUNDMINT checkout path
# make -f tools/makefile
#
# Works only on Unix systems
#

.DEFAULT_GOAL := all
BASEDIR = "../src"
OUTPUT = tu9onlinekurstest
STARTPAGE = sectionx3.1.0.html


build_DE:
	# prefixed with "-" to ignore converter errors
	-cd $(BASEDIR) && python3 tex2x.py VEUNDMINT lang=de output=$(OUTPUT)_de


build_EN:
	# prefixed with "-" to ignore converter errors
	-cd $(BASEDIR) && python3 tex2x.py VEUNDMINT lang=en output=$(OUTPUT)_en


#all: build_DE build_EN
all:
	mv $(OUTPUT)_de $(OUTPUT)

	# move German HTML from /html to /html/de
	mv $(OUTPUT)/html $(OUTPUT)/de
	mkdir $(OUTPUT)/html
	mv $(OUTPUT)/de $(OUTPUT)/html

	# move English HTML to /html/en
	mv $(OUTPUT)_en/html $(OUTPUT)/html/en

	# fix links to common (de/en) external files
	cd $(OUTPUT)/html
	ln -s ../*.js .
	ln -s ../*.png .
	ln -s ../images .
	ln -s ../qtip2 .
	ln -s ../css .
	ln -s ../datatables .
	ln -s ../fonts .
	ln -s ../i18n .
	ln -s ../MathJax .

	# fix links in German version
	cd $(OUTPUT)/html/de && find . *.html -type f -exec sed -i "s|href=\"\.\./html|href=\"\.\./de|g" {} \;
	cd $(OUTPUT)/html/de && find . *.html -type f -exec sed -i "s|href=\"\.\./\.\./html|href=\"\.\./\.\./de|g" {} \;

	# fix links in English version
	cd $(OUTPUT)/html/en && find . *.html -type f -exec sed -i "s|href=\"\.\./html|href=\"\.\./en|g" {} \;
	cd $(OUTPUT)/html/en && find . *.html -type f -exec sed -i "s|href=\"\.\./\.\./html|href=\"\.\./\.\./en|g" {} \;
