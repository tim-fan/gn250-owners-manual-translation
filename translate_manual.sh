#!/bin/bash
# Translates the GN250 manual from Spanish to English
# Steps:
# 1) perform OCR to extract Spanish text from manual
# 2) translate Spanish text to English
# 3) interleave original manual pages with pages of English translation
#
# Note, translate-shell can randomly fail to produce output, if google API stops returning results (rate limiting?)
# In this case, this script will exit with an error message, but you can run it again a little later and it will
# pick up where it exited (intermediate files are saved)
#
# Dependencies:
# tesseract-ocr
# https://github.com/soimort/translate-shell (using 0.9.6.11-git:598b6c7 installed from github)
# pandoc
# texlive-latex-base
# texlive-fonts-recommended

set -o errexit

mkdir -p spanish_pages
mkdir -p english_pages

for IMAGE_PATH in GN250_Owners_Manual/*.jpg
# for IMAGE_PATH in "GN250_Owners_Manual/GN 250 002.jpg"
do
    PAGE_NAME=$(basename "${IMAGE_PATH%.*}" | sed -e 's/ /_/g')
    echo "Translating page: ${PAGE_NAME}"

    if [ ! -f spanish_pages/${PAGE_NAME}.txt ]
    then
        tesseract "${IMAGE_PATH}" spanish_pages/${PAGE_NAME} -l spa
    fi

    if [ ! -f english_pages/${PAGE_NAME}.txt ]
    then
        ~/.local/bin/trans -input spanish_pages/${PAGE_NAME}.txt -brief -show-alternatives n -output english_pages/${PAGE_NAME}.txt -e bing es:en

        #remove empty results
        NUM_NON_EMPTY_LINES=$(cat english_pages/${PAGE_NAME}.txt | sed '/^\s*$/d' | wc -l)
        if [ $NUM_NON_EMPTY_LINES -eq 0 ]
        then
            rm english_pages/${PAGE_NAME}.txt
            echo "Empty result - Probably Google stopped talking to you. Input:"
            cat spanish_pages/${PAGE_NAME}.txt
            exit 1
        fi
    fi

    #create pdf files of translated text
    if [ ! -f english_pages/${PAGE_NAME}.pdf ]
    then
        pandoc english_pages/${PAGE_NAME}.txt -o english_pages/${PAGE_NAME}.pdf
    fi



done
