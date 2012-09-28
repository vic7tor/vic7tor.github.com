---
layout: post
title: "busybox and rootfs"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#编译busybox
The BusyBox build process is similar to the Linux kernel build:

    make menuconfig     # This creates a file called ".config"
    make                # This creates the "busybox" executable
    make install        # or make CONFIG_PREFIX=/path/from/root install

busybox下的INSTALL说，How do I build a BusyBox-based system，估计下面的内容应该能在这找到答案。

#/etc/inittab
见源代码目录的examples目录下的inittab。当不存在inittab时，init会有默认的inittab也在这个inittab中描述了。

语法:

    Format for each entry: <id>:<runlevels>:<action>:<process>

`<id>`:在u-boot init中这个有非传统的意思，在u-boot中，用来指定`<process>`的运行的控制终端。如果留空，就被忽略。

`<runlevels>`:这个字段完全被忽略。

`<action>`:这个可以见你机子上的man inittab. Valid actions include: sysinit, respawn, askfirst, wait, once, restart, ctrlaltdel, and shutdown.

    sysinit:忽略`<runlevels>`的，比较先执行的。
    respawn:process终止时会重新运行。
    askfisrt:好像是busybox中特有的，与respawn行为一样，但是会显示一句"Please press Enter to activate this console."
    wait:当指定的runlevels进入时，process就会运行，init等待它结束。
    其它的一看就明白意思了。

#/etc/mdev.conf
见源代码目录的examples目录下的mdev_fat.conf。

mdev.conf中的那些数字不是设备号，是用户与组的ID。语法与mdev_fat.conf中说的一样。

mdev是udev的缩水版，只通过设备名来匹配。那个devicename_regex就来匹配内核通过NETLINK发来的消息。

语法：

    Syntax:
    [-]devicename_regex user:group mode [>|=path] [@|$|*cmd args...]
    
     =: move, >: move and create a symlink
     @|$|*: run $cmd on delete, @cmd on create, *cmd on both

#初始化脚本
那句::askfirst:-/bin/sh就可以有个终端也。因为，在内核的启动代码已经打开了/dev/console做为控制终端。

挂载文件系统

    mount -t proc nodev /proc
    mount -t sysfs nodev /sys
    mount -t tmpfs nodev /dev

挂上/sys与/dev后就可以执行mdev -s来在/dev生成设置结点了。不用echo到那个hotplug文件。

#问题
##1.
panic attemp to kill init那个。

在那个/etc/init.d/rcS中放了`echo "sss" > /dev/console`发现没有显示。没有运行到这里。然后在网上找，说是EABI问题。

arm-none-linux-gnueabi-objdump -p vmlinux

    private flags = 602: [APCS-32] [VFP float format] [software FP] [has entry point]

arm-none-linux-gnueabi-objdump -p bin/busybox

    private flags = 5000002: [Version5 EABI] [has entry point]

看来应该是这个问题了。在Kernel feature里面。

用这个选项编译内核后：arm-none-linux-gnueabi-objdump -p vmlinux

    private flags = 5000002: [Version5 EABI] [has entry point]

##2.显示Freeing init memory: 200K后无反应
uart的startup函数没有被执行。/etc/init.d/rcS中有echo到tty的语句。


