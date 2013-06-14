---
layout: post
title: "tty and job control"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#0 /dev/tty
看tty_open的实现，/dev/tty major为5TTYAUX_MAJOR。这货指向current->signal->tty。

current->signal->tty怎么设置的？

#1 tty_open

tty_register_driver分配字符设置，同时还有下面的。所以，所有的tty设备的打开函数都分指向tty_open

    cdev_init(&driver->cdev, &tty_fops);

在tty_open中设置current->signal->tty的条件：

        if (!noctty &&
            current->signal->leader &&
            !current->signal->tty &&
            tty->session == NULL)
                __proc_set_tty(current, tty);

noctty的赋值：

    1. noctty = filp->f_flags & O_NOCTTY; 这个是调用open时传进来的参数吧
    2. 设备结点编号4,0(/dev/tty0)的；设备节点编号5,1(/dev/console)的;PTY MASTER;这些都赋值为1。因为这三个都是虚拟出来的设备，都会指向一个真正的tty设备。

current->signal->leader：

    boolean value for session group leader

看这么个情况，只用户态一个为session group leader的进程打开了一个除了/dev/tty、/dev/console的终端设备之后，以后打开/dev/tty就有货了。

#android init
在android init的console_init_action之中，对androidboot.console指定的值进行了尝试。

    if (console[0]) {
        snprintf(tmp, sizeof(tmp), "/dev/%s", console);
        console_name = strdup(tmp);
    }

    fd = open(console_name, O_RDWR);
    if (fd >= 0)
        have_console = 1;
    close(fd);

console[0]是从androidboot.console来的。做为进程组，就算打开后再关闭，那个/dev/tty也就会有指向了。

console_name = strdup(tmp);为改变这个默认的指向。

have_console就在一个地方使用了，就是service_start，它后面的fork子进程中的操作：

        if (needs_console) {
            setsid();
            open_console();
        } else {
            zap_stdio();
        }

setsid - creates a session and sets the process group ID哈哈，就是这样。

open_console的console_name可能就是上面被替换的。

似乎needs_console这个变量来源于服务定义时的console语句，目前就console服务需要console。

在android里如果报androidboot.console没有的话就可以传内核参数androidboot.console=ttyXXX。

