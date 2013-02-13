---
layout: post
title: "linux input user programming"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.数据获得
`<linux/input.h>`:

    struct input_event {
        struct timeval time;
        __u16 type;
        __u16 code;
        __s32 value;
    };

读/dev/input/eventX就行，读得的数据就是上面那样的结构体。

type见`<linux/input.h>`下面定义的Event types。

code也见头文件中定义的。

#2.信息接口

1./proc/bus/input

2.IOCTL

    EVIOCGNAME - get device name
    还有其它的，需要时再弄吧。

