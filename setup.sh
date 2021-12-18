#!/bin/sh

DIR="$(pwd)"
[[ "${DIR##*/}" != 'website' ]] && [[ -d "$DIR/.git" ]] && \
	echo "$0: script must be run from repo root dir" 1>&2 && exit 1

[[ `whoami` != root ]] && echo "$0: must be root" && exit 1

PREFIX="/usr/local/bin"

cp scripts/site.sh $PREFIX/site
chmod +x $PREFIX/site
sed -i "/WEBSITE_PATH=/ s|$|'$DIR'|" "$PREFIX/site"
