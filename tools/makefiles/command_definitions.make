#
# Use the converter to build the version specified by CURRENT_LANG
#
define convert_cmd
	# prefixed with "-" to ignore converter errors
	# now converting, don't worry about converter errors. This can take a while...
	-cd $(BASEDIR) && python3 tex2x.py VEUNDMINT lang=$(CURRENT_LANG) output=$(OUTPUT)_$(CURRENT_LANG) ${OVERRIDE} 
endef

#
# Deploy all images and videos to the images directory
#
define deploy_img_cmd
	# copy all math images (and logos)
	find ${STATIC}/ -iname \*.png -print0 | xargs -I{} -0 cp {} $(OUTPUT)/images
	find ${SOURCE}/ -iname \*.jpg -print0 | xargs -I{} -0 cp {} $(OUTPUT)/images
	find ${SOURCE}/ -iname \*.png -print0 | xargs -I{} -0 cp {} $(OUTPUT)/images
	# copy partner logos
	find src/files/images/ -iname logo_\*.png -print0 | xargs -I{} -0 cp {} $(OUTPUT)/images
	# copy additional images
	cp src/files/images/cclbysa.png $(OUTPUT)/images
	cp src/files/images/tbeispiel.png $(OUTPUT)/images
	# copy autogenerated images
	find autogenerated/ -iname \*.png -print0 | xargs -I{} -0 cp {} $(OUTPUT)/images
	# copy all videos
	find ${SOURCE}/ -iname \*.mp4 -print0 | xargs -I{} -0 cp {} $(OUTPUT)/images
endef

#
# Generate PDF of whole course
# @see: https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/wikis/pdf
#
define pdf_cmd
	# now building PDFs, this can take a while...
	cd _tmp/tex && pdflatex -interaction nonstopmode -halt-on-error -file-line-error veundmint_$(CURRENT_LANG).tex >> convert.log
	cd _tmp/tex && makeindex  -q veundmint_$(CURRENT_LANG)
	cd _tmp/tex && pdflatex -interaction nonstopmode -halt-on-error -file-line-error veundmint_$(CURRENT_LANG).tex >> convert.log
	-mkdir $(OUTPUT)_$(CURRENT_LANG)/pdf
	cp _tmp/tex/veundmint_$(CURRENT_LANG).pdf $(OUTPUT)_$(CURRENT_LANG)/pdf/
endef

#
# Generate PDF of whole course
# @see: https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/wikis/pdf
#
define pdf_cmd_physik
	# now building PDFs, this can take a while...
	cd _tmp/tex && pdflatex -interaction nonstopmode -halt-on-error -file-line-error tree1_physik_bk.tex >> convert.log
	cd _tmp/tex && makeindex  -q tree1_physik_bk
	cd _tmp/tex && pdflatex -interaction nonstopmode -halt-on-error -file-line-error tree1_physik_bk.tex >> convert.log
	mkdir $(OUTPUT)_$(CURRENT_LANG)/pdf
	cp _tmp/tex/tree1_physik_bk.pdf $(OUTPUT)_$(CURRENT_LANG)/pdf/veundmint_de.pdf
endef

#
# Don't use Unix softlinks here (ln -s),
# as the output should also work on non-Unixes.
#
define fixRedirects_cmd
	# copy HTML-redirects to each language version
	cd $(OUTPUT) && cp *.html html/$(CURRENT_LANG)
endef

# Move special pages to their definitive location.
# This should be dealt with in mintmod
define fixSpecialPages_cmd
	# Remove the single-language special pages	
	#-rm $(OUTPUT)/html/$(CURRENT_LANG)/data.html
	#-rm $(OUTPUT)/html/$(CURRENT_LANG)/signup.html
	#-rm $(OUTPUT)/html/$(CURRENT_LANG)/login.html
	#-rm $(OUTPUT)/html/$(CURRENT_LANG)/logout.html
	#-rm $(OUTPUT)/html/$(CURRENT_LANG)/search.html
	#-rm $(OUTPUT)/html/$(CURRENT_LANG)/favorites.html
	#-rm $(OUTPUT)/html/$(CURRENT_LANG)/test.html

	# Move special pages to their definitive location (for the current language)
	-cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -print | xargs grep '<!-- mdeclaresiteuxidpost;;VBKM_MISCCOURSEDATA;; //-->' -l | xargs -I '{}' cp '{}' data.html
	-cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -print | xargs grep '<!-- mdeclaresiteuxidpost;;VBKM_MISCSETTINGS;; //-->' -l | xargs -I '{}' cp '{}' signup.html
	-cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -print | xargs grep '<!-- mdeclaresiteuxidpost;;VBKM_MISCLOGIN;; //-->' -l | xargs -I '{}' cp '{}' login.html
	-cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -print | xargs grep '<!-- mdeclaresiteuxidpost;;VBKM_MISCLOGOUT;; //-->' -l | xargs -I '{}' cp '{}' logout.html
	-cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -print | xargs grep '<!-- mdeclaresiteuxidpost;;VBKM_MISCSEARCH;; //-->' -l | xargs -I '{}' cp '{}' search.html
	-cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -print | xargs grep '<!-- mdeclaresiteuxidpost;;VBKM_MISCFAVORITES;; //-->' -l | xargs -I '{}' cp '{}' favorites.html
	-cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -print | xargs grep '<!-- mdeclaresiteuxidpost;;VBKMT_START;; //-->' -l | xargs -I '{}' cp '{}' test.html

	#now correct the links
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\".*#L_CONFIG|href=\"\.\./$(CURRENT_LANG)/signup.html|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\".*#L_CDATA|href=\"\.\./$(CURRENT_LANG)/data.html|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\".*#L_LOGIN|href=\"\.\./$(CURRENT_LANG)/login.html|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\".*#L_LOGOUT|href=\"\.\./$(CURRENT_LANG)/logout.html|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\".*#L_SEARCHSITE|href=\"\.\./$(CURRENT_LANG)/search.html|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\".*#L_FAVORITESSITE|href=\"\.\./$(CURRENT_LANG)/favorites.html|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\".*#L_TEST01START|href=\"\.\./$(CURRENT_LANG)/test.html|g" {} \;

	# fix links in search page
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name 'search.html' -type f -exec sed -i "s|href=\"html/|href=\"|g" {} \;
endef

#
# Fix the links using shell commands.
# Don't use Unix softlinks here (ln -s),
# as the output should also work on non-Unixes.
#
define fixLinks_cmd
	# copy HTML-redirects to each language version
	cd $(OUTPUT) && cp *.html html/$(CURRENT_LANG)

	# fix links to HTML pages
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -exec sed -i "s|href=\"\.\./html|href=\"\.\./$(CURRENT_LANG)|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -name '*.html' -type f -exec sed -i "s|href=\"\.\./\.\./html|href=\"\.\./\.\./$(CURRENT_LANG)|g" {} \;

	# fix link in redirects (-maxdepth 1 is important here)
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|url=html/|url=|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|window\.location\.href = \"html/|window\.location\.href = \"|g" {} \;
	cd $(OUTPUT)/html/$(CURRENT_LANG) && find . -maxdepth 1 -name '*.html' -type f -exec sed -i "s|href=\"html/|href=\"|g" {} \;

endef
