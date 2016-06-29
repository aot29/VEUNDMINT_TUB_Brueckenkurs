# Builds the multi-language version
#
# Will be integrated in the continuous integration server (when it's there)
# Remember to always use tabs instead of spaces
#
# invoke as:
#
# cd tools
# make
#

.DEFAULT_GOAL := build_DE

prepare:
	cd ../src

build_DE: prepare
	python3 tex2x.py VEUNDMINT lang=de
