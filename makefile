SOFTWARE_REPOSITORY = git@gitlab.tubit.tu-berlin.de:stefan.born/VEUNDMINT_TUB_Brueckenkurs.git
SUBMODULE_DIR = ./content_submodule

#
# Use this target after checking out the content branch first time around.
# 
install: clean
	# add the content as a submodule
	git submodule add --force -b ${branch}  ${SOFTWARE_REPOSITORY} ${SUBMODULE_DIR}
	
	# updates the linked submodules
	git submodule init
	git submodule update

	# install a Python virtual environment and all dependencies	
	$(MAKE) -f tools/makefiles/devinstall

	# unstage submodules, as these may be different for other users
	git reset HEAD content_submodule
	git reset HEAD .gitmodules


#
# Build the course with all languages available.
#
all:
ifeq ($(course),PhysikBK)
	# link to actual physics tex-tree to he name expected by the script
	#ln -sf $(CURDIR)/content_submodule/content/tree_physik_bk.tex 
$(CURDIR)/content_submodule/content/tree_de.tex
	# call the makefile, with overrides, skip creating PDF
	$(MAKE) -f tools/makefiles/makefile OVERRIDE="'description=Onlinebrückenkurs Physik'" nopdf
	# forward to the first page
	-rm $(CURDIR)/public/index.html
	cp $(CURDIR)/src/templates_xslt/html5_redirect_basic.html $(CURDIR)/public/index.html
	find $(CURDIR)/public -maxdepth 1 -name 'index.html' -type f -exec sed -i "s|\$$url|/html/de/sectionx2.1.0.html|g" {} \;
else
	$(MAKE) -f tools/makefiles/multilang
endif
	# if everything went well, you can now start a server by doing
	# npm run gulp watch


#
# Build the default course but skip PDF generation
#
nopdf:
	$(MAKE) -f tools/makefiles/multilang nopdf


#
# Updates the source code and the content submodules
#
update:
	git pull
	git submodule update --remote


#
# Remove any submodules 
#
clean:
	-git submodule deinit -f ${SUBMODULE_DIR}
	-git rm -rf ${SUBMODULE_DIR}
	-rm -rf .git/modules/${SUBMODULE_DIR}

	
#
# Run the test suite on localhost
#
test:
	$(MAKE) -f tools/makefiles/test localhost
