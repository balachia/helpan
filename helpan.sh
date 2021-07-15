#!/bin/sh

# templates
#_READ="--read=markdown+simple_tables+table_captions+yaml_metadata_block+tex_math_double_backslash+grid_tables+raw_html"
_READ="--read=markdown+tex_math_double_backslash"

TEXMODE=batchmode
TEXMODE=nonstopmode

pdftex_error() {
    pdflatex -file-line-error -interaction=$TEXMODE $1 \
        | grep -i ".*:[0-9]*:.*"
}

pdftex_error_warning() {
    pdflatex -file-line-error -interaction=$TEXMODE $1 \
        | grep -i ".*:[0-9]*:.*\|warning"
}

pdftex_run() {
    pdftex_error_warning
}

############################################################
# set filename
fn=${2%.md}

echo $fn

############################################################
# TEMPLATES
############################################################

# generics
criticmarkup () { criticmarkuphs -i $fn.md -o $fn.cm.md; }

# latex
_ARGS_LATEX="$_READ --write=latex+smart \
    --standalone --pdf-engine=pdflatex --verbose \
    --bibliography=$HOME/Documents/library-zotero.bib \
    --filter=pandoc-include \
    --filter=pandoc-crossref \
    --filter=pandoc-citeproc \
    --filter=pandoc-citeproc-preamble"

# latexpp
_ARGS_LATEX_PP="$_ARGS_LATEX \
    --default-image-extension=pdf"

latexpp_pre () { criticmarkuphs -i $fn.md -o $fn.cm.md; }
latexpp_body () { pandoc $_ARGS_LATEX_PP -o $fn.tex $fn.cm.md; }

# latexnb
_ARGS_LATEX_NB="$_ARGS_LATEX_PP --natbib"

latexnb_pre () { latexpp_pre; }
latexnb_body () { pandoc $_ARGS_LATEX_NB -o $fn.tex $fn.cm.md; }

# pdfpp
pdfpp_pre () { latexpp_pre; }
pdfpp_body () { latexpp_body; }
pdfpp_post () {
    pdftex_error $fn.tex
    pdftex_error_warning $fn.tex
    rm $fn.{out,aux,log,tex,cm.md}
}

# pdfnb
pdfnb_pre () { latexnb_pre; }
pdfnb_body () { latexnb_body; }
pdfnb_post () {
    pdftex_error $fn.tex
    bibtex $fn
    pdftex_error $fn.tex
    pdftex_error_warning $fn.tex
    rm $fn.{out,aux,log,tex,cm.md}
}

# html
_ARGS_HTML="$_READ --write=html+smart \
    --standalone --verbose \
    --bibliography=$HOME/Documents/library-zotero.bib \
    --filter=pandoc-include \
    --filter=pandoc-crossref \
    --filter=pandoc-citeproc \
    --filter=pandoc-citeproc-preamble"

# mjhtml
mjhtml_pre () { criticmarkup; }
mjhtml_body () { pandoc $_ARGS_HTML -o $fn.html $fn.cm.md; }
mjhtml_post () { rm $fn.cm.md; }

#for arg in $_ARGS_LATEX_NB; do
#    echo $arg
#done

case $1 in
    latexpp)
        $1_pre; $1_body
        ;;
    latexnb)
        $1_pre; $1_body
        ;;
    pdfpp)
        $1_pre; $1_body; $1_post
        #pdfpp
        ;;
    pdfnb)
        $1_pre; $1_body; $1_post
        #pdfnb
        ;;
    mjhtml)
        $1_pre; $1_body; $1_post
        ;;
    *)
        echo "USAGE: $0 [template] [file]"
esac

