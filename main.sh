#!/bin/bash

function mkowntemp(){
	local NAME="/tmp/latex_rebuild-$(date +%s.%06N)"
	mkdir "$NAME"
	echo "$NAME"
}

function runlatex(){
	local FILENAME="$1"
	local LOGFILENAME="$(echo "${FILENAME}" |sed 's/.tex$/.log/')"
	local LATEX="${2:-xelatex}"
	local MAX_RUN="${3:-5}"
	for i in $(seq $MAX_RUN);do
		if :|"${LATEX}" "$FILENAME" latex="$LATEX" ;then
			if [[ $(grep -c '^(rerunfilecheck)' "$LOGFILENAME") -gt '1' ]];then
				continue
			else
				return 0
			fi
		else
			echo 'latex failed with status code '$?
			return 1
		fi
	done
	echo 'number of rerun exceeded'
	return 1
}

function latex_rebuild(){
	local CURRENT="$(pwd)"
	local WORKDIR="$(mkowntemp)"
	cp -r . "$WORKDIR"
	cd "$WORKDIR"
	lyx --export xetex "$2"
	if runlatex "$1" xelatex 5 ;then
		:
	else
		local EXITCODE=$?
		echo "$WORKDIR"
		return $EXITCODE
	fi
	cp $(echo "$1" |sed 's/.tex$/.pdf/') "$CURRENT/"
	cd "${CURRENT}"
	rm -fr "${WORKDIR}"
}

latex_rebuild "${1:-main.tex}" "${2:-export.lyx}"
