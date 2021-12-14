#!/bin/sh

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM

file=$1
[[ ! -f "$file" ]] && echo "$0: $file non existent" 1>&2 && exit 1

template="etc/template"

md2html < $file > tmp
title=`sed -n "s/<h1>\(.*\)<\/h1>/\1/p" tmp`
body=`tail -n +2 tmp`
rm tmp

sed -ne "s/<\!--PAGENAME-->/$title/"\
	-ne "s/<\!--TITLE-->/<h1>$title<\/h1>/"\
	-e "0,/<\!--CONTENT-->/p"\
	"$template"

printf "$body\n" | sed -n "s/^\(.\)/\t\t\1/gp"

sed -n "/<\!--CONTENT-->/,\$p" "$template"
