SOFTWARE_REPOSITORY = git@gitlab.tubit.tu-berlin.de:stefan.born/VEUNDMINT_TUB_Brueckenkurs.git
SUBMODULE_DIR = content_submodule

#
# Use this target after checking out the content branch first time around.
# 
install: clean
	# add the software as a submodule
	git submodule add -b ${branch} ${SOFTWARE_REPOSITORY} ${SUBMODULE_DIR}
	
	# updates the linked submodules
	git submodule init
	git submodule update

	# install a Python virtual environment and all dependencies	
	$(MAKE) -f tools/makefiles/devinstall


#
# Build the course with all languages available.
#
all:
ifeq ($(course),PhysikBK)
	$(MAKE) -f tools/makefiles/makefile OVERRIDE="'description=Onlinebrückenkurs Physik'"
else
	$(MAKE) -f tools/makefiles/multilang
endif


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
