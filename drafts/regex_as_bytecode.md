# Regular Expressions as Bytecode

## Introduction

This my contribution to a [series of articles](https://swtch.com/~rsc/regexp/)
on regular expressions by Russ Cox. In this article, I'll compare different
ways regular expressions may be represented, and how I came to represent them
in my implementation.

This article is not an introductory read, so I'd recommend reading Cox's stuff
first if you've never had a go at implementing regular expressions yourself,
although jumping in at the deep end isn't necessarily bad.

## Finite Automata

First, I'll quickly go over _Finite Automata_.

_Finite Automata_, or _State Machines_, are the simplest kind of computer,
and they can be used to describe arbitrary patterns of text identically to
regular expressions (historically regular expressions were actually made to
represent finite automata in a concise way).

Take the expression `abc`. The corresponding automata looks like this:

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
arc -> from 4th circle.n to 2nd circle.n
circle at last circle rad last circle.rad/1.25
```

These NFAs serve as the conceptual framework from which the representations
I'll compare in this article derive.

## Graphs

This is the most direct representation of the NFAs in code (and was also the
first I encountered). Since the NFA diagram is itself a graph, it can be very
easily represented in code with a node based data structure.

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

Here's a diagram of how the expression `a|bc?` would look.

```pikchr
color = 0xdfdfdf

B1: box "s0:" "type = BRANCH," "arrow_0 = &s1," "arrow_1 = &s2 " fit
move to B1 then right 0.9 then up 0.7
B2: box "s1:" "type = LITERAL," "c = 'a'," "arrow_0 = &s3" fit
move to B1 then right 0.9 then down 0.7
B3: box "s2:" "type = LITERAL," "c = 'b'," "arrow_0 = &s3" fit
move to B1 then right 2
B4: box "s3:" "type = BRANCH," "arrow_0 = &s4," "arrow_1 = &s5" fit
move up 0.7 then right 0.7
B5: box "s4:" "type = LITERAL," "c = 'c'," "arrow_0 = &s4" fit
arrow "&s5" above from B4.e right 2.5
B6: box "s5:" "type = MATCH" fit

spline -> from B1.n up then right to B2.w
move to 0.3 left of last spline.nw
"&s1" color 0xdfdfdf

spline -> from B1.s down then right to B3.w
move to 0.3 left of last spline.sw
"&s2" color 0xdfdfdf

spline -> from B2.e right then down to B4.n
move to 0.15 above last spline.n
"&s3" color 0xdfdfdf

spline -> from B3.e right then up to B4.s
move to 0.15 below last spline.s
"&s3" color 0xdfdfdf

spline -> from B4.e right then up then right to B5.w
move to last spline.n
"&s4" color 0xdfdfdf

spline <- from B6.w left then up then left to B5.e
move to 0.15 left of last spline.e
"&s5" color 0xdfdfdf
```

Once the graph is constructed, only the address of `s0` is returned.

The main drawback of this representation is that the graphs cannot be altered
after construction because only the pointer to the first node is returned by
the compiler. This is prevents us from doing sub-matching in the most efficient
way, adding the sub-graph of the expression `.*` at the beginning and end of
the main graph. Instead, sub-matches must be done by trying to match the input
string n times, each time starting from the nth character in the string, which
has an O(n<sup>2</sup>) time complexity.

## Instructions

Another way of representing NFAs is as instructions for a virtual machine, as shown
in the second Russ Cox article.

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

Now instead of linking every struct as a node in a graph, we just store
them sequentially in an array. There are pointer members in the struct, but
now they are only used when branching to 2 different states (in an __ALT__)
or jumping foward or backward to another state (in a __JUMP__).

This doesn't make compilation much less tricky, but it get's around the
immutability problem of graphs, allowing us to insert the instructions for `.*`
at the beginning and end of an expression if we wish to perform sub-matches.

Unfortunately, (as was the case with graph nodes) these instructions
often have many empty fields, resulting in unsused memory, and, if we wish to
extend the syntactic functionality of our regex implementation, it will come at
the cost of yet more unused memory.

## Bytecode

In order to address the shortcomings of the previous representations, I decided
that my regex implementation would represent the NFA using a stream of bytes,
with opcodes marking the beginning of each instruction just like a normal
machine language. This stream is stored in the `bin` member of a struct
called `regex_t` , which has another member `len` for storing the length of the
stream in bytes.

The instructions are as follows:

__CHAR__ (OPCODE 1): `\x1<character to match>`

__WILD__ (OPCODE 2): `\x2`

__JUMP__ (OPCODE 3): `\x3<n bytes to jump foward>`

__BACK__ (OPCODE 4): `\x4<n bytes to jump backward>`

__ALT__: (OPCODE 5) `\x5<n bytes to inst at end of arrow 0><n bytes to inst at end of arrow 1>`

__CLASS__ (OPCODE 6): `\x6<length of class string in bytes><class string>`
         
__BLINE__ (OPCODE 7): `\x7`
         
__ELINE__ (OPCODE 8): `\x8`
         
__MATCH__ (OPCODE 11): `\xB`

Instead of using pointers to branch off or jump foward and backward to other
instructions, __JUMP__, __BACK__ and __ALT__ store the relative distance in
bytes to the instructions to which they lead.

As an example, here's the case for generating an _at most one_
repetition (e.g. __e?__).

```
case '?':
	/* pop the compiled expression 'e' off the stack */
	frag0 = POP(stack, stack_top);

	/* create instruction for '?' */
	tmp.len = ALTLEN; /* length of an ALT instruction in bytes */
	tmp.bin = (char*)calloc(tmp.len + 1, sizeof(char));
	tmp.bin[OP] = ALT;

	/* set relative jumps
	*
	* NOTE:
	* ARROW_0 and ARROW_1 are the offsets for where to store each jump
	* value. The value of each jump is stored in a pair of consecutive
	* bytes. This is done in order to allow for jumps greater than 255.
	* Manipulation of these bytes is done by the functions setnum() and
	* getnum().
	*
	*/
	setnum(tmp.bin + ARROW_0, 4);
	setnum(tmp.bin + ARROW_1, frag0.len + 2);

	/* join compiled expression 'e' and '?' instruction */
	frag0 = fragcat(tmp, frag0);

	/* pile the new frag0 onto the stack */
	PILE(stack, stack_top, frag0);
	break;
```

With this representation we get something which describes a pattern of text
almost as compactly in memory as regular expressions themselves (instructions
are sized between 1 and 5 bytes, __CLASS__ being the only instruction that
varies). The bytecode can be mutated by simple array manipulation, and can be
extended without affecting the memory usage of existing syntax.

## Conclusion

As I said before, this article was not intended to be in any way an
introduction to implementing regular expressions. So, in case you felt lost
reading this (and as an acknowledgement of those whom were unknowingly my
tutors on the subject), here are links to the resources I discovered during the
writing of my regex implementation, including the git repo where my code is.

- [_Implementing Regular Expressions_](https://swtch.com/~rsc/regexp/), Russ Cox
- [_Computers Without Memory_](https://www.youtube.com/watch?v=vhiiia1_hC4), Computerphile
- [_Regex under the hood: Implementing a simple regex compiler in Go_](https://medium.com/@phanindramoganti/regex-under-the-hood-implementing-a-simple-regex-compiler-in-go-ef2af5c6079), Phanindra Moganti
- [My git repo](https://github.com/segf00lt/jgrep) (the files are regex.c and regex.h)
