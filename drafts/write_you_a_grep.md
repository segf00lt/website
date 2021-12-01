# Write you a grep

## Introduction

Around September this year I had the idea to try and write a grep
implementation from scratch. This meant I would also have to implement regular
expressions. Little did I know, this project would turn out to be the most
fun and challenging undertaking of the year (up till then).

Throughout this article I'll reference the resources that helped me during this
project, and that I hope will help others who decide to write themselves a
grep.

## What are regular expressions _really_?

Regular expressions as many know are a compact way of describing arbitrary
patterns of text, such as:

- `a+` the letter 'a' one or more times
- `.*` any character any number of times
- `[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*@[a-zA-Z0-9_].(com|co\.uk|xyz|io|net|)` an
  email address

These expressions range from benign literal strings, to URL's, email addresses,
C function declarations and more. So how the hell do we implement them?

### Finite Automata

