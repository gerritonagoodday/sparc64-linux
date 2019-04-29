--------------------
Video issues on boot
--------------------

You should not need any of these parameters when installing on a standard SUN
Ultra5/10 machine. However, if you have video problems at boot time, try:

  * Set the resolution and refresh rate in OpenBootProm at the `ok' prompt 
    Hit Stop-A or L1-A depending on your keyboard, Ctrl-] Ctrl-L over serial
    To view the current settings, type:
        ok printenv output-device
    It will probably just return `screen'. To set it, execute the following:
        ok setenv output-device screen:r1024x768x60
    This will set the framebuffer to a resolution of 1024x768 @ 60Hz refresh
    rate. Note that the refresh rate doesn't always carry over into the Linux
    framebuffer (but the resolution seems to). Return to the `boot:' prompt:
        ok go  (hit Return twice)

  * Specify the resolution and mode at the `boot:' prompt 
        boot: bignose video=atyfb:1024x768@60
    This will boot your system with the ATI Mach64 framebuffer in a 
    resolution of 1024x768 at 60Hz refresh rate.

  * Disable the framebuffer if you don't want any video at all:
    For ATI framebuffers        boot: bignose video=atyfb:off
    For SBUS framebuffers       boot: bignose video=sbus:off  

  * To use an unsupported framebuffer, choose it by framebuffer name, e.g.
    For Matrox framebuffers     boot: bignose video=matroxfb:1024x768@60

Type `help' to view Help menu.

