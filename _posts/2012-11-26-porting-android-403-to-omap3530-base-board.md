---
layout: post
title: "porting android 4.0.3 to omap3530 base board"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.netd无法启动
##1.内核

##2.init.rc
    android 4.0的init.rc与android2.3.4的不样

    platform/system/core/rootdir/init.rc
    android 4.0 platform目录改为system

#2.屏幕闪烁
    把framebuffer的console关了就行了。

#3.触屏


logcat有下面信息

    D/EventHub( 1117): No input device configuration file found for device 'ADS7846 Touchscreen'.
    I/EventHub( 1117): New device: id=1, fd=90, path='/dev/input/event2', name='ADS7846 Touchscreen', classes=0x4, configuration='', keyLayout='', keyCharacterMap='', builtinKeyboard=false
    E/EventHub( 1117): could not get driver version for /dev/input/mouse0, Not a typewriter
    I/InputReader( 1117):   Touch device 'ADS7846 Touchscreen' could not query the properties of its associated display 0.  The device will be inoperable until the display size becomes available.
    I/InputReader( 1117): Device added: id=1, name='ADS7846 Touchscreen', sources=0x00002002

vi drivers/input/touchscreen/ads7846.c改下这个设备的名字。然后，见http://source.android.com/tech/input/input-device-configuration-files.html。再把/system/usr/idc/DEVICE_NAME.idc改成那个名字就行了。


