#!/usr/bin/env bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
pink='\033[0;35m'
clear_color='\033[0m'
print_help() {
    printf "${pink}show-ssid${clear_color}: a simple script written in Bash/Python to read data from WPA/WPA2 handshakes in hc22000 form.\n"
    printf "${yellow}Usage${clear_color}: "
    printf './show-ssid.sh hashfile.hc22000 [full]'
    printf "\n"
    echo "If full (or simply the letter f) is passed, output will include MIC, MAC address of client, MAC address of AP, and network SSID."
    echo "If not, output will only include the network SSID and the MAC address of the AP."
    echo "If the command-line tool oui is found, the device manufacturer will also be displayed."
    echo "Each WPA/WPA2 handshake processed is printed after these details."
    printf "${red}Example workflow:${clear_color}\n"
    echo "·Use wifite, hcxdumptool, airodump-ng etc to capture handshakes"
    echo "·Use hcxpcapngtool to convert raw .cap/.pcap/.pcapng file into a .hc22000 file"
    echo "·Use show-ssid to analyze handshake(s) captured"
    echo "·Put similar handshakes into groups"
    echo "·Prepare hashcat charsets/masks/rules for each group"
    echo "·Run hashcat"
    echo "·???"
    echo "·Profit"
    exit 1
}
if [ ! -z "$1" ]; then
    hashfile="$1"
    if [ ! -f "$hashfile" ]; then
        echo "File not found"
        print_help
    fi
else
    printf "${yellow}Path to hc22000 file ${clear_color}(one WPA/WPA2 hash per line): "
    read hashfile
    printf "\n"
fi
if [ ! -z "$2" ]; then
    flag="$2"
    case $flag in
        f | full)
            function=full
            ;;
        *)
            print_help;
            ;;
    esac
else
    function=standard
fi
hashes="$(cat $hashfile | tr '\n' ' ')"
standard() {
    python3 - $e << EOF
import hashlib, hmac, sys, struct

hashline = None

if len(sys.argv) > 1:
    hashline=sys.argv[1]
    hl = hashline.split("*")
    mac_ap = bytes.fromhex(hl[3])
    essid = bytes.fromhex(hl[5])

def show_values(mac_ap, essid):
    print('\033[32;1m'"SSID:                     ", essid.decode())
    print('\033[34;1m'"AP MAC Address:           ", "%02x:%02x:%02x:%02x:%02x:%02x" % struct.unpack("BBBBBB", mac_ap), end='')
    print('\x1b[0m', end='')

show_values(mac_ap, essid)
EOF
}
full() {
    python3 - $e << EOF
import hashlib, hmac, sys, struct

hashline = None

if len(sys.argv) > 1:
    hashline=sys.argv[1]
    hl = hashline.split("*")
    mic = bytes.fromhex(hl[2])
    mac_ap = bytes.fromhex(hl[3])
    mac_cl = bytes.fromhex(hl[4])
    essid = bytes.fromhex(hl[5])

def show_values(mic, mac_ap, mac_cl, essid):
    print('\033[33;1m'"MIC:                      ", mic.hex())
    print('\033[32;1m'"SSID:                     ", essid.decode())
    print('\033[34;1m'"AP MAC Address:           ", "%02x:%02x:%02x:%02x:%02x:%02x" % struct.unpack("BBBBBB", mac_ap))
    print('\033[35;1m'"Client MAC Address:       ", "%02x:%02x:%02x:%02x:%02x:%02x" % struct.unpack("BBBBBB", mac_cl), end='')
    print('\x1b[0m', end='')

show_values(mic, mac_ap, mac_cl, essid)
EOF
}

for e in $hashes; do
    if [ "$function" == "full" ]; then
        outputs="$(full)"
    elif [ "$function" == "standard" ]; then
        outputs="$(standard)"
    fi
    echo "$outputs"
    if command -v oui >/dev/null 2>&1; then
        printf "${red}Device manufacturer:       ${clear_color}"
        ap_mac="$(printf "$outputs" | grep "AP MAC" | grep -oE "[0-9,A-F,a-f]{2}:[0-9,A-F,a-f]{2}:[0-9,A-F,a-f]{2}:[0-9,A-F,a-f]{2}:[0-9,A-F,a-f]{2}")"
        oui $ap_mac | tail -n 2 | head -n 1 | cut -c 50- | rev | cut -c 75- | rev 
        printf "${clear_color}\n"
    fi
    printf "$e\n\n"
done
