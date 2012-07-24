---
layout: post
title: "pseudo terminal"
description: ""
category: 
tags: []
---
{% include JB/setup %}
wikipedia上面的词条pseudo terminal。一共有两种pseudo terminal。一种是BSD PTYS一种是UNIX98 PTYS。BSD的是那种从设备为`/dev/tty[p-za-e][0-9a-f]`，主设备为`/dev/pty[p-za-e][0-9a-f]`。UNIX98是主设备为/dev/ptmx，从设备为/dev/pts/N那种。/dev/ptmx是"pseudo terminal master multiplexer"，当它被打开时，一个从节点/dev/pts/N会出现（devpts这种文件系统）。试试cat /dev/ptmx，你会发现，在/dev/pts下，会有一个新的slave出现。
pty驱动注册时，注册了两个tty_driver。名字分别为: pts与ptm。他们都设置了TTY_DRIVER_DYNAMIC_DEV。所以如果不调用tty_register_device。都不会通过udev生成设备节点。但是呢，master又另外注册了一个字符驱动。devpts又挂载在了/dev/pts。所以，他们都没有使用tty_register_device与udev联合来生成设备节点。
注意下ptmx_open，先devpts_new_index，然后tty_init_dev，再然后tty_add_file，再然后devpts_pty_new（在devpts中生成设备节点。）就OK了。

tty_init_dev里面有戏，initialize_tty_struct值得看下，它在tty_struct里面设置了些什么重要的东西。tty_driver_install_tty中`ret = driver->ops->install(driver, tty);`driver是master，因为这是master的字符设备打开的处理函数，tty是这次打开产生的master，不是slave的。然后在调用的install（pty_unix98_install）函数中，生成了从设备的tty_struct但是没有调用tty_init_dev而是自己做了一些初始化。
