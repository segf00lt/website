#!/bin/sh

BLOGPATH="../src/blog/articles"

t1="<!DOCTYPE html>
<html lang=\"en\">
	<head>
		<meta charset=\"UTF-8\"/>
		<meta name=\"keyword\" content=\"index,follow\"/>
		<title> </title>
		<link rel=\"stylesheet\" type=\"text/css\" href=\"../style.css\">
	</head>
	<body>
		<header>
"
t2="
		</header>
		<nav>
			&#91;
			<a href=\"../index.html\">Home</a> &vert;
			<a href=\"#Blog\">Blog</a> &vert;
			<a href=\"https://github.com/segf00lt\">Software</a> &vert;
			<a href=\"#Music\">Music</a> &vert;
			<a href=\"#Contact\">Contact</a>
			&#93;
		</nav>
		<main>
		<hr>
"
t3="
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

cd ../articles
for file in *; do
	md2html < $file > tmp
	title=`grep "<h1>.*</h1>" < tmp | head -n 1`
	body=`tail -n +2 tmp`
	rm tmp

	printf "$t1\t\t\t$title$t2" > $BLOGPATH/${file%%'.md'}.html
	printf "$body\n" | sed -n "s/^\(.\)/\t\t\t\1/gp" >> $BLOGPATH/${file%%'.md'}.html
	printf "$t3" >> $BLOGPATH/${file%%'.md'}.html
done
