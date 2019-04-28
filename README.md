# Linux Distro for Sun Ultra5 / Ultra10 Sparc 2 machines

```
Blessed are the cheesemakers
Blessed are the meek
Blessed are the bignoses
Oooh, that's nice, isn't it?
 - from Monty Python's The Life of Brian
 ```
     
BigNose Linux is a binary Linux installation for Sun Ultra5/10 computers and is based on the Gentoo Linux __meta-distro__,  The BigNose Linux distro is primarily intended to quickly create a web server using the classical LAMP-stack  (Linux, Apache, MySQL and PHP) with Joomla and a few other useful web-based management tools. 

## About this Distro

This distro is built for Sun Ultra5/10 computers with an ATI 3D Rage graphics card  and the Happy Meal network interface card (NIC) on the motherboard  and a minimum 4.5GB hard drive on the primary IDE interface. Support for other Sparc-based Sun computers and other hardware is not yet included for, but this distro may well turn out to work OK on other 64-bit, Sparc II-based Sun machines. Since this distro is based on the Gentoo __meta-distro__, you should be able to make most compatible hardware work once you are up and running if required. 

This distro CD installs a binary installation on your Sun Ultra5/10 computer, which should save you many days of work (no, really) to get Linux installed  on your Ultra5/10. The distro CD also serves as a minimal LiveCD to help you recover your system.  

## Why

Breathe some life into your Sun Ultra5 and Ultra10 machine!

Many people still own and love Ultra 5 and Ultra 10 machines since they are built like little fortresses and are very reliable and run very quiet. They are also dirt cheap on eBay (on average £20 per machine). They were, after all, the first 64-bit desktops available on the open market 20 years ago and they sure weren't cheap then. The nice thing is that  they use commodity hardware and any PC monitor and most IDE hard disks work with them.

Ultra 5 and Ultra 10 machines are  not particularly useful for today's graphical computing needs any more and even their 270MHz - 330MHz clockspeeds make them relatively non-performant when you get machines that have 10 times the clockspeed speed. 

However, if all you want to do is build a quick web server or experiment with computer grids, this is one way to set such a system up and running at minimal cost and effort. 

## Installation

Download the ISO image, burn it to CD and boot your beloved Sun Ultra5 or Ultra 10 box up with it.

As you probably know, Sun machines are quite different to x86-based machines, so the booting process is also different. For starters, you need a Sun keyboard or a serial terminal to the machine.

Enter the OpenProm environment by hitting the Stop+A (L1+A on some Sun keyboards) key-combination. The prompt will change to ```ok```. If you are at the ```boot:``` prompt, type ```halt``` to get the ok prompt. 

To boot from the CD, type: ```ok boot cdrom```

You will eventually be greeted with a pretty message and a ```boot:``` prompt. At the ```boot:``` prompt, type the following:

```boot: bignose```

This will boot the live CD. To start the installation, execute the command at the command prompt:

```InstallDistro.sh```

 - and follow the installation wizard. If your hardware was as was expected, you should have a fully functioning webserver on you Ultra5/10 machine in under 30 minutes.
 
 ## Included Packages 

 The following software tools and packages are included:
 
 Linux kernel 2.6.24, Apache Web Server 2.2.8, MySQL Database 5.0.24, PHP 5.2 6, gcc 4.1.2, python 2.4.4, perl 5.8.8, tcl 8.4.1, webalizer, phpmyadmin, poxy, sendmail 
 
 The usual gang of supporting tools include: make, gzip, tar, bzip2, nano. vi(m), hexedit, cpio, awk, sed, flex, m4, patch, diff, wget, links, etc...
 
 Security tools, firewalling and authentication tools are: fail2ban, iptables, openssh, openssl, openldap
 
 Even though the on-board ATI Rage graphic card performs disappointingly, x11 has also been included with x.org 7.2, fluxbox 1.0.0, firefox 2.0.0.12, xterm
 
 ## Origins
 
 This Distro is a Gentoo-based Distro - see [http://www.gentoo.org](#http://www.gentoo.org) for more info. For further documentation on how to maintain your  system after installation, go to [http://www.gentoo.org/doc/en/handbook/handbook-sparc.xml](#http://www.gentoo.org/doc/en/handbook/handbook-sparc.xml).

## Disclosure

Here is a disclosure of stuff that you can't do or stuff that won't run and stuff you shouldn't do on BigNoseLinux: 
* This Distro is meant to be installed on SPARC-based Sun boxen. It will not work on x86 or AMD machines - not even on Sun x86-based ones.  
* No Java. Yes! I mean __No__. I mean...bizarre. You can't. This may be a Sun box, and Sun may have invented Java, but Java does not work on a Sun box running Linux.
* No Flash. You may need Flash for some websites if you choose to use the X-Desktop, but sorry, __c'est impossible__!
* Dual booting: Don't try sharing this OS with another one on the same drive - the BigNoseLinux installation will obliterate all existing data on your drive. Anyway, why would you want to dual-boot once you have the wonderful BigNoseLinux installed? 

Here are some work-arounds for dealing with proprietory stuff: 
* You can view PDF files through the XPDF application
* VLC (VideoLan) can play AVI files, MPEG-4 files, XVid, DivX, and many more formats. 
* Audacity can play your MP3 files in X-Windows, and mpg123 can do it from the command line. 
* You can view and edit Word files with AbiWord in X-Windows, and you can view Word files from the command line with Antiword.

# Installation

There are 3 ways in which you can install BigNoseLinux on a Sun 5/10 box:

* Keyboard / Monitor method
* Headless Network method
* Serial connection method 

## Quick Installation - Keyboard / Monitor method 

This quick installation guide will walk you through the Keyboard / Monitor route. As you probably know, Sun machines are quite different to x86-based machines,so the booting process is also different.

### Hardware overview 

For starters, you need a Sun keyboard (type 5 or type 6) and a compatiblle monitor. A generic monitor with 15-pin VGA will be fine on Ultra 5's, and most Ultra 10's come with a PGX32 graphics card, which supports the same generic monitor. If you don't have a 15-pin VGA output on your Ultra 10, get either a [VGA cable adaptor](#http://www.networktechinc.com/cgi-bin/keemux/13w3m-15hdf.html) or a PGX32 graphics card, or get a Sun monitor, or consider one of the other installation methods.

### Booting up

Download the ISO image from the Downloads section, burn it to a CD-R type of CD. Note that the original CD drives that come with Ultra5/10's do not recognize rewritable CD's.

Now boot your beloved Sun Ultra5 or Ultra 10 box up with the CD as follows: Soon after the first text appears on the screen, enter the OpenProm environment by hitting the Stop+A (L1+A on some Sun keyboards) key-combination. The prompt will change to ```ok```. If you are already at a ```boot:``` prompt, type ```halt``` to get the ```ok``` prompt. You are now in the OpenProm environment where all sorts of things can be configured on your box, such as writing programs in FORTH. But this is for another day. To boot from the CD, type: 

```ok boot cdrom```

The machine will power down and then up again and you will eventually be greeted with a pretty message with various options that you can explore through the Help pages at the ```boot:``` prompt. But we digress again. At the ```boot:``` prompt, type the following:

```boot: bignose```

 This will boot the live CD. Once the booting process has gone through its girations and come to a standstill, it is time to start the installation. You should now be in a terminal with a ```livecd #``` prompt. Execute the command:

```livecd # bignose``` 

- and follow the steps in the installation wizard. If your hardware is as expected, you should have a fully functioning BigNoseLinux on you Ultra5/10 machine in under 30 minutes.

## Installation over a Serial Link 

If you do not have a Sun type 5 or 6 keyboard or a compatible monitor, or do not fancy doing a blind install with just a keyboard and no monitor or can't get your mitts on a 13W3M-15HDF adapter, you should consider doing the installation over a serial link between your Sun Ultra 5/10 box and another working computer. The nice thing about a Sun computer is that it listens on the serial port /dev/ttyS0 when no monitor and keyboard are connected and allows last-resort interaction when no other access methods are available. 

### Hardware overview

Here is what you need:
* Another working computer that has a serial port. Here we assume that it is another Linux box.
* The program minicom should be installed. Ensure that you are a member of the dialout group (for which you need root access to add yourself to this group)  
* A null-model serial cable. Your 'other' computer probably is an X86-based machine with a 9-pin, female serial D-connector port (DB9-F), but your Ultra 5/10 has a 25-pin male D-connector (DB25-M). Buy a serial cable [DB9F to DB25M Null modem cable](# href="http://www.cabling4less.co.uk/index.php?action=search&searchTerm=DB9&go=Go) for very cheap.
* Know which serial port you are connecting on the host computer. What is mostly marked up as COM1 on an X86-based machine is /dev/ttyS0 in Linux-speak. i.e. COM2 is /dev/ttyS1 etc..

### Plug your serial cable in

The 25-pin male end of the serial cable goes into the 25-pin port on the Ultra 5/10 next to the 15-pin VGA output. This is /dev/ttyS0 on your Ultra 5/10. The 9-pin female end of the cable goes into the serial port of your other computerand you are set to go.

### Set up minicom on your host machine

You need the following serial configuration to connect to a Ultra 5/10: 9600 baud, no parity, 8 bits, 1 stop bit, Hardware flow control, initialisation string: ```~^M~```. Save yourself the configuration work and simply paste the following into the a file named ~/.minicom.sun:

```bash
pu port             /dev/ttyS0
pu baudrate         9600
pu minit            ~^M~
```

### Power up your Sun box

Now run minicom on your host machine, power the Ultra 5/10 up and wait for the serial console to come alive:

```$ minicom sun```

You may see all sorts of interesting stuff on your minicom session - your Ultra 5/10 may even be rebooting to its previously installed operating system (not to worry - we are about to remedy this :-). What is important here that is that you are seeing stuff coming on your serial link that looks legible. If not, check your connection, change /dev/ttyS0 to /dev/ttyS1 in your config, make sure that the Ultra 5/10 is powered on, etc.

## Boot from the CD-Rom 

It is unlikely that your Sun box will boot to a CD-rom, so you need to get it to do so as a once-of. Send a break signal from minicom with the following series of key strokes: Ctrl-A, Z, F. This will bring you to the ```ok``` prompt, regardless of what is happening on the Sun box. To boot from the CDROM, type at the ```ok``` prompt and hit Enter:

```ok boot cdrom ```

The Ultra 5/10 will now reboot into SILO (similar to LILO in X86 architectures, which preceeded GRUB). Even while you reboot, you can still see everything that the machine does over the serial terminal: 

```
Rebooting with command: boot cdrom
Boot device: /pci@1f,0/pci@1,1/ide@3/cdrom@2,0:f  File and args:
SILO Version 1.4.13

             ___
     _______/   \         ____  ____
    /   _   \___/_____   /    \/ __/__  ___________
   /  _|_|_ /   /  _  \ /       /  _  \/  ____/ __ \
  /  |_____| \ (  |_|  )   /   (  |_|  )___  \  ___/_
 /__________ /__\__   /___/\___/\_____/______/\_____/
                /____/  ___
                   ____/   \
                  /    \___/ ____  ___ _____  ____
                 /     |___|/    \/   |  \  \/  /
                /          |   |  \   |   \    /
               /___________|___|__/______/  /\  \
                 Gerr'it while it's Hot /__/  \__\

BigNose Linux Release 2009.03  -   http://bignoselinux.org

Type `help' to view the Help menu.

boot:
```

### Start the Installation 

You are now at the ```boot``` prompt. Load the installation environment at the boot prompt:

```bash
boot: bignose
```

This step takes a short while to complete. You are eventually presented with this:

```
------------------------------------------------------------------------------
Welcome to the BigNose Linux Installation CD!
------------------------------------------------------------------------------
This CD installs BigNose Linux on your Sun Ultra5/10 computer.  It also serves
as a minimal LiveCD to help you recover your system.  The BigNose Linux distro
is primarily intended to quickly create a  Webserver using the classical LAMP-
stack (Linux, Apache, MySQL and PHP).

More info is available here: http://bignoselinux.org

BigNose Installation:
---------------------
To start the installation, execute the command:
  # bignose

Security:
---------
The root password on this system has been auto-scrambled for security  but the
ssh daemon has already been started. If you want to work remotely, execute:
  # passwd
  # ifconfig eth0
The latter gives you the IP address of this box. Remotely ssh to this box:
  # ssh root@<IP Address of this box>

A Gentoo-based Distro - see http://www.gentoo.org
---------------------------------------------
View documentation on how to maintain your system after installation, execute:
  # links file:///mnt/cdrom/docs/handbook/html/index.html```

livecd root #
```

You now have a proper Linux-session over a serial link. Except the the speed (we are only on 9600 bits per second after all), this behaves just like a normal terminal session over SSH. If the serial link is too slow for you, follow the instructions in the message shown above and SSH to the SUN box from the host machine over the LAN.  

Begin the installation at the ```livecd root #``` prompt: 

```livecd root # bignose```

# Problem Resolution

##  Lockfile for Minicom

You get an error message on your dial-out computer when you try to run minicom as a non-root user: 

```Cannot create lockfile. Sorry.```

Check the group ownership of /var/lock and /dev/ttyS0, e.g

```# ls -al /var/lock
drwxrwxr-x  3 root <strong>uucp</strong>  96 2009-01-18 23:18 .
# ls -al /dev/ttyS0
crw-rw---- 1 root <strong>uucp</strong> 4, 64 2009-01-18 23:16 /dev/ttyS0 
```

Add yourself to the ```uucp``` group, as well as to the ```dialout``` group on your dial-out computer

```# usermod -a -G uucp,dialout [my_login]```

## Minicom does not display anything when the cable is connected

Your host machine probably does not have a COM1 port, but may have a COM2 port. Try changing ttyS0 to ttyS1 in the file ```~/.minicom.sun``` and restart minicom. Check what serial ports you have onyour dial-out computer with the command:

```
# ls /dev/ttyS*
/dev/ttyS0    /dev/ttyS1
```

In this example both serial ports are available, so try the next suggestions:
* You may have picked the wrong serial port on your host machine that has 2 serial ports.
* You may also have serial ports disabled on your x86-based host machine. Check its BIOS.
* Did you use a NULL-modem cable or an RS232 cable? They look the same, but are wired differently and an RS232 cable will not work.

## Memory Address not Aligned 

You boot up from the CDROM and then start the BigNoseLinux installation, but get the error: 

```Memory Address not Aligned```

You are unseremoniously returned to the ```ok``` prompt. The error probably looks like this:

```
Rebooting with command: boot cdrom
Boot device: /pci@1f,0/pci@1,1/ide@3/cdrom@2,0:f  File and args:
SILO Version 1.4.13
\
             ___
     _______/   \         ____  ____
    /   _   \___/_____   /    \/ __/__  ___________
   /  _|_|_ /   /  _  \ /       /  _  \/  ____/ __ \
  /  |_____| \ (  |_|  )   /   (  |_|  )___  \  ___/_
 /__________ /__\__   /___/\___/\_____/______/\_____/
                /____/  ___
                   ____/   \
                  /    \___/ ____  ___ _____  ____
                 /     |___|/    \/   |  \  \/  /
                /          |   |  \   |   \    /
               /___________|___|__/______/  /\  \
                 Gerr'it while it's Hot /__/  \__\

BigNose Linux Release 2008.10  -   http://bignoselinux.org

Type `help' to view the Help menu.

boot: bignose
Allocated 8 Megs of memory at 0x40000000 for kernel
Loaded kernel version 2.6.24
 Loading initial ramdisk (1717076 bytes at 0x2FC02000 phys, 0x40C00000 virt)...
Memory Address not Aligned.
ok
```

### Fix Attempt 1: 

First, try to change the boot order in OpenProm so that the CD is boots first:

```
ok setenv boot-device cdrom disk net
boot-device =         cdrom disk net
ok
```

There is no compelling reason for this fix, but it was suggested on other Linux-on-SPARC forums and seemed to work, and is easiest to do. This is also a fix for when the computer only recognizes the hard disk as /dev/hdb, instead of /dev/hda. 

Don't forget to change the boot order back to disk, cdrom-order when you have completed the Linux installation:

```
ok setenv boot-device disk cdrom net
boot-device =         disk cdrom net
ok
```

### Fix Attempt 2 

Failing the previous step, disconnect the floppy drive and try booting from the CDROM again. 

If this worked, then is was because the floppy drive's memory range conflicted with that of the RAM disk.

### Fix Attempt 3 

If you have a hard disk attached that has Solaris installed, then this last trick may work (it worked on my Ultra 10). Quite wierd actually - here's what you need to do: 

* Remove the Solaris disk from the bus (i.e. disconnect the IDE cables, don't just move it to the secondary IDE port)
* Replace it with a nice shiny new IDE hard disk
* If you have managed to all this without cycling the power, cycle the power now, because OpenProm still thinks that there is a Solaris disk attached 
* Reboot and boot up from the CDROM

If this worked, then:

* Install BigNoseLinux
* Optionally re-attach the Solaris hard disk to the IDE bus on the secondary port.
* Some folk say it has 'something to do with Solaris being installed' on the machine (well, clearly!) but there is no explanation for this one... 
