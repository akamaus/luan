#!/bin/bash

set -e
FILE=`mktemp --suffix .ps`

DOT=${1:-tst.dot}

dot -Tps $DOT > $FILE && okular $FILE

rm $FILE
