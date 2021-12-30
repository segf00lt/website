# Regex from scratch

## Introduction

Around September this year I had the idea to write grep by myself, totally from
scratch. This meant I would also have to implement regular expressions. Little
did I know, this project would turn out to be the most fun and challenging
undertakings of the year.

## What are regular expressions?

Regular expressions, as many programmers will know, are a compact way of describing arbitrary
patterns of text, such as:

- `a+` the letter 'a' one or more times
- `.*` any character any number of times
- `[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*@[a-zA-Z0-9_]+\.(com|co\.uk|xyz|io|net)` an
  email address

Here's a quick overview of the syntax in order of precedence, lowest to highest (sort of):

__e<sub>0</sub>|e<sub>1</sub>__ &#8212; match first expression or second expression

__e<sub>0</sub>e<sub>1</sub>__ &#8212; match one expression followed by another

__e<sub>0</sub>?__ &#8212; match the preceding character (or group) at most once

__e<sub>0</sub>__<b>\*</b> &#8212; match the preceding character (or group) any number of times

__e<sub>0</sub>+__ &#8212; match the preceding character (or group) 1 or more times

__[abc]__ &#8212; match one of the of characters in the character class

__(e<sub>0</sub>)__ &#8212; match the expression in the group

__.__ &#8212; match any character

__[a-z]__ &#8212; match a range of characters, in this case a through z

__a__ &#8212; match a literal character (__a__ in this case)

__^__ &#8212; match beginning of line

__$__ &#8212; match end of line

Expressions may be made of any of the syntactic elements listed above.
Also, in our implementation, to force the literal version of any character it must be
escaped with a backslash.

Try and work out the example expressions given above if you're new to regular expressions.

As you can see, these expressions can range from benign literal strings, to
URL's, email addresses, C function declarations and more. So how do we
implement them?

## Finite Automata

A _Finite Automata_, or _State Machine_, is a computer with no memory, that can
be in 1 (or more) of a finite number of states at a given moment.

If you've ever seen a flow chart then you kind of understand state machines.
Each state is connected to other states by a collection of labeled arrows.
If the input to the machine matches the condition of one of those arrows,
the machine is moved into the state that the arrow points to, and awaits more
input. This is done until the machine reaches the _end state_ (or the _match state_
as we'll soon call it).

Before you continue, watch [this](https://www.youtube.com/watch?v=vhiiia1_hC4)
Computerphile video for a great explanation of state machines from Professor
Brailsford.

Alright, now that you've heard the Professor's explanation, let's see how this
relates to regular expressions.

Take the expression `abc`.

```pikchr
color = 0xdfdfdf

circle "s0" big fit
arrow "a" above
circle "s1" big fit
arrow "b" above
circle "s2" big fit
arrow "c" above
circle "s3" big fit
circle at last circle rad last circle.rad/1.25
```

The state machine above has a start state (s0), a match (end) state (s3), and
2 transition states between the two (s1 and s2).

The machine to recognize `a(bb)+a` would look like this:

```pikchr
color = 0xdfdfdf

circle "s0" big fit
arrow "a" above
circle "s1" big fit
arrow "b" above
circle "s2" big fit
arrow "b" above
circle "s3" big fit
arc -> cw from last circle.s to 2nd last circle.s
"b" above at last arc.s color 0xdfdfdf
arrow from last circle.right "a" above
circle "s4" big fit
circle at last circle rad last circle.rad/1.25
```

This machine matches an __a__, followed by __one or more__ pairs of __b__'s followed
by another __a__.

Notice that both of the machines shown so far will can only be in at most one state
at a time&#8212;they are called _Deterministic Finite Automata_, or DFA's.

Alternatively, one could have a state machine be in _1 or more_ states at a time,
a _Non-deterministic Finite Automata_, or NFA. Take the expression `abc|abd`.

It could be represented like this:

```pikchr
color = 0xdfdfdf

circle "s0" big fit
arrow "a" above
circle "s1" big fit
arrow "b" above
circle "s2" big fit
move to 3rd circle
move up 0.44 right 0.25
circle "s3" big fit
arc -> cw from 3rd circle.n to last circle.w
"c" at last arc.nw color 0xdfdfdf
move to 3rd circle
move down 0.44 right 0.25
circle "s4" big fit
arc -> from 3rd circle.s to last circle.w
"d" at last arc.sw color 0xdfdfdf
move to 3rd circle
line 0.8 invisible
circle rad 1st circle.rad
circle at last circle rad last circle.rad/1.25
spline -> from 4th circle.e right 0.25 then down 0.2 to 0.038 above last circle.n
spline -> from 5th circle.e right 0.25 then up 0.2 to 0.038 below last circle.s
```

Or like this:

```pikchr
color = 0xdfdfdf

circle "s0" big fit
move to 1st circle
move up 0.44 right 0.25
circle "s1" big fit
arc -> cw from 1st circle.n to last circle.w
move to 1st circle
move down 0.44 right 0.25
circle "s4" big fit
arc -> from 1st circle.s to last circle.w

/* first group */
move to 2nd circle.e
arrow "a" above
circle "s2" big fit
arrow "b" above
S3: circle "s3" big fit

/* second group */
move to 3rd circle.e
arrow "a" above
circle "s5" big fit
arrow "b" above
S6: circle "s6" big fit

move to 1st circle.e
line 2.4 invisible
circle rad 1st circle.rad
circle at last circle rad last circle.rad/1.25

spline -> from S3.e right 0.3 then down 0.2 to 0.038 above last circle.n
move to 0.18 above last spline.n
"c" color 0xdfdfdf
spline -> from S6.e right 0.3 then up 0.2 to 0.038 below last circle.s
move to 0.01 above last spline.s
"d" color 0xdfdfdf
```

The first machine is _deterministic_, it'll only ever be in 1 state at a time.
The second, however, can be in at most 2 states at a time&#8212;it is
_non-deterministic_.

Here's a question: which of these machines is easier to build from the
expression given? Imagine you are a compiler, reading the
regular expression `abc|abd` character by character, trying to parse it.
If you wanted to generate the non-deterministic machine, you could simply
parse it as "__a__ then __b__ then c, or __a__ then __b__ then __d__",
and go about your day. If instead you wanted to generate the deterministic
machine, you'd have to keep track of any identical parts of the expression,
and restructure in order for it to parse as
"__a__ then __b__, then __c__ or __d__"&#8212;suffice to say, the 1st
machine compiles faster (which is important if you're implementing grep,
like I was, but not so much if you're writing a lexer).

Due to this shorter compile time, we'll be using the NFA in our implementation.

But how do we execute the instructions of the second machine then? Specifically,
seeing as the first 2 arrows are unlabeled (meaning we may simply follow them
without taking input) and the machine has no way of knowing in advance what
characters it will see, which branch should it choose to follow? The great
Ken Thompson gave quite an interesting answer in his 1968 CACM paper: just let
it choose both.

You could think of this approach as a breadth-first-search. Alternatively, the
regex implementations used by Perl, Python, Ruby and more do a
depth-first-search, and have to backtrack if the branch they chose didn't work.
As Russ Cox shows in an [article](https://swtch.com/~rsc/regexp/regexp1.html)
on the topic, Thompson's BFS approach is stupidly fast compared with the DFS
algorithms used in most modern languages.

## Building an NFA

We create an NFA from a regular expression by assembling it from a set of Lego
like building blocks, specified by the expression. For the sake of simplicity,
we'll be ignoring character classes, line anchors, escaped characters and wild
cards, for now, because they behave same as literals in the context of NFA
diagrams

Here are the fragments we'll use to build our NFA's.

```pikchr
color = 0xdfdfdf

T1: "Literal (a)" color 0xdfdfdf
move right
F1: circle rad 0.12
arrow "a" above

move to T1 then down

T2: "Concatenation (e1e2)" color 0xdfdfdf
move to F1 then down
F2: box "e1" big fit
move to last box.e
arrow right
box "e2" big fit
arrow right

move to T2 then down 1

T3: "Alternation (e1|e2)" color 0xdfdfdf
move to F2 then down 1
F3: circle rad F1.rad
move to F3
move up 0.36 right 0.25
box "e1" big fit
arrow right
arc -> cw from F3.n to last box.w
move to F3
move down 0.36 right 0.25
box "e2" big fit
arrow right
arc -> from F3.s to last box.w

move to T3 then down 1

T4: "At most one (e?)" color 0xdfdfdf
move to F3 then down 1
F4: circle rad F1.rad
move to F4
move up 0.36 right 0.25
box " e " big fit
arrow right
arc -> cw from F4.n to last box.w
move to F4
move down 0.36 right 0.25
line invisible
arc -> from F4.s to last line.w

move to T4 then down 1

T5: "Zero or more (e*)" color 0xdfdfdf
move to F4 then down 1
F5: circle rad F1.rad
move to F5
move up 0.36 right 0.25
box " e " big fit
spline -> from last box.e right then down 0.36 then left to F5.e
arc -> cw from F5.n to last box.w
move to F5
move down 0.36 right 0.25
line invisible
arc -> from F5.s to last line.w

move to T5 then down 1

T6: "One or more (e+)" color 0xdfdfdf
move to F5 then down 1
F6: box " e " big fit
arrow from F6.e right
circle rad F1.rad
arrow right
arc -> from last circle.n to F6.n
```

Now what we need is a way of parsing regular expressions and constructing
the corresponding NFA diagram from the fragments shown above. We'll use a
variant of Edsger Dijkstra's "Shunting Yard Algorithm".

<!--TODO: write pseudocode for shunting yard-->
