#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for i in `find 1250 ! -wholename "*/fonts*" ! -path *.crf*`; do

	if [ -d "$i" ]
		then
			echo "directory : ${i//1250/UTF8}"
			mkdir "${i//1250/UTF8}" 2>/dev/null
		else
			echo "file : $i"
		cstocs 1250 utf8 "$i" > "${i//1250/UTF8}"
	fi	
done

IFS=$SAVEIFS
