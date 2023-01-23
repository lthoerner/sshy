#!/usr/bin/env bash
description="Usage: $0 [OPTIONS]

SSHy is a simple script to list SSH logins in a more human-readable format.
It uses the /var/log/auth.log file, and optionally auth.log.* files.

Options:
    -i,  --include-old
        Include rotated logs (numberbed backups such as auth.log.1, etc.)
    -r,  --reverse-output
        Sort entries by newest to oldest instead of oldest to newest
    -24, --24-hour
        Uses 24-hour format instead of 12-hour format for timestamps
    -t,  --timer
        Prints the script's execution time
    -h,  --help
        Displays this help message
"
AUTH_LOG_LOCATION=/var/log/auth.log

print_logins() {
    for file in "$@"; do
        msg "Reading '$file'..."
        # If the file exists and is readable
        if [ -r "$file" ]; then
            # For every line that indicates a successful login
            while read -r line; do
                pattern="($date_pattern) .* sshd\[([0-9]+)\]: Accepted (publickey|password) for (\w+) from ([0-9.]+)"

                if [[ "$line" =~ $pattern ]]; then
                    # Get the login data
                    username=${BASH_REMATCH[4]}
                    ip=${BASH_REMATCH[5]}
                    date=${BASH_REMATCH[1]}
                    authtype=${BASH_REMATCH[3]}

                    # Turn the date into a more human-readable format, e.g. "01/16/2023 12:00 PM"
                    # or "01/16/2023 12:00" if the user specified the --24-hour option
                    format="+%m/%d/%Y %I:%M %p"
                    if [ -n "$twfr_format" ]; then
                        format="+%m/%d/%Y %H:%M"
                    fi
                    date=$(date -d "$date" "$format")

                    # Summarize the login neatly
                    echo "[$date] $username logged in from $ip using a $authtype"
                fi
            done < "$file"
        # If the file does not exist
        else
            echo "Error: $file does not exist on your system or isn't readable." >&2
            return 2
        fi
    done
}

run_sshy() {
    date_pattern=$(determine_timestamp_format "$AUTH_LOG_LOCATION")
    if [ -z "$date_pattern" ]; then
        msg "Error: Could not determine the timestamp format of your auth.log file."
        return 1
    fi

    input_files=("$AUTH_LOG_LOCATION")
    if [ -n "$include_old" ]; then
        # The user specified --include-old, so include numbered logfiles like auth.log.1 etc.
        input_files=("${input_files[0]}.1")
    fi

    # Print the output lines
    if [ -n "$reverse_output" ]; then
        # If the user specified the --reverse-output option, reverse the order
        print_logins "${input_files[@]}" | tac
    else
        print_logins "${input_files[@]}"
    fi
}

determine_timestamp_format() {
    msg "Checking timestamp format..."
    read -r first_line < "$1"

    standard_pattern="^\w+\s+[0-9]+ [0-9]{2}:[0-9]{2}:[0-9]{2}";   # "Jan 16 12:00:00"
    [[ "$first_line" =~ $standard_pattern ]] &&
        msg "Using the standard timestamp format." &&
        echo "$standard_pattern" &&
        return 0

    alternate_pattern="^[0-9]+-[0-9]+-[0-9]+T[0-9:]{8}\.[0-9]+-[0-9]+:[0-9]+";  # "2023-01-16T12:00:00.123456-03:00" 
    [[ "$first_line" =~ $alternate_pattern ]] &&
        msg "Using the alternate timestamp format." &&
        echo "$alternate_pattern"
}

msg() { echo "$*" 1>&2; }

if [ "$0" = "$BASH_SOURCE" ]; then
    # Parse command line arguments
    for arg in "$@"; do
        case $arg in
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
                timer="time"
                ;;
            -h | --help | * )
                msg "$description"
                exit 0
                ;;
        esac
    done
    eval "${timer:-} run_sshy"  # eval for time builtin instead of time command
fi
