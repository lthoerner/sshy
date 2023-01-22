#!/bin/bash

echo "Creating folder for installation at ~/.local/bin/sshy"
mkdir -p ~/.local/bin
mkdir -p ~/.local/bin/sshy

install="$HOME/.local/bin/sshy"

echo "Downloading script file to install folder"
curl -sLo "$install/sshy.sh" https://raw.githubusercontent.com/Eyesonjune18/sshy/main/src/sshy.sh

echo "Setting up permissions for script file"
chmod +x "$install/sshy.sh"

echo "SSHy has been installed successfully. It is recommended that you install Ally (https://github.com/Eyesonjune18/ally) to manage your scripts."
echo "To add an alias for SSHy, run 'cd ~/.local/bin/sshy && mkal sshy'"

shred -u "$0"
