# Regex from scratch

## Introduction

This article is supposed to be my contribution to the discussion of regular
expressions in a series of articles by [Russ Cox](https://swtch.com/~rsc/),
which I encountered in trying to write a grep implementation myself, without
the aid of a regex library
(the code for which can be found [here](https://github.com/segf00lt/jgrep)).

Is was a great project and I learned a lot from it and Russ' articles, so I hope
my contribution will prove educational for others.

## What are regular expressions?

Regular expressions are a compact way of describing arbitrary
patterns of text, such as:

- `a+` the letter __a__ one or more times
- `.*` any character any number of times
- `[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*@[a-zA-Z0-9_]+\.(com|co\.uk|xyz|io|net)` an
  email address

Here's a quick overview of the regex syntax in order of precedence, lowest to
highest (sort of):

__e<sub>0</sub>|e<sub>1</sub>__ &#8212; match first expression or second expression

__e<sub>0</sub>e<sub>1</sub>__ &#8212; match one expression followed by another

__e<sub>0</sub>?__ &#8212; match the preceding expression at most once

__e<sub>0</sub>__<b>\*</b> &#8212; match the expression any number of times

__e<sub>0</sub>+__ &#8212; match the expression 1 or more times

__a__ &#8212; match a literal character (__a__ in this case)

__(e<sub>0</sub>)__ &#8212; match the expression in the group

__.__ &#8212; match any character

__[abc]__ &#8212; match one of the of characters in the character class

__[a-z]__ &#8212; match a range of characters, in this case a through z

__^__ &#8212; match beginning of line

__$__ &#8212; match end of line

__&#92;+__ &#8212; force the literal version of a character (plus sign in this case)

Try and work out the example expressions given above (especially if you're new
to regular expressions).

Note that we'll be ignoring syntax like character classes, line anchors, escaped
characters and wild cards, because they have the same precedence as literals
and the details for implementing them aren't important for this article.

## Finite Automata

A _Finite Automata_, or _State Machine_, is the simplest kind of computer,
it can be in 1 (or more) of a finite number of states at a given moment, and
has no memory. We say it has no memory because a state machine doesn't know how
it got to a given state, it only knows what state it's currently in.

If you've ever seen a flow chart then you kind of understand state machines.
Each state is connected to other states by a collection of labeled arrows.
If the input to the machine matches the condition of one of those arrows,
the machine is moved into the state that the arrow points to, and awaits more
input. This is done until the machine reaches the _end state_ (or the _match state_
as we'll soon call it).

```note
Watch [this](https://www.youtube.com/watch?v=vhiiia1_hC4)
Computerphile video for a great explanation of state machines from Professor
Brailsford.
```

We can use them to represent regular expressions in the form of diagrams
(in fact, historically, regular expressions were created as a short hand for
representing said diagrams). Let's look at some examples.

Take the expression `abc`. The corresponding state machine looks like this:

```pikchr
color = 0xdfdfdf
scale = 1.3

circle "s0" big fit
arrow "a" above
circle "s1" big fit
arrow "b" above
circle "s2" big fit
arrow "c" above
circle "s3" big fit
circle at last circle rad last circle.rad/1.25
```

The machine to recognize `a(bb)+a` would look like this:

```pikchr
color = 0xdfdfdf
scale = 1.3

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

It doesn't matter what order of states these machines go through to get to the match
state because they _must_ reach it by matching the correct characters. In order for
the second machine to get from s<sub>3</sub> to s<sub>4</sub> it _must_ have gone
through the preceding states and it _must_ see an __a__ in the last character of the
string.

Also, notice that both of the machines shown will can only be in at most one
state at a time&#8212;the second machine will only match either __a__ or __b__
in s<sub>3</sub>, and thus will only ever choose one path to follow&#8212;this is
what makes them _Deterministic Finite Automata_, or DFAs.

Alternatively, one could have a state machine capable of following _more than
one_ arrow at a time, or what is known as a _Non-deterministic Finite
Automata_, or NFA.

Take the expression `abc|abd`. It could be represented like this:

```pikchr
color = 0xdfdfdf
scale = 1.3

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
scale = 1.3

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

Both of these machines _must_, as before, match the correct characters in order
to reach the match state. But unlike the first machine, which must read a _particular_
input character before moving to a new state (and thus could only be in 1 state at a
time), the second machine can transition without reading _any_ input, and therefor
could move along either one of the arrows at s<sub>0</sub>.

First question: which of these machines is easier to build? Imagine you're
reading the regexp `abc|abd` character by character, trying to parse it. If you
wanted to generate the NFA, you could simply parse it as &ldquo;__a__ then __b__ then
c, or __a__ then __b__ then __d__&rdquo;. If instead you wanted to generate the
deterministic machine, you'd have to keep track of any identical parts of the
expression, and restructure in order for it to parse as &ldquo;__a__ then __b__,
_then_ __c__ _or_ __d__&rdquo;&#8212;suffice to say, the first machine is simpler.

Due to this shorter compile time, we'll be using the NFA in our implementation.

Next question: how do we execute the instructions of the second machine?
Specifically, seeing as the first 2 arrows are unlabeled (meaning we may
follow them without taking input) and the machine has no way of knowing in
advance what characters it will see, which branch should it choose to follow?
The great Ken Thompson gave quite an interesting answer in his 1968 CACM paper:
both.

You could think of this approach as a breadth-first-search. Alternatively, the
regex implementations used by Perl, Python, Ruby and more do a
depth-first-search, and have to backtrack if the branch they choose turns out
to be wrong. Thompson's BFS approach is
[_stupidly_](https://swtch.com/~rsc/regexp/grep1p.png) fast compared with the DFS
algorithms used in most modern languages.

I'll explain the regex search algorithm in detail later in this article.

```note
It's good to know that while DFAs take longer to compile, they execute much
faster, and depending on your application, execution time may be more important
than compile time.

If you're writing a lexical analyzer, for example, expressions
are compiled when the lexer itself is compiled, and thus long compile time
isn't a big problem. If, however, you're writing something like grep, expressions
are compiled at runtime (or just-in-time), so it's best to spend less time
compiling the expressions and more time executing them.
```

## NFAs from Regular Expressions

Before we look at the actual implementation, we'll look at the relationship
between NFA diagram and regexp.

Here are the NFA equivalents of the regex operators.

```pikchr
color = 0xdfdfdf
scale = 1.3

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

The grouping operator doesn't appear in this list because (as in most languages)
it's just a way of overriding precedence.

As an example, let's build the expression `a(bb)+(c|d)?`.
It's read as :

1. A literal __a__.
2. One or more repetitions...
3. of a concatenation of __b__...
4. and __b__.
5. And at most one repetition...
6. of an alternation...
7. of __c__...
8. and __d__.

Each of the items listed above corresponds to one state of the NFA.
Putting the states together into larger sub-expressions, we get:

A literal

```pikchr
color = 0xdfdfdf
scale = 1.3
circle rad 0.12
arrow "a" above
```

A repetition of a concatenation of two literals

```pikchr
color = 0xdfdfdf
scale = 1.3
circle rad 0.12
arrow "b" above
circle rad 1st circle.rad
arrow "b" above
circle rad 1st circle.rad
arrow
arc -> from last circle.n to 1st circle.n
```

And a repetition of an alternation of two literals

```pikchr
color = 0xdfdfdf
scale = 1.3
S0: circle rad 0.12
move to S0
move up 0.36 right 0.25

S1: circle rad S0.rad

move to S1
move up 0.36 right 0.25
S2: circle rad S0.rad
arrow right "c" above

move to S1
move down 0.36 right 0.25
S3: circle rad S0.rad
arrow right "d" above

arc -> cw from S1.n to S2.w
arc -> from S1.s to S3.w

arc -> cw from S0.n to S1.w
move to S0
move down 0.36 right 0.25
line invisible
arc -> from S0.s to last line.w
```

And finally, putting these sub expressions together and adding the match state,
we get:

```pikchr
color = 0xdfdfdf
scale = 1.0

F0: circle rad 0.12
    arrow "a" above

F1: circle rad 0.12
    arrow "b" above
    circle rad F0.rad
    arrow "b" above
    circle rad F0.rad
    arrow
    arc -> from last circle.n to F1.n

move to last arrow.e

F2: circle rad 0.12
    move to F2
    move up 0.36 right 0.25

F3: circle rad F0.rad

move to F3
move up 0.36 right 0.25

F4: circle rad F0.rad

move to F3
move down 0.36 right 0.25

F5: circle rad F0.rad

arc -> cw from F3.n to F4.w
arc -> from F3.s to F5.w
arc -> cw from F2.n to F3.w

move to F2 then right 1.6

F6: circle rad F0.rad
    circle at last circle rad last circle.rad/1.25

arc -> from F2.s to F6.s
spline -> "d" above from F5.e to F6.w
spline -> from F4.e right 0.55 then down to F6.n
move to 0.15 above last spline.n
"c" color 0xdfdfdf
```

## Implementation

This article's implementation will be in Python, and can be broken into 3 major
components.

1. A parser.
2. Code to turn the regexps into NFAs (and an internal representation of NFAs).
3. A version of Ken Thompson's breadth-first-search algorithm.

We'll tackle each of these components in the following sections.

## Parsing

In his 1968 CACM paper, Ken Thompson parsed regular expressions by converting
them into postfix notation, or _reverse polish_ notation. In reverse polish,
operators come after their operands. For example, the arithmetic expression
`1 + 1` would be written as `1 1 +` in postfix. Evaluating the expression then
becomes very simple: while reading the expression, pile operands onto a stack
__A__, and operators onto a stack __B__; each time an operator is added to
__B__ check if there is already an operator at the top of the stack, and if there
is one, pop off however many operands that operator takes
(only to in the case of `+`) from stack __A__ and pile the result of the operation
back onto __A__.

Unlike in Thompson's paper though, we'll be using &rdquo;&&ldquo; instead of &rdquo;.&ldquo; as an explicit
concatenation operator.

The algorithm for converting a _infix expression_
(where operators are in between operands) to a _postfix expression_
is called the
[_shunting-yard algorithm_](https://en.wikipedia.org/wiki/Shunting-yard_algorithm).
