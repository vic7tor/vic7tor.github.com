---
layout: post
title: "applet not found"
description: ""
category: 
tags: [busybox]
---
{% include JB/setup %}

编译了下android的recovery，push到模拟器的名字是rec。执行下说applet not found。查了下源码，发现问题出在，busybox/libbb/appletlib.c:731:	full_write2_str(": applet not found\n");。recovery要busybox的一个静态库。把rec改成recovery就能正常运行了。
