# Regex from scratch

## Introduction

Around September this year I had the idea to write grep by myself.
This meant I would also have to implement regular expressions. Little did I
know, this project would turn out to be the most fun and challenging
undertaking of the year (up till then).

Throughout this article I'll reference the resources that helped me during this
project, and that I hope will help others who decide to give it a try.

## What are regular expressions _really_?

Regular expressions, as many programmers will know, are a compact way of describing arbitrary
patterns of text, such as:

- `a+` the letter 'a' one or more times
- `.*` any character any number of times
- `[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*@[a-zA-Z0-9_].(com|co\.uk|xyz|io|net|)` an
  email address

These expressions range from benign literal strings, to URL's, email addresses,
C function declarations and more. So how the hell do we implement them?

## Finite Automata

Don't be intimidated by the name of this section. A _Finite Automata_, or
_State Machine_, is a computer with no memory, that can be in 1 or more
(we'll come back to this) of a finite number of states at a given moment.

If you've ever seen a flow chart then you kind of understand state machines.
Each state is connected to other states by a collection of labeled arrows. If
the input to the machine matches the condition of one of those arrows, the
machine is moved into the state that the arrow points to, and awaits more
input. This is done until the machine reaches the _end state_ (or the _match state_
as we'll soon call it).

Before you continue, watch [this](https://www.youtube.com/watch?v=vhiiia1_hC4)
Computerphile video for a great intuitive explanation of state machines from
Professor Brailsford.

Alright, now that you've heard the Professor's explanation, let's see how this
relates to regular expressions.


