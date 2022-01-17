#!/usr/bin/awk -f

BEGIN { note = 0; pik = 0; acc = ""; pikcount = 1; }

# format note blocks
/```note$/ {
	note = 1
	printf "<div class=\"note\">\n<h3>NOTE</h3>\n\n"
	next
}

/```$/ && note == 1 {
	note = 0
	print "\n</div>"
	next
}

note == 1 {
	print $0
	next
}

# generate pikchr diagrams
/```pikchr$/ {
	pik = 1
	next
}

/```$/ && pik == 1 {
	pik = 0
	print "<div class=\"diagram" pikcount "\">"
	print acc | "pikchr --svg-only - | head -n -1"
	close("pikchr --svg-only - | head -n -1")
	print "</div>"
	acc=""
	++pikcount
	next
}

pik == 1 {
	acc = acc (acc == "" ? "" : ";") $0
	next
}

# ignore normal lines
pik == 0 && note == 0 {
	print $0
	next
}
