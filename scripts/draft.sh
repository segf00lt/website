#!/bin/sh

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

file=$1
[[ ! -f "$file" ]] && echo "$0: $file non existent" 1>&2 && exit 1

template="etc/template"

awk '\
BEGIN { flag=0; acc=""; count=1 } \
/```pikchr$/ { flag=1; next } \
/```$/ { \
flag=0; \
print "<div class=\"diagram" count "\">"; \
print acc | "pikchr --svg-only - | head -n -1"; \
close("pikchr --svg-only - | head -n -1"); \
print "</div>"; \
acc=""; \
++count; \
next; \
} \
flag==0{print $0;next} \
flag==1{acc = acc (acc == "" ? "" : ";") $0;next}' \
< $file | md2html > tmp

title=`sed -n "s/<h1>\(.*\)<\/h1>/\1/p" tmp`
body=`tail -n +2 tmp`
rm tmp

sed -ne "s/<\!--PAGENAME-->/$title/"\
	-ne "s/<\!--TITLE-->/<h1>$title<\/h1>/"\
	-e "0,/<\!--CONTENT-->/p"\
	"$template"

echo "$body"

sed -n "/<\!--CONTENT-->/,\$p" "$template"
