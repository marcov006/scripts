#!/bin/bash

if [[ $# -ne 3 ]]; then
	echo "usage: geo2gpx LOC_DIR IN_GPX OUT_GPX" 
	exit
fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

LOC_FILES=$1/*.loc
cmd="gpsbabel -i geo"
for f in $LOC_FILES
do
	cmd="$cmd -f '$f'"
done

cmd="$cmd -i gpx -f '$2' -o gpx -F $3"

#echo $cmd
eval $cmd

IFS=$SAVEIFS
