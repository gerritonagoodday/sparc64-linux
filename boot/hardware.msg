--------------------------------------
Hardware diagnostics and configuration
--------------------------------------
This distro is built for Sun Ultra5/10 computers with an ATI 3D Rage graphics
card and a Happy Meal network interface card on the motherboard and a minimum
4.5 GB hard drive on the primary IDE interface.  As it is based on the Gentoo
meta-distro you should be able to make most compatible hardware work.

To diagnose and resolve some hardware issues in the OpenProm environment (at
the `ok' prompt - hit Stop-A or L1-A), try the following commands:
  * If you have more than one NIC and you run into any configuration issues:
      ok setenv local-mac_address? true
  * To automatically boot on power-up:
      ok printenv auto-boot?  (if false, do next steps)
      ok setenv auto-boot? true
      ok setenv boot-command boot
  * To always boot from the device disk/cdrom/net:
      ok setenv boot-device disk (or cdrom or net, use net option with care!)
  * Hardware diagnostic and configuration for Ultra5/10 computers:
      ok banner              Hardware overview
      ok show-devs           List the devices
      ok devalias            List the device aliases
      ok .speed              List CPU and bus speeds
      ok pcia-probe-list     Controls probe order of PCI A-bus
      ok pcib-probe-list     Controls probe order of PCI B-bus
      ok test [device]       Selt-test the device, e.g. test net
      ok watch-net           Monitor network connection

See the following for more details about OpenProm
http://www.gentoo.org/doc/en/gentoo-sparc-obpreference.xml

Type `help' to view the Help menu.

