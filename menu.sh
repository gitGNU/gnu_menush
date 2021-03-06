#!/bin/sh
#
#.    Copyright (C) 2008  Matthew King
#.
#.    This program is free software: you can redistribute it and/or
#.    modify it under the terms of the GNU General Public License as
#.    published by the Free Software Foundation, either version 3 of the
#.    License, or (at your option) any later version.
#.
#.    This program is distributed in the hope that it will be useful, but
#.    WITHOUT ANY WARRANTY; without even the implied warranty of
#.    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#.    General Public License for more details.
#.
#.    You should have received a copy of the GNU General Public License
#.    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Leave the . above so that copyright() will display it and I don't have
# to have it twice.

set -e

# A placeholder function to ensure no function is empty
nothing() {
    return
}

# Display a copyright message
copyright() {
    centre Menu Shell
    echo
    grep ^#\\. "$0"|sed s/^#\\.//
    echo
    echo "Press any key to continue..."
    readchar
}

# Centre text
centre() {
    # Get screen width.
    local COLUMNS=`tput cols`

    ( if [ "$*" ]; then echo "$@"; else cat; fi ) | awk '
        { spaces = ('$COLUMNS' - length) / 2
          while (spaces-- > 0) printf (" ")
          print
        }'
}

# Right-align text
right() {
    # Get screen width.
    local COLUMNS=`tput cols`

    ( if [ "$*" ]; then echo "$@"; else cat; fi ) | awk '
        { spaces = '$COLUMNS' - length
          while (spaces-- > 0) printf (" ")
          print
        }'
}

# Read a single character from the terminal without echoing it
readchar() {
    local old_stty=$(stty -g)
    stty -icanon -echo
    if [ "$1" ]; then
	eval $1=$(head -c1)
    else
	head -c1 > /dev/null
    fi
    stty "$old_stty"
}

nomenu() {
    echo "The menu '${which_menu}' doesn't exist!" 1>&2

    return 1
}

# Run the menu
run_menu() {
    local choice
    local user_choice
    local which_menu
    local options

    which_menu=${1:-main}

    while [ "$choice" != "quit" ]; do
	# Ensure options are passed to the inner functions
	options=""
	if echo "$which_menu" | grep '[()]'; then
	    options=$(echo "$which_menu" | sed 's/.*(\(.*\))/\1/; s/,/ /g')
	    which_menu=$(echo "$which_menu" | sed 's/(.*//')
	fi

	# If one exists, they all do.
	eval "menu_${which_menu}_exists >/dev/null 2>&1 || nomenu"

	# Display the menu
	clear
	eval "menu_${which_menu}_title \"$options\""
	eval "menu_${which_menu}_text \"$options\""

	# Determine the user's choice, ensuring it's valid
	choice=""
	user_choice=""
	while [ -z "$choice" ]; do
	    if [ "$user_choice" ]; then
		$ECHO -n '\033[0;1;31mInvalid option. Please try again.\033[0m\r'
	    fi
	    readchar user_choice
	    choice=$(eval "menu_${which_menu}_choose $user_choice")
	done

	clear

	# Process the choice
	if echo "$choice" | grep -q "^menu="; then
	    # The choice is to open a new menu
	    which_menu=$(echo $choice | sed 's/^menu=//')
	else
	    if echo "$choice" | grep -q "^run="; then
		# The choice is to run something
		$(echo $choice | sed 's/^run=//') "$user_choice" "$options"
	    fi
	fi

    done
}

usage() {
    echo "Usage: $0 FILE"
}

MENU="$1"
if [ -z "$MENU" ]; then
    echo "No configuration file specified." 1>&2
    usage
    exit 1
elif [ "$MENU" = "--help" -o "$MENU" = "-help" -o "$MENU" = "-h" ]; then
    usage
    exit 0
fi
shift

# Create the menu processing functions
if [ "$BASH_VERSION" ]; then
    sedecho() { sed "s/echo/echo\ -e/g"; }
    ECHO="echo -e"
else
    sedecho() { cat; }
    ECHO=echo
fi
eval $(awk '%AWK%' < "$MENU" | sed s/\#.*// | sedecho)

run_menu
