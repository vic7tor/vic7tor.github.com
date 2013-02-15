---
layout: post
title: "Android SystemServer Debug"
description: ""
category: 
tags: []y
---
{% include JB/setup %}
调试见gdb attach那篇文章。

调试后总结，关于虚拟的那些设备见OnFirstRef函数的。同时，这些设备是没被使能，所以创建了也没有用。

所以，应该根据加速度计在HAL中模拟一个屏幕旋转所需的设备。


