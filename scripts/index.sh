#!/bin/sh

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

file="$1"
index="$2"
link="$3"

[[ ! -f "$file" ]] && echo "$0: $file non existent" 1>&2 && exit 1

date=$(date +"%b %d")
year=$(date +"%Y")
title=$(sed -n "s/^# \(.\+\)/\1/p" "$file" | head -n 1)
entrie="$title\t$link\tPublished $date"

[[ ! -f "$index" || ! -s "$index" ]] && printf "$entrie\n$year\n" > "$index" && exit 0

grep -qF "$title" "$index" && \
	sed -i "/$title/ s/\(\tPublished [A-Za-z]\+ [0-9]\+\).*$/\1 | Modified $date/" "$index" && \
	exit 0

[[ "$year" == "$(tail -n 1 < "$index")" ]] && sed -i '$ d' "$index"

printf "$entrie\n$year\n" >> "$index"
