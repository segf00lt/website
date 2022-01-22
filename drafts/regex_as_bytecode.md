# Regular Expressions as Bytecode

## Introduction

This my contribution to a [series of articles](https://swtch.com/~rsc/regexp/)
on regular expressions by Russ Cox. For context I'd recommend reading those
first.

In this article, I'll focus on comparing different ways regular expressions may be
represented, and how I came to represent them in my implementation.

## Finite Automata

First, I'll quickly go over _Finite Automata_.

```note
Watch [this](https://www.youtube.com/watch?v=vhiiia1_hC4)
Computerphile video for a great explanation of state machines from Professor
Brailsford.
```

_Finite Automata_, or _State Machines_, are the simplest kind of computer,
and they can be used to describe arbitrary patterns of text identically to
regular expressions (historically regular expressions were actually made to
represent finite automata in a concise way).

Take the expression `abc`. The corresponding automata looks like this:

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

They're executed by starting from the initial state, reading a character, and
comparing it to the current arrows label. If the character matches the label,
the arrow is followed to the next state. If the machine is in the final state
by the time all characters have been read, it has successfully matched the
string. Finite automata have no memory of how they got to a given state, they only
know what state they are currently in.

Finite automata may also posses unlabeled arrows which are followed without
reading input, and are known as _Non-deterministic Finite Automata_.

An example would be the machine to recognize `a(bb)+a`:

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
arrow
circle "s4" big fit
arrow "a" above
circle "s5" big fit
arc -> cw from 4th circle.s to 2nd circle.s
circle at last circle rad last circle.rad/1.25
```

These NFAs serve as the main conceptual representation for regular expressions
from which the representations I'll compare in this article derive.

## Trees

This is the most direct representation of the NFAs in code (and was also the
first I encountered). Since the NFA diagrams already strongly resemble trees,
or node based data structures more generally, this is likely to be the first
representation one would try and implement.

```
enum type {
	LITERAL,
	WILD,
	CLASS,
	BRANCH,
	BLINE, /* match beginning of line */
	ELINE, /* match end of line */
	MATCH,
};

struct state {
	int type;
	char c;
	char* class;
	struct state* arrow_0;
	struct state* arrow_1;
};

typedef struct state State;
```

In the C struct shown above, the `type` field denotes whether this node matches
a literal character, a wild-card or a class of characters, or also if it is a
branch node with 2 unlabeled arrows. The `c` field stores the character to be
matched (if the node is of type __LITERAL__), and `class` stores a string of
the characters in a character class (if the node is of type __CLASS__). Only
`arrow_0` is used if the node is not of type __BRANCH__, otherwise both arrows
are used. Repetition operators are, as in NFA diagrams, created by arranging
__BRANCH__ nodes in certain ways.

Compiling regular expressions to these trees of nodes can be tricky for some as
it is a very pointer heavy procedure, and involves a lot of memory management
(the trees also consume a lot of memory, 30+ bytes per node).

Another drawback of this representation is that the trees cannot be altered
after construction, which is useful for sub-matching, as the nodes for the
expression `.*` could be added at the beginning and end of the main tree.
Instead, sub-matches must be done by trying to match the input string n times,
each time starting from the nth character in the string, which has an
O(n<sup>2</sup>) time complexity.

## Instructions

In
[&ldquo;Regular Expression Matching: the Virtual Machine Approach&rdquo;](https://swtch.com/~rsc/regexp/regexp2.html),
we find another way of representing NFAs: as instructions for a virtual machine.

```
enum OPCODES {
	CHAR,
	WILD,
	JUMP,
	ALT,
	CLASS,
	BLINE,
	ELINE,
	MATCH,
};

struct inst {
	int op;
	char c;
	char* class;
	struct inst* next_0;
	struct inst* next_1;
};

typedef struct inst Inst;
```

Once again we have some pointers in the struct, but they will only be used by
ALTs and JUMPs to jump to specific instructions in the program, otherwise,
instructions will simply be stored sequentially in an array.

This get's around the immutability problem of trees, allowing us to insert the
instructions for `.*` at the beginning and end of an expression if we wish to
perform sub-matches.

Unfortunately though, as with the tree nodes, these instructions consume lots
of memory. This is where my representation comes in.

## Bytecode

When I came across the VM Approach, I found it strange that an array of structs
was used instead of something looking more like machine language, so I decided
that for my implementation, that's exactly what I'd do.

```
enum OPCODES {
	CHAR  = 1,
	WILD  = 2,
	JUMP  = 3,
	BACK  = 4,
	ALT   = 5,
	CLASS = 6,
	BLINE = 7,
	ELINE = 8,
	MATCH = 11,
};
```

On it's own the enum says little about the various instructions of our machine
language because the structure of the bytecode comes from the various rules in
the compilers code generator. The instructions are as follows:

__CHAR__: `\x1<character to match>`

__WILD__: `\x2`

__JUMP__: `\x3<n bytes to jump foward>`

__BACK__: `\x4<n bytes to jump backward>`

__ALT__: `\x5<n bytes to inst at end of arrow 0><n bytes to inst at end of arrow 1>`

__CLASS__: `\x6<length of class string in bytes><class string>`

__BLINE__: `\x7`

__ELINE__: `\x8`

__MATCH__: `\x11`

Note that the values in __JUMP__, __BACK__ and __ALT__ each take up 2 bytes,
because I don't want my expressions to be limited to around 255 characters, so
I came up with some neat bit-hacks to treat 2 consecutive bytes as a single number.

With this representation we get something which describes a pattern of text
almost as compactly in memory as regular expressions themselves, but which can
be mutated by simple array manipulation, and can be extended without affecting
the memory usage of existing syntax.

## Conclusion

Many things were left out in this article in the interest of brevity, but, potentially,
at the expense of clarity. So, I'll leave you with some links to various resources
I discovered during the writing of my regex implementation, including the git repo
where my code is.

- [_Implementing Regular Expressions_](https://swtch.com/~rsc/regexp/), Russ Cox
- [_Computers Without Memory_](https://www.youtube.com/watch?v=vhiiia1_hC4), Computerphile
- [_Regex under the hood: Implementing a simple regex compiler in Go_](https://medium.com/@phanindramoganti/regex-under-the-hood-implementing-a-simple-regex-compiler-in-go-ef2af5c6079), Phanindra Moganti
- [My git repo](https://github.com/segf00lt/jgrep)
  (feel free to open an issue if you have a question about the implementation)
