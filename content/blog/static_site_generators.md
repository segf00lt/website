---
draft: true
---

# Thoughts on minimal, extensible Static Site Generators

At the moment, this website is powered by a few shell scripts I wrote,
which can be found [here](https://github.com/segf00lt/website).

**draft.sh** generates a blog post by converting the given markdown file to html,
and putting it in a template. **index.sh** adds the title, creation date and URL
of newly created blog posts to a tab separated file used to generate the blog
index, and the recent articles section of the homepage (existing articles have
their modified date added to one of the fields).

There are a few more, but most of the functionality is provided just by these
two. It's enough for my small blog, but isn't really a general purpose static
site generator.

In looking for inspiration to write something more generic to manage my (and
other people's) website, I came across a few interesting projects.

<!--
TODO

Try to set up my website (and maybe the montessori site)
with each of the programs below.
-->

## [zs](https://github.com/zserge/zs)

**zs** was the first program I came across, and it has some very interesting
ideas. Most notably it's ability to call other programs that read stdin, and
write their stdout to the place in the file where you called them
(this feature is also present in [**zas**](https://github.com/imdario/zas),
from which **zs** takes inspiration whilst being overall smaller).
There are also two special variables, _prehook_ and a _posthook_,
which are programs that get executed _before_ and _after_ each build,
respectively. This is quite useful for integrating preprocessors,
or generating a locally linked version of your website for previewing.

Additionally, **zs** allows defining variables in content file headers with YAML.

## [saait](https://git.codemadness.org/saait/file/README.html)

I discovered **saait** on [suckless's](https://suckless.org) website.
It's a bit more UNIX'y than **zs**. The example given of how to build
a website actually uses a Makefile to run **saait** and some other commands.
So yeah, it's very minimal.

Instead of allowing variable definition
at the top of markdown files (or actually even having anything to do with markdown
processing) the user provides a separate config file for each page. This config
file contains page title, creation and update date, path to page file, etc.
