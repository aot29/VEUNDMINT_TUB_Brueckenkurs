# Builds the multi-language version
#
# This file is here for 2 reasons:
# 1. This could be implemented in Python, but in the present stage of development,
# it would be unwise to add the extra layer of complexity.
#
# 2. Some form of automation is necessary to setup the continuous integration server
#
# Caveats:
# * Remember to always use tabs instead of spaces!
# Specially when doing copy+paste, tabs will sometimes be replaced by spaces.
# Make will then throw a "missing separator" error.
# * This script should work on any Unix system, but the result should be cross-plattform,
# so specifically don't use softlinks (ln -s is bad).
#

# The shared command definitions file
include tools/makefiles/command_definitions.make

.DEFAULT_GOAL := all

# Path to source dir, relative to <VEUNDMINT checkout path>
BASEDIR = src

# Name of the output dir to be created
OUTPUT = build
SOURCE=content_submodule/content

# Language the index.html will point to by default,
# possible values: de, en
DEFAULT_LANG = de 

# Declare as phony so targets will run even if there's a file by that name
.PHONY: cleanupBefore convert_with_pdf convert_without_pdf merge fixlinks fixredirects cleanupAfter all movePDF


#
# Build everything for the bootstrap version
# Including PDFs
#
all: | cleanupBefore convert_with_pdf merge fixRedirects fix fixSpecialPages startGulp movePDF docs cleanupAfter
	echo "ready"

buildDE: 
	# set CURRENT_LANG at runtime.
	$(eval CURRENT_LANG := de)
	$(convert_cmd)
	# move German HTML from /html to /html/de
	mv $(OUTPUT)_${CURRENT_LANG} $(OUTPUT)
	mv $(OUTPUT)/html $(OUTPUT)/${CURRENT_LANG}
	mkdir $(OUTPUT)/html
	mv $(OUTPUT)/${CURRENT_LANG} $(OUTPUT)/html
	$(deploy_img_cmd)
	$(fixRedirects_cmd)
	$(fixLinks_cmd)
	$(setLocale_cmd)
	$(fixSpecialPages_cmd)


#
# Build everything for the bootstrap version
# WITHOUT PDFs
#
nopdf: |cleanupBefore convert_without_pdf merge fixRedirects fix fixSpecialPages startGulp docs cleanupAfter
	echo "ready"


#
# Build the English and the German version.
# including PDFs of whole course
#
convert_with_pdf:
	# set CURRENT_LANG at runtime.
	$(eval CURRENT_LANG := de)
	$(convert_cmd)
	$(pdf_cmd_physik)


#
# Build the English and the German version.
#
convert_without_pdf:
	# set CURRENT_LANG at runtime.
	$(eval CURRENT_LANG := de)
	$(convert_cmd)


#
# Merge the 2 versions together.
#
merge:
	mv $(OUTPUT)_de $(OUTPUT)

	# move German HTML from /html to /html/de
	mv $(OUTPUT)/html $(OUTPUT)/de
	mkdir $(OUTPUT)/html
	mv $(OUTPUT)/de $(OUTPUT)/html

	$(deploy_img_cmd)


#
# Copy redirect pages to each html/language directory
# Moved to its own target, to make sure it is done
# Before serach and replace starts in "fix" target.
#
fixRedirects:
	# set CURRENT_LANG to de
	$(eval CURRENT_LANG := de)
	$(fixRedirects_cmd)


#
# Move special pages to their definitive location
# this will overwrite some but not all redirect pages
#
fixSpecialPages:
	# set CURRENT_LANG to de
	$(eval CURRENT_LANG := de)
	$(fixSpecialPages_cmd)


#
# Fix the link paths in the HTML files
#
fix: fixRedirects
	# fix links to videos
	cd $(OUTPUT)/html && find . -name '*.html' -type f -exec sed -i "s|:localmaterial:|\.\./\.\./\.\./images|g" {} \;
	
	# set CURRENT_LANG to de
	$(eval CURRENT_LANG := de)
	$(fixLinks_cmd)

	# replace index.html to allow for choosing en or de version
	cp src/plugins/VEUNDMINT_TUB/templates/html5_choose_language_simple.html $(OUTPUT)/index.html


useScormIndex:
	# replace public/index.html for moodle
	cp src/plugins/VEUNDMINT_TUB/templates/html5_redirect_moodle.html public/index.html


#
# Cleanup before starting a new build
#
cleanupBefore:
	-rm -Rf $(OUTPUT)
	-rm -Rf $(OUTPUT)_en
	-rm -Rf $(OUTPUT)_de
	-rm -Rf _tmp
	-rm -Rf public


#
# Cleanup after a build is ready
#
cleanupAfter:
	-rm -Rf $(OUTPUT)
	-rm -Rf $(OUTPUT)_en
	-rm -Rf $(OUTPUT)_de
	-rm -Rf _tmp
	-rm -Rf doc


#
# starts gulp to produce dist version version if gulp command is found
# echo instruction how to proceed otherwise
#
startGulp:
	# running gulp and copying to /public
	@type npm >/dev/null 2>&1 && npm run gulp >/dev/null 2>&1 ||echo "npm does not exist. You need to install npm (node package manager) first. Then install project dependencies via 'npm install' and build the online version with 'gulp' or run this make script again after you installed npm and dependencies"

#
# Copy PDFs to public (move this and possibly other targets to gulp)
#
movePDF:
	-cp -R $(OUTPUT)/pdf public/
	
#
# Produce documentation
#
docs:
	doxygen doxygen.conf
	-cp -R doc public/
	
	
