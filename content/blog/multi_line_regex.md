---
title: Multi-line Regular Expressions - Is $ really an assertion?
date: 2022-04-01
draft: false
---

If you've programmed for any amount of time you probably know about
regular expressions, the terse, sometimes unreadable, powerful syntax
for describing arbitrary patterns of text. They can match any sort of
pattern, be it a URL, an email address or a C function declaration.

However, despite their arbitrary matching power, most implementations and most
programs that use them are implicitly limited to doing single line matches.
You'll become acutely aware of this if you try to use UNIX core utilities to do
any kind of simple parsing (preprocessing HTML or Markdown for example). Very
quickly you'll turn to awk, annoyed at the fact that sed or grep are unable to
accomplish such a simple task.

Recently, I discovered Rob Pike's article
[_structural regular expressions_](http://doc.cat-v.org/bell_labs/structural_regexps/),
which tackles this very problem, and was quite intrigued.

The solution he provides is beautifully simple. Instead of tools like grep,
sed, awk, diff etc. reading a file one line at a time, make them read one
_byte_ at a time. This way, the implicit structure normally imposed on files
and streams by these tools disappears, and the user can provide their own.

Inspired by Pike's article, I have decided to take a crack at redesigning some
core utilities with the afore mentioned limitations removed. And despite having
just started this project, I've found what I'll argue is another curious
instance of implicit structure in the implementation of regular expressions:
the end-of-line assertion or **$**.

In a regular expression match function (or at least the ones I've looked at)
**^** and **$** cause a skip to the next element of the expression without
consuming a character in the input, whenever what they assert is true. This
behaviour is semantically correct, **^** and **$** just ask the question
&rdquo;Am I at the beginning of a line?&ldquo; or &rdquo;Am I at the end of a
line?&ldquo;. So, given this behaviour, when looking at the string &rdquo;foo
bar&ldquo; the expression &rdquo;^[a-z ]+$&ldquo; would return a match. But
what about the expression &rdquo;stupid\\.$Kelly&ldquo; and the string
&rdquo;Keep it simple, stupid.\\nKelly Johnson&ldquo;? Surprisingly, it won't
match.

The problem isn't the newline character because the string &rdquo;foo bar\\n&ldquo;
would be matched by the first expression just fine. So why the heck won't it work?

Let's step through the execution of expression 2.

- Skip to the beginning of &rdquo;stupid.&ldquo; and match
   **s**, **t**, **u**, **p**, **i**, **d** and a literal dot.
- Now we're at **\\n** in the string and **$** in the expression.
- The end-of-line assertion succeeds.
- We move to the next element in the expression **K**.

See the problem? The assertion only moves you along in the expression,
_not in the string_. So, after the **$** assert succeeds we try and match
**K**, but we're still at the newline character in the string. How do we fix
this you ask? It's simple, make **$** consume a character.

&rdquo;But João&ldquo; you exclaim, &rdquo;its semantically incorrect for an
assertion to consume a character!&ldquo;  
To this I say: _Is **$** really an assertion?_  
I would argue that it _isn't_, or rather that it shouldn't be treated the same
as **^**.

When asserting a beginning-of-line, you need to check that either you're at the
beginning of the string, or that the last character you looked at was a newline.
Notice that this has _nothing_ to do with the current character in the string, so
it would be wrong to walk along to the next character.
On the other hand, when asserting an end-of-line, you need to check that either
you're at the end of the string, or that the character you're _currently_
looking at is a null terminator or a newline. In the case of **$**, it _does_
matter what the current character in the string is, so why should it not behave
as though it matches something?

Using standard behaviour, a **$** assert becomes completely useless unless you
only put it at the end of the expression. So trying to check for an empty line
somewhere in the middle of the expression, for example, has to be done with
&rdquo;^\\n&ldquo;, instead of &rdquo;^$&ldquo;. Using our new behaviour, the
**$** actually becomes useful in multi-line regular expressions and makes them
much more convenient to type, more syntactically consistent and more meaningful.
