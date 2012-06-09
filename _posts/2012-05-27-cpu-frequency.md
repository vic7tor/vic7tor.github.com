---
layout: post
title: "cpu frequency"
description: ""
category: 
tags: []
---
{% include JB/setup %}
无意间摸到笔记本键盘有点烫烫的，我靠，我这个有点老的笔记本还顶不顶得住这样的折腾。想想应该是cpu频率的问题。然后在网上找找，找到了cpufrequtils这个东西。内核驱动，acpi-cpufreq还有cpufreq_XXXX系列的。cpufreq-set调频率
/etc/conf.d/cpufreq和/etc/rc.d/cpufreq
#acpi不能自动启动
vi /etc/rc.d/cpufreq在最前面加入modprobe acpi-cpufreq
