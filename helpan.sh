#!/bin/sh

# templates
_READ="--read=markdown+simple_tables+table_captions+yaml_metadata_block+tex_math_double_backslash+grid_tables+raw_html"

# latexpp
#latex () {

#}

TEXMODE=batchmode
TEXMODE=nonstopmode

pdftex_run() {
    pdflatex -file-line-error -interaction=$TEXMODE $1 \
        | grep -i ".*:[0-9]*:.*\|warning"
}

############################################################
# set filename
fn=${2%.md}

echo $fn

############################################################
# TEMPLATES
############################################################

# latex
_ARGS_LATEX="$_READ --write=latex+smart \
    --standalone --pdf-engine=pdflatex --verbose \
    --bibliography=$HOME/Documents/library.bib \
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
    pdftex_run $fn.tex
    pdftex_run $fn.tex
    rm $fn.{out,aux,log,tex,cm.md}
}
pdfpp () {
    pdfpp_pre
    pdfpp_body
    pdfpp_post
}

# pdfnb
pdfnb_pre () { latexnb_pre; }
pdfnb_body () { latexnb_body; }
pdfnb_post () {
    pdftex_run $fn.tex
    bibtex $fn
    pdftex_run $fn.tex
    pdftex_run $fn.tex
    rm $fn.{out,aux,log,tex,cm.md}
}
pdfnb () {
    pdfnb_pre
    pdfnb_body
    pdfnb_post
}

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
    *)
        echo "USAGE: $0 [template] [file]"
esac

