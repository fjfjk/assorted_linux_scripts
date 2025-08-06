Scripts I wrote to automate stuff on GNU/Linux devices, uploaded to this repo because uploading to GitHub Gists is annoying and nobody would ever be able to find stuff uploaded there.

Not intended to be universal -- these will not work on any of the BSDs, macOS, or Android (unless inside a GNU/Linux chroot).

·chroot-jail-setup.sh: creates a bare-bones (bash and nothing else) chroot at /jail and user 'prisoner' to allow you to forward services from another device to yours via SSH without exposing your credentials or facilitating any counterattack

·hcxinstall.sh: replace the broken/outdated version of hcxdumptool/hcxtools found in Kali Linux apt repos with one built automatically from latest sources on ZeroBeat's github

·hcx_make_bpf.sh: turn a list of MAC addresses into a Berkley packet filter for use with hcxdumptool

·show-ssid.sh: output human readable values from an .hc22000 file of WPA/WPA2 handshakes

·start-chroot.sh: mount and enter a chroot environment (note: must already exist)

·test-fonts.sh: test a string to see how it looks in installed figlet fonts
