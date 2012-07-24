---
layout: post
title: "systemtap UNKNOWN symbol in module"
description: ""
category: 
tags: []
---
{% include JB/setup %}
今天在使用systemTap查看系统中tty_driver时，在insmod阶段报找不到tty_drivers这个符号。觉得奇怪，原来查看init_task是可以的啊。先看了下，`<linux/sched.h>`与`<linux/tty_driver.h>`中init_task与tty_drivers都是extern的。然后,readelf -s查看了下两个模块，结构都是一样的啊。因为当时是make ARCH=arm tags生成的ctags。只有arm的init_task定义，这个符号是EXPORT_SYMBOL的，当时没什么在意，并且认为EXPORT_SYMBOL了的会在/proc/kallsyms中会出现。但是后来发现EXPORT_SYMBOL的并不在/proc/kallsyms中出现。总的来讲，是tty_drivers没有EXPORT_SYMBOL。但是nm vmlinux文件时，这两个符号都存在，systemTap也是把它弄成未定义符号，让linux内核来解决这个符号问题。因为tty_drivers是在嵌入c代码中使用的，所以，是因为这个吧。
