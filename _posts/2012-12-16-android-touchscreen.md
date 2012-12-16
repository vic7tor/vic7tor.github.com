---
layout: post
title: "android touchscreen"
description: ""
category: 
tags: []
---
{% include JB/setup %}

编译默认的android后，运行时，在logcat中搜EventHub会找到触屏的名字。然后，在/system/usr/idc，弄一份那个触屏名字的idc文件。

据说，在android中，power supply，电池系统没有弄好的话，触屏是不会起作用的。

把电池系统弄好后，触屏还是没有反应。后面有getevent看了下，根本没有反应。

然后切到官方给的那个系统，用getevent看了下，大把数据，而且，不是那个叫fa_ts_input的设备，而是一个叫ft5x0x_ts的设备在工作，看了下内核里面没有这个驱动。后面看了下数据手册，蛋疼的很，给的那个屏的手册没有i2c接口的，好像里面有个mcu，其在软件上实现了这些东西吧。试试网上那个驱动吧。看来，得自己弄了。

getevent是android提供的一个工具。用看查看linux内核input系统传上来的数据。

    getevent -l 会以友好的方式来显示数据。


