#!/bin/sh

set -e

# A placeholder function to ensure no function is empty
nothing() {
    return
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
	eval "menu_${which_menu}_head \"$options\""
	eval "menu_${which_menu}_text \"$options\""
	eval "menu_${which_menu}_foot \"$options\""
	echo

	# Determine the user's choice, ensuring it's valid
	choice=""
	while [ -z "$choice" ]; do
	    if [ "$user_choice" ]; then
		echo -n $'\033[0;1;31mInvalid option. Please try again.\033[0m\r'
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
		$(echo $choice | sed 's/^run=//')
		# Let the user see any output
		sleep 3
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
eval $(cat "$MENU" | awk '%AWK%')

run_menu
