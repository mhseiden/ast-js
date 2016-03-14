#! /usr/bin/env bash
BASEDIR="./$(dirname $0)"
LIBDIR="$BASEDIR/lib"

VERSION=$(coffee $BASEDIR/version.coffee)
PREAMBLE="astjs $VERSION | (c) 2016 - Max Seiden <140dbs@gmail.com> | MIT Licensed"

rm -f "$LIBDIR/*.js"

coffee --no-header -o $LIBDIR -c "$BASEDIR/treenode.coffee"

uglifyjs "$LIBDIR/treenode.js" \
  -m \
  -o "$LIBDIR/treenode.min.js" \
  --preamble "/* $PREAMBLE */" \
  --screw-ie8 \
  --lint \
  --define DEBUG=false \
  -c
