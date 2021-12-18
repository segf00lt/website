#!/bin/sh

WEBSITE_PATH=
USAGE='Usage: site OPTION [ARGUMENTS]
   -p [ARGUMENTS] : publish
   -r [ARGUMENTS] : retract
   -m [ARGUMENTS] : mock
   -s [ARGUMENTS] : sync
   -h : help
'
declare -a args=()
declare n=0

function publish() {
	cd $WEBSITE_PATH && ./scripts/publish.sh "$@"
}

function retract() {
	cd $WEBSITE_PATH && ./scripts/retract.sh "$@"
}

function mock() {
	cd $WEBSITE_PATH && ./scripts/mock.sh "$@"
}

function sync {
	local files="$@"
	[[ "$#" == 0 ]] && files=$WEBSITE_PATH/src/*
	rsync -rv $files 'joaodear@joaodear.xyz:~/joaodear.xyz/' || exit 1
}

function getargs() {
	while [[ "$#" -gt 0 ]] && [[ "$1" != -* ]]; do
		args+=("$1")
		((n=$n+1))
		shift 1
	done
}

[[ $WEBSITE_PATH != *'/website' ]] && echo "$0: run setup.sh before use" && exit 1

[[ "$#" == 0 ]] && echo "$0: missing arguments" && exit 1

while [ "$#" -gt 0 ]; do
	case $1 in
		-p) getargs "${@:2}" && publish "${args[@]}" && shift `expr $n \+ 1` ;;
		-r) getargs "${@:2}" && retract "${args[@]}" && shift `expr $n \+ 1` ;;
		-m) getargs "${@:2}" && mock "${args[@]}" && shift `expr $n \+ 1` ;;
		-s) sync && shift 1 ;;
		-h) printf "$USAGE" && exit 1 ;;

		*) echo "$0: unkown option $1" && exit 1 ;;
	esac
	unset args && n=0
done
