---
layout: post
title: "programming rw sysfs"
description: ""
category: 
tags: []
---
{% include JB/setup %}
写程序控制sysfs的leds来开关led。写sysf有点小要求。原来这样子写：

    #define LED_ON "150"
    char stron[] = LED_ON;
    write(fd, stron, sizeof(stron));

这样做失败。用strace看了下echo 150 > brightness。发现echo是write(1, "150\n", 4)这样做的，所以。。

    #define LED_ON "150\n"
    char stron[] = LED_ON;
    write(fd, stron, sizeof(stron) - 1);

