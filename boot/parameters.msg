------------------------------------
Miscellaneous LIVECD boot-parameters
------------------------------------

(You should not need any of these parameters when installing on a standard SUN 
 Ultra5/10 machine)

ide=nodma       This forces the disabling of DMA in the kernel. If your system
                has trouble reading from your IDE CDROM, try this option. This
                also disables the default hdparm settings from being executed.
nodetect        This disables all of the autodetection done by the boot CD (so
                don't use this after installation), including device detection
                and DHCP probing. This is useful for debugging of a failing CD
                or driver.
nodhcp          This disables DHCP probing on detected network cards.  This is
                useful on networks with only static addresses.
nogpm           Disables gpm console mouse support.
nohotplug       Disables the loading of  the hotplug and coldplug init scripts 
                at boot. This is useful for doing debugging of a failing CD or 
                driver.
nousb           Disables the autoloading of USB modules to debug USB issues.
docache         This caches the entire runtime portion of the LIVECD into RAM,
                which allows you to umount /mnt/cdrom and mount another CDROM.
                This option requires that you have at least twice as much
                available RAM as the size of the CD.

Type `help' to view the Help menu.

