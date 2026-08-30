#!/bin/sh

TOPDIR="/usr/local/projects/writing"
CONVERT=/usr/local/projects/common/writing/bin/rewrite_characters.pl

echodo()
    {
    echo "+ $*"
    $*
    }

ls -ld $CONVERT

find $TOPDIR -name 'characters.xml' -print | while read fn; do
    oldfn="$fn.pre_setvar_change"
    if [ -f "$oldfn" ] ; then
        if grep "modifier=" $oldfn >/dev/null; then
	    if grep "LAST=" $fn >/dev/null; then
	        echo "$fn was already done."
	    else
	        echo "$oldfn is in the old format but $fn is not."
	    fi
	elif grep "LAST=" $fn >/dev/null; then
	    echo "$oldfn is in a weird format but $fn is ok."
	else
	    echo "$oldfn and $fn are both weird."
	fi
    elif [ -h "$fn" ] ; then
	echo "Skipping symlink $fn."
    elif grep "modifier=" $fn >/dev/null; then
	echodo mv $fn $oldfn
        echodo $CONVERT -i $oldfn -o $fn
	echodo chmod 644 $fn
    else 
        echo "Skipping $fn is in a weird format."
    fi
done
