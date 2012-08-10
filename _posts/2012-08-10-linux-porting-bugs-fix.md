---
layout: post
title: "linux porting bugs fix"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#1.zImage死循环
arch/arm/boot/compressed/vmlinux是objcopy后就得到zImage。这个vmlinux与源代码根目录的vmlinux是不一样的，看下面这张图：

![zImage]({{ site.img_url }}/zimg.gif)

反汇编vmlinux计算出vmlinux相应函数在内存中的位置，在这些位置下断，或者，通过内存地址来计算当前执行到vmlinux的哪个阶段。

额，突然想到，不用上面那么麻烦。gdb可以加载那些不在固定地址加载的模块的符号。这个在ldd3中用讲。这条命令就是:`add-symbol-file`

    (gdb) help add-symbol-file
    Load symbols from FILE, assuming FILE has been dynamically loaded.
    Usage: add-symbol-file FILE ADDR [-s <SECT> <SECT_ADDR> -s <SECT> <SECT_ADDR> ...]
    ADDR is the starting address of the file's text.
    The optional arguments are section-name section-address pairs and
    should be specified if the data and bss segments are not contiguous
    with the text.  SECT is a section name to be loaded at SECT_ADDR.
