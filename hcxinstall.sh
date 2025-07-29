#!/usr/bin/env bash
#script to remove outdated/broken versions of hcxtools/hcxdumptool from Kali apt repos
#and replace them with new versions built from latest sources on ZeroBeat's GitHub
if [ $EUID -ne 0 ]; then
	echo "Run it as root"
	exit 1
fi
grep "kali" /etc/debian_version > /dev/null
is_os_kali="$?"
if [ "$is_os_kali" -ne 0 ]; then
	echo "This script uses Kali's package names to install dependencies."
	echo "It is unlikely to work on other Linux distros."
	exit 1
fi
if command -v hcxdumptool >/dev/null 2>&1; then
	echo "Removing current version of hcxdumptool"
	apt remove hcxdumptool -y
fi
if command -v hcxpcapngtool >/dev/null 2>&1; then
	echo "Removing current version of hcxtools"
	apt remove hcxtools -y
fi
echo "Updating package list"
apt update
packages="git pkg-config libpcap-dev zlib1g-dev libcurl4-openssl-dev build-essential make openssl"
apt install $packages -y
bulk_install="$?"
if [ $bulk_install -ne 0 ]; then
	echo "Bulk installation of required packages failed. Attempting one by one"
	for p in $packages; do
		apt install $p -y
	done
fi
if [ -d $HOME/hcxdumptool ]; then
	echo "Updating repo"
	cd $HOME/hcxdumptool
	git pull
else
	echo "Cloning repo"
	cd $HOME
	git clone https://www.github.com/ZerBea/hcxdumptool
fi
if [ -d $HOME/hcxtools ]; then
	echo "Updating repo"
	cd $HOME/hcxtools
	git pull
else
	echo "Cloning repo"
	cd $HOME
	git clone https://www.github.com/ZerBea/hcxtools
fi
build_and_install() {
echo "Building hcxdumptool"
cd $HOME/hcxdumptool
make -j $(nproc --all)
make install
echo "Building hcxtools"
cd $HOME/hcxtools
make -j $(nproc --all)
make install
}
build_and_install
built="$?"
if [ $built -eq 0 ]; then
	echo "hcxdumptool installed at $(which hcxdumptool)"
	echo "version: $(hcxdumptool --version)"
	hcxtools="hcxhash2cap hcxnmealog hcxpmktool hcxwltool hcxeiutool hcxhashtool hcxpcapngtool hcxpsktool"
	for h in $hcxtools; do
		echo "$h installed at $(which $h)"
		echo "Version: $($h --version)"
	done
else
	echo "Build failed"
	exit $built
fi
