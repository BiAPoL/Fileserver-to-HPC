#!/bin/bash
echo "processing $1"
filename=$(basename $1)
dir=$(dirname $1)
resultfile=.${dir}/results/${filename%.*}.result
echo "result for $filename" > $resultfile
cat $1 >> $resultfile
echo "done processing $1"
