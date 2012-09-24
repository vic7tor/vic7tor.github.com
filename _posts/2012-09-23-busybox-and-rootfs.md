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

#初始化脚本
