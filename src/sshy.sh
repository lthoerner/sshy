#!/bin/bash

# SSHy is a simple script to list SSH logins in a more human-readable format.
# It uses the /var/log/auth.log file.

# Get the options
while [ "$1" != "" ]; do
    case $1 in
        -i | --include-old )
            include_old=1
            ;;
        -r | --reverse-output )
            reverse_output=1
            ;;
        -24 | --24-hour )
            twfr_format=1
            ;;
        -h | --help )
            help=1
            ;;
        * )
            help=1
    esac
    shift
done

# If the user specified the help option, print the help message and exit
if [ -n "$help" ]; then
    echo "Usage: ./sshy.sh [OPTIONS]"
    echo "Options:"
    echo "  -i, --include-old: Includes logs from auth.log.1"
    echo "  -r, --reverse-output: Sorts entries by newest to oldest instead of oldest to newest"
    echo "  -24, --24-hour: Uses 24-hour format instead of 12-hour format for timestamps"
    echo "  -h, --help: Displays this help message"
    exit 0
fi

output_lines=()

# For every line that indicates a successful login
# If the user specified the include-old option, include logs from auth.log.1
while read -r line
do
    match=$(grep -oP '(\w+ [\d]{2} [\d:]{8} .* sshd\[[\d]+\]: Accepted (publickey|password) for \w+ from [\d.]+)' <<< "$line")

    if [ -n "$match" ]; then
        # Get the username
        username=$(grep -oP '(?<=for )\w+' <<< "$match")
        # Get the IP address
        ip=$(grep -oP '((\d+\.){3}\d+)' <<< "$match")
        # Get the date
        date=$(grep -oP '(\w+ [\d]{2} [\d:]{8})' <<< "$match")
        # Get the authentication method
        authtype=$(grep -oP '(password|publickey)' <<< "$match")

        # Turn the date into a more human-readable format, e.g. "01/16/2023 12:00 PM" or "01/16/2023 12:00"
        if [ -n "$twfr_format" ]; then
            date=$(date -d "$date" "+%m/%d/%Y %H:%M")
        else
            date=$(date -d "$date" "+%m/%d/%Y %I:%M %p")
        fiz

        # Turn authtype from "password" to "a password" to "a key" respectively
        if [ "$authtype" = "password" ]; then
            authtype="a password"
        else
            authtype="a key"
        fi

        # Print the information
        output_lines+=("[$date] $username logged in from $ip using $authtype")

    fi
done < /var/log/auth.log

# Print the output lines
for line in "${output_lines[@]}"
do
    echo "$line"
done

exit 0
