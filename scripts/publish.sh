#!/bin/sh

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

[[ "$(pwd | sed -n "s/\(\/.\+\/\)\+\(.\+\)/\2/p")" != 'website' ]] && \
	echo "$0: script must be run from repo root dir" 1>&2 && exit 1

for file in "$@"; do
	[[ ! -f "$file" ]] && echo "publish.sh: $file non existent" 1>&2 && continue

	out="$(echo $file | sed -ne "s/\(\/\?.\+\/\)\+\(.\+\)/\2/" -ne "s/\(.\+\)\.md/\1.html/p")"
	scripts/./draft.sh "$file" > "src/blog/articles/$out"
	scripts/./index.sh "$file" "etc/blogindex" "/blog/articles/$out" 2>&1
done >/dev/null

# Update blog index page
blogindex="etc/blogindex"
page="src/blog/blog.html"
template="etc/template"

title="Blog Index"

content="$(tac "$blogindex" | md2html)"

sed -ne "s/\(<\!--PAGENAME-->\)/\1$title/"\
	-ne "s/\(<\!--TITLE-->\)/\1<h1>$title<\/h1>/"\
	-e "0,/<\!--CONTENT-->/p"\
	"$template" > "$page"

echo "$content" | sed -n "s/^\(.\)/\t\t\1/p" >> "$page"

sed -n "/<\!--CONTENT-->/,\$p" "$template" >> "$page"

# Update recent articles section
home="src/index.html"

recent="$(echo "$content" | sed -e "/^<h2>[0-9]\+<\/h2>/d" -e "/^<\/\?ul>$/d" | head -n 4)"

top="$(sed -n "0,/<\!--BEGIN-->/p" "$home")"
bot="$(sed -n "/<\!--END-->/,\$p" "$home")"
printf "$top\n" > "$home"
printf "\t\t\t\t\t$recent\n" | tr -d '\n' >> "$home"
printf "\n" >> "$home"
printf "$bot" >> "$home"
