---
layout: post
title: "filesystem notify"
description: ""
category: 
tags: [inotify 系统调用]
---
{% include JB/setup %}
在linux里面一共有三种文件系统notify。Dnotify、Inotify、Filesystem wide access notification。

Dnotify已经挂了，Filesystem wide access notification这个太高级了，用不上。

所以就讲Inotify了。

一份文档：Documentation/filesystems/inotify.txt

#调用系统调用
不像open、read、write这些inotify没有提供可以直接调用的函数。但是，我弄inotify-tools的源代码来看发现了一个可以调用作何系统调用的函数syscall。

    #define _GNU_SOURCE         /* See feature_test_macros(7) */
    #include <unistd.h>
    #include <sys/syscall.h>   /* For SYS_xxx definitions */

    int syscall(int number, ...);

    static inline int inotify_add_watch (int fd, const char *name, uint32_t mask)
    {
        return syscall (__NR_inotify_add_watch, fd, name, mask);
    }

#inotify

##inotify_init

    int fd = inotify_init ();

##inotify_add_watch

    int wd = inotify_add_watch (fd, path, mask)

path你要监视文件的路径，mask是IN_xxx那些宏。

##inotify_rm_watch

    int ret = inotify_rm_watch (fd, wd);

##read

    size_t len = read (fd, buf, BUF_LEN);

依buf太小返回合适数量的inotify_event。ioctl FIONREAD fd会返回inotify_event的数量。

fd不是wd。

##inotify_event
定义在include/linux/inotify.h还有一些代表事件的宏定义。

    struct inotify_event {
        __s32           wd;             /* watch descriptor */
        __u32           mask;           /* watch mask */
        __u32           cookie;         /* cookie to synchronize two events */
        __u32           len;            /* length (including nulls) of name */
        char            name[0];        /* stub for possible name */
    };

##select poll
可以用select poll fd。

