---
layout: post
title: "Android User System"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.initrd
initrd不管叫initrd.gz或者其它名字，它是一个gzip压缩的文件
##1.内核启动参数
让内核使用initrd u-boot的参数。

    setenv bootargs console=ttyS0,115200n8 root=/dev/ram rw initrd=0xa00000,0x8fffff initrd=inird所在内存地址,initrd大小

##2.initrd内容
弄initrd的主要原因是内核不支持sd做为根文件系统？(想想应该可以吧，sd卡做为一个块设备的。initrd的内容还是留着吧。这个还需要考虑，有没有sd卡的设备文件？内核有机制识别这个吗？就是怎么打开根文件系统的设备。

#2.挂SD卡的参数
直接这样子：

    root=/dev/mmcblk0p2 rw rootfstype=ext3 rootdelay=1

经测试，不需要ramfs，在3.0.8的内核，用上面参数，不做别的直接支持了。
