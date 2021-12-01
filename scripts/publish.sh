#!/bin/sh

for draft in "$@"; do
	./draft.sh "$draft" > "../src/blog/articles/${draft%%'.md'}.html"
	./index.sh "$draft"
done

# Generate modified blog index page

# Update recent articles section
