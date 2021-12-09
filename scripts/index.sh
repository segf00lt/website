#!/bin/sh

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

file="$1"
index="$2"
link="$3"

[[ ! -f "$file" ]] && echo "$0: $file non existent" 1>&2 && exit 1

date=$(date +"%b %d")
year=$(date +"%Y")
title=$(sed -n "s/^# \(.\+\)/\1/p" "$file" | head -n 1)
entrie="+ [$date &#8212; $title]($link)"

[[ ! -f "$index" || ! -s "$index" ]] && printf "$entrie\n## $year\n" > "$index" && exit 0

grep -F "$entrie" "$index" && exit 1

lines=$(wc -l < "$index")
last=$(tail -n 1 < "$index")

[[ "$year" == "$(echo "$last" | sed -n "s/^## \(.\+\)/\1/p")" ]] && sed -i '$ d' "$index"

printf "$entrie\n## $year\n" >> "$index"
