---
layout: post
title: "ueventd which is the udev of android"
description: ""
category: 
tags: []
---
{% include JB/setup %}
android系统的udev不是那个vold而是ueventd。在网上有很多说vold是udev.

没有研究过ueventd但是，从行为上，ueventd才符合udev的行为。

ueventd的配置文件是：根目录下的ueventd.rc。其内容为：

    /dev/null                 0666   root       root
    /dev/zero                 0666   root       root
    /dev/full                 0666   root       root
    /dev/ptmx                 0666   root       root
    /dev/tty                  0666   root       root
    /dev/random               0666   root       root
    /dev/urandom              0666   root       root
    /dev/ashmem               0666   root       root
    /dev/binder               0666   root       root

ueventd.rc来控制设备结点的权限，组，用户。

而那个vold.fstab用来指示挂载信息。

uevent指定sysfs路径，当发生这些事件时，自动创建设备节点：


