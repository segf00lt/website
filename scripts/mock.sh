#!/bin/sh

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

dir="$(pwd)"
[[ "${dir##*/}" != 'website' ]] && [[ -d "$dir/.git" ]] && \
	echo "$0: script must be run from repo root dir" 1>&2 && exit 1

./scripts/publish.sh "$@"

rm -fdr 'mock' && cp -r src mock

./scripts/retract.sh "$@"

while read -r file; do
	sed -i \
		-e "s|\"/\([^\"]*\)\"|\"$dir/mock/\1\"|g" \
		-e "s|\"\($dir/mock\)/\"|\"\1/index.html\"|" \
		"$file"
done <<< "$(find mock -type f -name '*.html*')"
