---
layout: post
title: "systemtap"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.安装
archlinux下要重新编译内核。使用abs吧，配置好后重新编译。wiki上有说明。其它发行版有debug版的内核。
menuconfig
    General setup->Kprobes kprobe与架构相关，有的架构还没有实现
只需打开kprobe就行了，systemtap是kprobe的封装。
#2.vim高亮
systemtap源代码目录中有个vim目录。

