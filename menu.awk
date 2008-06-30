#!/usr/bin/gawk -f

# This script is not very robust.
# There is NO error checking
# There are also no comments yet

/^\. / { print $0";"; next }

/^[[:alnum:]]/ {
    if (NF > 2)
	for (i = 3; i <= NF; i++)
	    $2 = $2" "$i;
    current_menu = $1;
    menu[current_menu] = "defined";
    current_entry = 0;
    title[current_menu] = $2;
    current_text = "head";

    next;
}

/^\"/ {
    if (match ($0, /^\"!/))
	text_line = gensub (/^\"![[:space:]]*(.*)/, "\\1 \"$options\";", "g");
    else
	text_line = "echo '" gensub (/^\"[[:space:]]*/, "", "g") "';";

    if (current_text == "head")
	head[current_menu] = head[current_menu]"\n"text_line;
    else
	foot[current_menu] = foot[current_menu]"\n"text_line;

    next;
}

/^\+/ {
    $0 = gensub (/^\+[[:space:]]*/, "", "g");

    if (NF > 3)
	for (i = 4; i <= NF; i++)
	    $3 = $3" "$i;

    echo="echo " # Space needed for tabbage
    if (match ($3, /^(<+|[>\|]) ?/)) {
	if (match ($3, /^>/))
	    echo="right "
	else if (match ($3, /^\|/))
	    echo="centre "
	else if (align = match ($3, /^<+/))
	    for (i = 0; i < align; i++)
		echo = echo"'\\t'"
	
	sub (/^(<+|[>\|]) ?/, "", $3)
    }

    current_text = "foot";

    current_entry++;
    entries[current_menu, current_entry] = "defined";
    entries_keys[current_menu, current_entry] = $1;
    entries_methods[current_menu, current_entry] = $2;
    size[current_menu] = current_entry;

    # space is already added after echo
    text[current_menu] = text[current_menu]"\n"echo"'"$3"';"

    next;
}
    

/./ { print "# NOT PROCESSED", $0 }

END {
    for (this_menu in menu) {
	print "menu_"this_menu"_exists() {";
	print "true;";
	print "};";

	print "menu_"this_menu"_title() {";
	print "nothing;";
	print "WIDTH=$(echo -n '"title[this_menu]"'|wc -m);";
	print "centre '"title[this_menu]"';";
	print "};";

	print "menu_"this_menu"_head() {";
	print "nothing;";
	print head[this_menu];
	print "};";

	print "menu_"this_menu"_foot() {";
	print "nothing;";
	print foot[this_menu];
	print "};";

	print "menu_"this_menu"_text() {";
	print "nothing;";
	print text[this_menu];
	print "};";

	print "menu_"this_menu"_choose() {";
	print "nothing;";
	for (option in entries) {
	    if (index (option, this_menu) == 1) {
		print "if echo $1 | grep -q '["entries_keys[option]"]'; then";
		print "echo '"entries_methods[option]"';";
		print "fi;";
	    }
	}
	print "};";
    }
}
