#!/bin/bash
if [ ! -d /usr/share/figlet/fonts ]; then
	echo "No figlet fonts found"
	exit 1
fi
if ! command -v figlet &>/dev/null; then
	echo "figlet not found"
	exit 1
fi
fonts="$(ls /usr/share/figlet/fonts | grep .flf | tr '\n' ' ')"
if [ ! -z "$1" ]; then
	string="$1"
else
	read -p "String to test: " string
fi	
for f in $fonts; do
	name="$(printf "$f" | rev | cut -c 5- | rev)"
        printf "\n\e[0;91m$name:\n\n\e[0m"
	figlet -f $f $string
done 
