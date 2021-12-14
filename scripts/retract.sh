#!/bin/sh

# A RETRACTION?????

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

[[ "$(pwd | sed -n "s/\(\/.\+\/\)\+\(.\+\)/\2/p")" != 'website' ]] && \
	echo "$0: script must be run from repo root dir" 1>&2 && exit 1

blogindex="etc/blogindex"

for article in "$@"; do
	file=`sed -ne "s|^\+ \[.*\; $article\](/blog/articles/\(.*\.html\))|\1|p" "$blogindex"`
	echo $file
	sed -i "/$article/d" "$blogindex"
	rm -f "src/blog/articles/$file"
done

./scripts/publish.sh
