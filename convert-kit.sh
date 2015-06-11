#!/bin/bash

if [[ $1 == 'pdf' ]]; then
    OPTION='-treepdf'
else
    OPTION='-tree'
fi

./converter/mconvert.pl $OPTION module_veundmint/tree_kit.tex module_veundmint output
