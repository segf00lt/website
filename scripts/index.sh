#!/bin/sh

index="../etc/blogindex"
date=$(date +"%b %d")
year=$(date +"%Y")
title=$(sed -n "s/^# \(.\+\)/\1/p" < "$1")
entrie="+ $date &#8212; $title"

[[ ! -f "$index" || -s "$index" ]] && printf "$entrie\n## $year\n" > "$index" && exit 0

grep "$entrie" "$index" && exit 1

lines=$(wc -l < "$index")
last=$(tail -n 1 < "$index")

[[ "$year" == "$(echo "$last" | sed -n "s/^## \(.\+\)/\1/p")" ]] && sed -i '$ d' "$index"

printf "$entrie\n## $year\n" >> "$index"
