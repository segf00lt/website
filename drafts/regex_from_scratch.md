# Regex from scratch

## Introduction

Around September this year I had the idea to write grep by myself.
This meant I would also have to implement regular expressions. Little did I
know, this project would turn out to be the most fun and challenging
undertaking of the year (up till then).

Throughout this article I'll reference the resources that helped me during this
project, and that I hope will help others who decide to give it a try.

## What are regular expressions?

Regular expressions, as many programmers will know, are a compact way of describing arbitrary
patterns of text, such as:

- `a+` the letter 'a' one or more times
- `.*` any character any number of times
- `[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*@[a-zA-Z0-9_]+\.(com|co\.uk|xyz|io|net|)` an
  email address

Here's a quick overview of the syntax:

__a+__ - match the preceding character (or group) 1 or more times

__a__<b>\*</b> - match the preceding character (or group) any number of times

__a?__ - match the preceding character (or group) at most once

__(abc)__ - match the sequence of characters in parentheses

__[abc]__ - match one of the set of characters in parentheses

__a|b__ - match first character (or group) or second character (or group)

__ab__ - match one character followed by another

__^__ - match beginning of line

__$__ - match end of line

__.__ - match any character

__[a-z]__ - match a range of characters, in this case a through z

Try and work out the example expressions given above if you're new to regular expressions.
Also, in our implementation, to force the literal version of any character it must be
escaped with a backslash.

As you can see, these expressions can range from benign literal strings, to
URL's, email addresses, C function declarations and more. So how do we
implement them?

## Finite Automata

A _Finite Automata_, or _State Machine_, is a computer with no memory, that can
be in 1 or more of a finite number of states at a given moment (we'll come back
to this).

If you've ever seen a flow chart then you kind of understand state machines.
Each state is connected to other states by a collection of labeled arrows. If
the input to the machine matches the condition of one of those arrows, the
machine is moved into the state that the arrow points to, and awaits more
input. This is done until the machine reaches the _end state_ (or the _match state_
as we'll soon call it).

Before you continue, watch [this](https://www.youtube.com/watch?v=vhiiia1_hC4)
Computerphile video for a great explanation of state machines from Professor
Brailsford.

Alright, now that you've heard the Professor's explanation, let's see how this
relates to regular expressions.

Take the expression `ab`.

```pikchr
color = 0xdfdfdf

circle "s0" big fit 
arrow "a" above 
circle "s1" big fit 
arrow "b" above 
circle "s2" big fit 
circle at last circle rad last circle.rad/1.25
```

The state machine diagram of this expression reads:
In s<sub>0</sub>, read a character, and if it's an __a__, move
to s<sub>1</sub>. In s<sub>1</sub>, read another character and if it's
a __b__, move to s<sub>2</sub>. In s<sub>2</sub> end execution and return
a match.
