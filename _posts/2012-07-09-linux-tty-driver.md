---
layout: post
title: "linux tty driver"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#tty架构
就是那个从用户态通过cdev到达tty核心，再通过tty ldisc，再到tty_driver那个。。

#tty_driver
    struct tty_driver {
            int     magic;          /* magic number for this structure */
            struct kref kref;       /* Reference management */
            struct cdev cdev;
            struct module   *owner;
            const char      *driver_name;
            const char      *name;
            int     name_base;      /* offset of printed name */
            int     major;          /* major device number */
            int     minor_start;    /* start of minor device number */
            int     minor_num;      /* number of *possible* devices */
            int     num;            /* number of devices allocated */
            short   type;           /* type of tty driver */
            short   subtype;        /* subtype of tty driver */
            struct ktermios init_termios; /* Initial termios */
            int     flags;          /* tty driver flags */
            struct proc_dir_entry *proc_entry; /* /proc fs entry */
            struct tty_driver *other; /* only used for the PTY driver */
            /*
             * Pointer to the tty data structures
             */
            struct tty_struct **ttys;
            struct ktermios **termios;
            struct ktermios **termios_locked;
            void *driver_state;
    
            /*
             * Driver methods
             */
    
            const struct tty_operations *ops;
            struct list_head tty_drivers;
    };
major(可为空，见register_tty_driver与minor_start以及num与name在register_chrdev_region中使用。详见register_tty_driver。name与name_base还被用在了tty_register_device中。
在register_tty_driver中register_chrdev_region已经注册num数量个字符设备。如果说创建设备节点的话应该就可以使用了。在register_tty_device中没有做什么事情（产生了sysfs的入口，然后，通过udev产生设备节点？另开一篇关于udev的文章）
type与sub_type,sub_type信赖于type，就是一个type下有几种sub_type。
type:TTY_DRIVER_TYPE_SYSTEM(略了，以后补）。。
init_termios = tty_std_termios;这个一般的tty驱动就这样子了。
type、subtype、flags均定义在<linux/tty_driver.h>在这个文件最后可以找到。
flags是几个的与。
#tty_register_device
用systemTap试了下，tty_register_device((struct tty_driver *)0xffff880039da2c00, 20, NULL);，调用了这个函数，当然参数指针都是正确的。这个函数干的事就是调用device_create。在调用这个函数后，在/sys/class/tty/下生成了对应的ttyS20目录，然后，/dev下了有了ttyS20。就是这么个情况。

/dev/ttyN那些是这个驱动：drivers/tty/vt/vt.c
#tty_operations
