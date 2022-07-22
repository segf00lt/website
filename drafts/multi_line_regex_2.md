# Multi-line Regular Expressions (Part 2): Greediness

In the [last article](https://joaodear.xyz/blog/articles/multi_line_regex.html)
on multi-line regex I talked about how the default behaviour of  **$** makes
writing multi-line expressions a bit strange and unintuitive, and proposed a
change to the end-of-line assert that would eliminate said strangeness.
In this article though, I'll just want to make a note of the usefulness of
an existing construct in some regular expression implementations: greedy
and non-greedy matching.


