---
layout: post
title: "new post"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.CONFIG_FB_S3C与CONFIG_S3C_FB
编译内核中的smdkv210时，报这样的错s5pv210_fb_gpio_setup_24bpp找不到。然后，在plat-s5p/include/plat/fb.h找到标题中的宏。

当第一个没有定义的时，第二个才能起作用，第二个起作用，编译才能通过。


