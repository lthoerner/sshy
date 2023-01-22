#!/bin/bash

# SSHy is a simple script to list SSH logins in a more human-readable format.
# It uses the /var/log/auth.log file, and optionally the /var/log/auth.log.1 file.

# Time the execution of the script
start=$(date +%s.%N)

# Parse command line arguments
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
        -t | --timer )
            timer=1
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
    echo "  -i, --include-old: Includes logs from auth.log.1, where older logs are stored"
    echo "  -r, --reverse-output: Sorts entries by newest to oldest instead of oldest to newest"
    echo "  -24, --24-hour: Uses 24-hour format instead of 12-hour format for timestamps"
    echo "  -t, --timer: Prints the script's execution time"
    echo "  -h, --help: Displays this help message"
    exit 0
fi

# Get the first line of the auth.log file to choose the correct timestamp format
first_line=$(head -n 1 /var/log/auth.log)

echo "Checking timestamp format..."

# If the auth.log file uses the "Jan 16 12:00:00" timestamp format
if [[ $(grep -oP "^\w+\s+\d+ [\d:]{8}" <<< "$first_line") ]]; then
    echo "Using the standard timestamp format."
    date_pattern="^\w+\s+\d+ [\d:]{8}"
# If the auth.log file uses the "2023-01-16T12:00:00.123456-03:00" timestamp format
elif [[ $(grep -oP "^\d+-\d+-\d+T[\d:]{8}\.\d+-\d+:\d+" <<< "$first_line") ]]; then
    echo "Using the alternate timestamp format."
    date_pattern="^\d+-\d+-\d+T[\d:]{8}\.\d+-\d+:\d+"
# If the auth.log file uses an unknown timestamp format
else
    echo "Error: Could not determine the timestamp format of your auth.log file." >&2
    exit 1
fi

input_files=()

# If the user specified the --include-old option, include logs from auth.log.1
if [ -n "$include_old" ]; then
    input_files+=("/var/log/auth.log.1")
fi

# Always include logs from auth.log
input_files+=("/var/log/auth.log")

output_lines=()

for file in "${input_files[@]}"
do
    echo "Reading $file..."
    
    # If the file exists
    if [ -f "$file" ]; then
        # For every line that indicates a successful login
        while read -r line
        do
            match=$(grep -oP "($date_pattern .* sshd\[[\d]+\]: Accepted (publickey|password) for \w+ from [\d.]+)" <<< "$line")

            if [ -n "$match" ]; then
                # Get the username
                username=$(grep -oP '(?<=for )\w+' <<< "$match")
                # Get the IP address
                ip=$(grep -oP '((\d+\.){3}\d+)' <<< "$match")
                # Get the date
                date=$(grep -oP "($date_pattern)" <<< "$match")
                # Get the authentication method
                authtype=$(grep -oP '(password|publickey)' <<< "$match")

                # Turn the date into a more human-readable format, e.g. "01/16/2023 12:00 PM"
                # or "01/16/2023 12:00" if the user specified the --24-hour option
                if [ -n "$twfr_format" ]; then
                    date=$(date -d "$date" "+%m/%d/%Y %H:%M")
                else
                    date=$(date -d "$date" "+%m/%d/%Y %I:%M %p")
                fi

                # Turn authtype from "password" to "a password" to "a key" respectively
                if [ "$authtype" = "password" ]; then
                    authtype="a password"
                else
                    authtype="a key"
                fi

                # Print the information
                output_lines+=("[$date] $username logged in from $ip using $authtype")
            fi
        done < "$file"
    # If the file does not exist
    else
        echo "Error: $file does not exist on your system." >&2
        exit 2
    fi
done

echo

# Print the output lines
# If the user specified the --reverse-output option, reverse the order
if [ -n "$reverse_output" ]; then
    for ((i=${#output_lines[@]}-1; i>=0; i--))
    do
        echo "${output_lines[$i]}"
    done
else
    for line in "${output_lines[@]}"
    do
        echo "$line"
    done
fi

# If the user specified the --timer option, print the execution time
if [ -n "$timer" ]; then
    echo
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    echo "Execution time: $runtime seconds"
fi

exit 0
