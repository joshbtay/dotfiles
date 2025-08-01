#!/bin/bash

# Define your options here
options=("Install Git" "Set up Zsh" "Install Vim" "Configure Tmux" "Install Neovim")

# Create an array to track selected options (0: not selected, 1: selected)
selected=()

# Initialize all options to unselected (0)
for i in "${!options[@]}"; do
    selected[i]=1
done

# Initialize variables for navigation
index=0
num_options=${#options[@]}

# Function to display the menu
display_menu() {
    clear
    echo "Select options to install/configure:"
    echo "[j/k] to navigate, [space] to toggle, [q] to quit, [c] to confirm."

    for i in "${!options[@]}"; do
        if [ ${selected[i]} -eq 1 ]; then
            status="[x]"
        else
            status="[ ]"
        fi

        if [ $i -eq $index ]; then
            # Highlight the current option
            echo -e "\033[1;32m$status ${options[$i]}\033[0m"
        else
            echo "$status ${options[$i]}"
        fi
    done
}

handle_keypress() {
    IFS= read -rsn1 input  # Read one character silently

    case "$input" in
        j)  # Move down
            index=$(( (index + 1) % num_options ))
            ;;
        k)  # Move up
            index=$(( (index - 1 + num_options) % num_options ))
            ;;
        " " )  # Toggle selection
            selected[$index]=$((1 - ${selected[$index]}))
            ;;
	q)
            tput cnorm  # Show the cursor again before quitting
            clear
            echo "You selected:"
            for i in "${!options[@]}"; do
                if [[ ${selected[i]} -eq 1 ]]; then
                    echo "- ${options[i]}"
                fi
            done
            exit 0
            ;;
	c)  tput cnorm
            exit 0
            ;;

    esac
}


tput civis  # Hide the cursor
trap "tput cnorm; clear; exit" INT TERM EXIT  # Ensure cursor is restored on exit
# Main loop
while true; do
    display_menu
    handle_keypress
done

