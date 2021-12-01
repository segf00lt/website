#!/bin/sh

BLOGPATH="../src/blog/articles"
file=$1

t1="<!DOCTYPE html>
<html lang=\"en\">
	<head>
		<meta charset=\"UTF-8\"/>
		<meta name=\"keyword\" content=\"index,follow\"/>
		<title>
"
t2="
		</title>
		<link rel=\"stylesheet\" type=\"text/css\" href=\"../../style.css\">
	</head>
	<body>
		<header>
"
t3="
		</header>
		<nav>
			&#91;
			<a href=\"../index.html\">Home</a> &vert;
			<a href=\"../blog.html\">Blog</a> &vert;
			<a href=\"https://github.com/segf00lt\">Software</a> &vert;
			<a href=\"#Music\">Music</a> &vert;
			<a href=\"#Contact\">Contact</a>
			&#93;
		</nav>
		<main>
		<hr>
"
t4="
		</hr>
		</main>
		<footer>
			<hr>
			<h3><a href=\"index.html\">https://joaodear.xyz</a></h3>
			</hr>
		</footer>
	</body>
</html>
"

cd ../drafts

md2html < $file > tmp
title=`grep "<h1>.*</h1>" < tmp | head -n 1`
body=`tail -n +2 tmp`
rm tmp

printf "$t1\t\t\t"
printf "$title" | sed -n "s/<h1>\(.*\)<\/h1>/\1/p"
printf "$t2\t\t\t$title$t3"
printf "$body\n" | sed -n "s/^\(.\)/\t\t\t\1/gp"
printf "$t4"
