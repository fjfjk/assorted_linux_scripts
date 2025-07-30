#!/usr/bin/env bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
clear_color='\033[0m'
if ! command -v hcxdumptool >/dev/null 2>&1; then
    printf "${red}Error${clear_color}: hcxdumptool is not installed\n"
    exit 1
fi
print_help() {
    echo "This script takes a text file containing MAC addresses and processes them into a Berkley packet filter with hcxdumptool."
    echo "It can be used to blacklist (protect) devices from hcxdumptool, or whitelist (attack) specific devices."
    echo 'Usage: ./hcx_make_bpf.sh -[ap] FILE [directory]'
    echo "-a: attack"
    echo "-p: protect"
    echo "FILE: path to a file with one MAC address per line"
    echo "directory (optional): where to write output files (if not passed, the current directory is used)"
    exit 1
}
while getopts ':a:p' option; do
    case $option in
        a)
            printf "Creating filter with networks to ${red}attack${clear_color}\n"
            method="wlan"
            outfile="attack_$(date '+%Y%m%d-%H%M').bpf"
            ;;
        p)
            printf "Creating filter with networks to ${green}protect${clear_color}\n"
            method="not wlan"
            outfile="protect_$(date '+%Y%m%d-%H%M').bpf"
            ;;
        ?)
            print_help
            exit 1
            ;;
    esac
done
shift 1
if [ -z "$1" ]; then
    printf "${yellow}"
    read -p "Text file with target BSSIDS: " ssid
    printf "${clear_color}"
else
    ssid="$1"
fi
if [ -z "$2" ]; then
    wdir="$(pwd)"
else
    wdir="$2"
fi
first_count="$(wc -l < $ssid)"
second_count="$(grep -E "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$" $ssid | wc -l)"
if [ $first_count != $second_count ]; then
    printf "${red}File contains errors${clear_color}\n"
    exit 1
fi
printf "${yellow}Formatting MAC addresses...${clear_color}\n"
ssids_processed="ssids-$(date '+%Y%m%d-%H%M').txt"
cat $ssid | sed -e 's/\(.*\)/\L\1/' | sed -e 's/[\:\-]//g' >> $wdir/$ssids_processed
num=1
while IFS= read -r line; do
        #The next line was useful for debugging but it's not really necessary anymore
        #echo "Adding SSID $line with command hcxdumptool --bpfc=\"$method addr$num $line\""
        hcxdumptool --bpfc="$method addr$num $line" >> $wdir/$outfile
        num=$(($num + 1))
   done < $wdir/$ssids_processed
echo "Berkeley packet filter saved at $wdir/$outfile"
rm $wdir/$ssids_processed
