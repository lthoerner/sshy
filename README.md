# SSHy
SSHy is a simple script for displaying SSH logs in a readable format. It supports most Debian-based distributions.

## Installation
Installation can be done with just 4 commands.

First, download the installer script:  
`curl -LJO https://raw.githubusercontent.com/Eyesonjune18/sshy/main/installer/install.sh`  
This will download the script into your current working directory.

You may need to add permissions to the script in order to run it: `chmod +x install.sh`

Run the script: `./install.sh`  
This will download all necessary files into their correct places.

Put together, this (should) be able to be installed in a simple copy-paste.
```
curl -sLJO https://raw.githubusercontent.com/Eyesonjune18/sshy/main/installer/install.sh
chmod +x install.sh
./install.sh
```

The installer script will delete itself automatically when the installation finishes.

You will also need to run `sudo chmod +r /var/log/auth.log /var/log/auth.log.1` in order to allow the script to read your log files.

## Explanation & Usage
SSHy contains one command (the script itself) with multiple options.

To run the script, install Ally and use `mkal` to create a shortcut. You can also simply navigate to the working directory and run `./sshy.sh`.

### sshy
It adds an alias for any executable file to .bash_aliases. It will also remove the executable's extension if applicable.
Usage: `sshy [OPTIONS]`  

#### Options
-i, --include-old: Includes logs from auth.log.1, where older logs are stored  
-r, --reverse-output: Sorts entries by newest to oldest instead of oldest to newest  
-24, --24-hour: Uses 24-hour format instead of 12-hour format for timestamps  
-t, --timer: Prints the script's execution time  
-h, --help: Displays this help message  
