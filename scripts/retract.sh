#!/bin/sh

# A RETRACTION?????

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

dir="$(pwd)"
[[ "${dir##*/}" != 'website' ]] && [[ -d "$dir/.git" ]] && \
	echo "$0: script must be run from repo root dir" 1>&2 && exit 1

blogindex="etc/blogindex"

for file in "$@"; do
	file="${file##*/}"
	[[ $file == *".md" ]] && file="${file%%'.md'}.html"
	sed -i "/$file/d" "$blogindex"
	rm -f "src/blog/articles/$file"
done

./scripts/publish.sh
