---
layout: post
title: "dump_stack"
description: ""
category: 
tags: []
---
{% include JB/setup %}
显示内核的调用堆栈在某些情况下还是很有用处的，比方想研究，我这个某个驱动里的，某个ops里的函数是被谁调用的。自己写驱动的话，用这个函数，比用stap好些。
内核配置：

    kernel hacking -> kenrel debugging
    kernel hacking -> Verbose kernel error message（好像这个配置没有了）

打开这两个之后你就能使用dump_stack了。
刚才用cscop找这个函数的时候，居然只显示有x86的。ctags显示有arm的。难道是原来使用make cscope的原因？
