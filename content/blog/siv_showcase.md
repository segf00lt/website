---
title: "Program Showcase - Siv"
date: 2022-10-12T15:46:50-03:00
draft: false
---

It's about time there was something aside from silly poorly thought out
philosophy on this blog.

__siv__ is a program I've been writing since around April, when I wrote
[this post]("multi_line_regex"), as part of a larger project called the
[sreutils](https://github.com/segf00lt/sreutils). It's the first _real_ program
I've ever written, which I guess is why it took such a long time to finish it.

It does what I call _Multi-layer regular expression matching_. __siv__ takes up to
10 regular expressions, a number of input sources and some flags, and reads through
each input source doing a recursive depth-first-search. First it looks for
_exp0_, then within what _exp0_ matched it looks for _exp1_ and so on up to _exp9_.
Most importantly, unlike grep, sed or the other UNIX core utilities, __siv__ doesn't
break input into an array of lines, it just reads an unstructured stream of bytes.
Any structure in the output is based on the regular expressions used in the search.

This means that __siv__ can do many things that grep can't.

Say for example you have a latex bibliography file, like this one

```
@book{gibson,
	author = "Gibson, J. J.",
	title = "The Ecological Approach to Visual Perception",
	year = 1986,
	publisher = "Psychology Press"
}

@book{collingwood,
	author = "Collingwood, R. G.",
	title = "The Principles of Art",
	year = 1938,
	publisher = "Clarendon Press"
}

@inbook{ridley,
	author = "Ridley, Aaron",
	title = "Expression in Art",
	editor = "Levinson, Jerrold",
	booktitle = "The Oxford Handbook of Aesthetics",
	year = 2003,
	publisher = "Oxford University Press",
	chapter = 11
}
```

and you want to extract all the __@book__ entries. With __siv__,
this can be done with the command

```
$ siv '^@book{.*,\n.*}$' references.bib
@book{gibson,
	author = "Gibson, J. J.",
	title = "The Ecological Approach to Visual Perception",
	year = 1986,
	publisher = "Psychology Press"
}
@book{collingwood,
	author = "Collingwood, R. G.",
	title = "The Principles of Art",
	year = 1938,
	publisher = "Clarendon Press"
}
```

If instead we wanted to extract the publisher field of each __@book__
entry, we could say

```
$ siv -t 1 -e '^@book{.*,\n.*}$' -e 'publisher = .+$' references.bib
publisher = "Psychology Press"
publisher = "Clarendon Press"
```

The flag __-t__ selects which match is to be printed, starting from 0.
In the command above __-t__ is selecting the content matched by the second regular
expression, corresponding to the publisher field of the book entry.

A more impressive display of __siv__'s capabilities is it's ability to do rudimentary parsing.
The expression
`^([A-Za-z_][A-Za-z_*0-9]* ?)+\** [A-Za-z_][A-Za-z_0-9]*\([^\n]\)[ \n]{\n.+^}$`
codes for a C function, whose header is all on one line, and whose body may
begin with an open curly brace on that same line or on the next one.

Other applications include parsing HTML/XML

```
$ curl https://joaodear.xyz | siv -t 1 -e '<head>.*</head>' -e '<meta.*>'
```

Extracting CSS rules for a given tag

```
$ siv '^([^\n]+, )*nav(, [^\n]+)* {\n.*^}$' style.css
```

And even fulfilling the role of grep itself

```
$ siv -e '^.*$' -e 'siv's not grep'
```

Now that __siv__ is finally in a working state I'll be testing it more in
everyday use to get a better understanding of it's strengths and weaknesses. I
encourage anyone who's interested to clone the [sreutils](https://github.com/segf00lt/sreutils)
repo and give it a try.
