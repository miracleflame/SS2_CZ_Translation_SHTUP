#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for i in `find UTF8 ! -path *.crf*`; do

	if [ -d "$i" ]
		then
			echo "directory : ${i//UTF8/1250}"
			mkdir "${i//UTF8/1250}" 2>/dev/null
		else
			echo "file : $i"
		cstocs utf8 1250 "$i" > "${i//UTF8/1250}"
	fi	
done

IFS=$SAVEIFS
