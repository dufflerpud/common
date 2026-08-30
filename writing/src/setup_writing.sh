#!/bin/sh

MUST_HAVE="index.cgi characters.xml"

ln -s ../common
ln -s common/writing/Makefile.stories Makefile
mkdir -p build published
touch index.ok
ls -l
for fn in $MUST_HAVE ; do
    [ -x $fn ] || echo "Need an $fn"
done
