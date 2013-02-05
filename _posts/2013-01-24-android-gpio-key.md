---
layout: post
title: "android gpio key"
description: ""
category: 
tags: []
---
{% include JB/setup %}
linux内核用gpio_keys_button来描述，其code成员就是/system/usr/keylayout下的那些文件描述的。

include/linux/input.h文件包含的KEY_xx定义就可以用在code成员的设置。

Jelly Bean中KEY_HOMEPAGE(172)才能回到主界面，KEY_HOME(102)没有这个作用。

key 114   VOLUME_DOWN	声音减
key 115   VOLUME_UP	声音加
key 116   POWER		手机中常见的那个上面那个键
