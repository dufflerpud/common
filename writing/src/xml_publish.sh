#!/bin/sh

PROG=`basename $0`
TMP=/tmp/$PROG
BASE_URL=http://localhost:8081/~chris/writing/Unhappy_Pigs
#BASE_URL=http://localhost/~chris/writing/Unhappy_Pigs

BOOK_DIMENSIONS="--page-height 9in --page-width 6in"
MANUSCRIPT_DIMENSIONS="--page-height 11in --page-width 8.5in"
#MARGINS="--margin-top 0.5in --margin-bottom 0.5in --margin-left 0.5in --margin-right 0.5in"
MARGINS="--margin-top 0.5in --margin-bottom 0.5in --margin-left 0.8in --margin-right 0.8in"
ALL_PAGE_ARGS="$MARGINS --print-media-type --quiet"
ALL_PAGE_ARGS="$ALL_PAGE_ARGS --dpi 96"
COVER_ARGS=""
TOC_ARGS="--xsl-style-sheet ../common/writing/toc.xsl"
#MAIN_ARGS="--footer-left `date +%Y%m%d%H%M%S` --footer-center [page] --page-offset -1"
MAIN_ARGS="--footer-center [page] --page-offset -1"
PUBLISHER_ARGS="--footer-center [page]"

WKHTMLTOPDF="/usr/local/bin/wkhtmltopdf"
#WKHTMLTOPDF="/opt/wkhtmltopdf/bin/wkhtmltopdf"
#WKHTMLTOPDF="/bin/wkhtmltopdf"

ALL_TODO="book manuscript publisher html"

DEST_DIR=build

#########################################################################
#	Print an error message, a usage message and die abnormally.	#
#########################################################################
usage()
    {
    echo "$1" | tr '~' '\012'
    echo "Usage:  $PROG { $ALL_TODO all } <proj> <url>"
    exit 1
    }

#########################################################################
#	Execute wkhtmltopdf command but handle error return better.	#
#########################################################################
generate_pdf()
    {
    for outfile1 in $@; do :; done
    args="$@"

    if $WKHTMLTOPDF "$@"; then
        echo "$outfile1 created normally."
    elif [ -s $outfile1 ] ; then
	echo "$outfile1 successfully created with bogus error."
	echo "Args were:  $args"
    else
	echo "$outfile1 not created.  Dying."
	echo "Args were:  $args"
	exit 1
    fi
    return 0
    }

#########################################################################
#	Concatinate pdf files.						#
#########################################################################
cat_pdf_files()
    {
    outfile2="$1"
    shift
    qpdfargs=
    for fn in "$@"; do
        qpdfargs="$qpdfargs $fn 1-z"
    done
    qpdf --empty --pages $qpdfargs -- $outfile2
    echo "$outfile2 created successfully."
    }

#########################################################################
#	Generate a pdf file suitable for uploading to createspace or	#
#	printing.							#
#########################################################################
generate_with_toc()
    {
    outfile0="$1"
    dimensions="$2"
    pre_toc="$3"
    post_toc="$4"
    generate_pdf $dimensions $ALL_PAGE_ARGS cover \
	"$prog_url&show=$pre_toc" \
        $COVER_ARGS $TMP.pre_toc.pdf

    generate_pdf $dimensions $ALL_PAGE_ARGS toc	$TOC_ARGS \
	"$prog_url&show=$post_toc" \
	$MAIN_ARGS $TMP.toc.pdf

    cat_pdf_files $outfile0 $TMP.pre_toc.pdf $TMP.toc.pdf
    }

#########################################################################
#	Generate a pdf file suitable for a publisher to review.		#
#	(contains only summaries)					#
#########################################################################
generate_query()
    {
    outfile0="$1"
    dimensions="$2"
    show_arg="$3"
    generate_pdf $dimensions $ALL_PAGE_ARGS toc $TOC_ARGS \
        "$prog_url&show=$show_arg" $PUBLISHER_ARGS $outfile0
    }

#########################################################################
#	Generate an html file suitable for a publisher to review.	#
#	(contains only summaries)					#
#########################################################################
generate_html()
    {
    outfile="$1"
    show_arg="$2"
    wget -q -O - "$prog_url&show=$show_arg" | embed_images > $outfile
    #[ -h $DEST_DIR/images ] || ln -s ../images $DEST_DIR/images
    #kindlegen $outfile
    #ebook-convert $outfile `$outfile
    }

#########################################################################
#	Main								#
#########################################################################

# Parse arguments
TODO=""
GENERATED=""
while [ "$#" -gt 0 ] ; do
    case "$1" in
	-generated)	GENERATED="$2"; shift				;;
	-mfs)		ALL_PAGE_ARGS="$ALL_PAGE_ARGS --minimum-font-size $2"
			shift
			;;
        all)		TODO="publisher book manuscript"		;;
        publisher|book|manuscript|agent|html)
			TODO="$TODO $1"					;;
	http*)		prog_url="$1"					;;
        *)		proj="$1"					;;
    esac
    shift
done

#[ -z "$TODO" ] && problems="${problems}Nothing to do.~"
[ -z "$prog_url" ] && problems="${problems}No URL specified.~"
[ -z "$TODO" ] && TODO="$ALL_TODO"

[ -n "$problems" ] && usage "$problems"

[ -z "$GENERATED" ] || prog_url="$prog_url?GENERATED=$GENERATED"

# Loop through requested pdf types.

mkdir -p $DEST_DIR

for task in $TODO ; do
    echo "Building $task for ${proj}."
    case "$task" in
	html)		generate_html $DEST_DIR/$task.html reader	;;

	book)		generate_with_toc $DEST_DIR/$task.pdf \
			    "$BOOK_DIMENSIONS" pre_toc post_toc
			;;

	manuscript)	generate_with_toc $DEST_DIR/$task.pdf \
			    "$MANUSCRIPT_DIMENSIONS" pre_toc post_toc
			;;

	*)		generate_query $DEST_DIR/$task.pdf \
			    "$MANUSCRIPT_DIMENSIONS" $task
			;;
    esac
done

exec rm -f $TMP.*
