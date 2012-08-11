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

从开始，开启MMU后会跳到restart去。然后，在restart一个"Relocate ourselves past the end of the decompressed kernel."的注释下面，会把restart至`_edata`复制到"end of the decompressed kernel"。cache flush后，会重新跳到restart去执行。

然后，跳到新的restart加载符号后发现：

     874:       eafffffe        b       874 <decompress_kernel+0x44>

一直往自己这跳。。


objdump -d misc.o发现，这里面只有三个函数：`error`、`__div0`、`decompress_kernel`三个函数，根本没有putstr。对putstr的调用都会转为b 自己。非常不科学。

找到原因了，这个问题曾经遇到过一次，新开一贴来讲这个问题。[见此]({% post 2012-08-11-gcc-optimize-hide-the-truth.md %})。

#2.s3c2440_clk_init
这个函数是在early_init中执行的。这个时候，还没有调用map_init，访问那个寄存器地址后就会出错。

log_buf是printk输出的地方，在还没有console的时候，可以通过gdb来查看这个。不过要先在gdb中`set print elements 0`才能显示出所有的内容。开了后，就可以使用`p log_buf`命令来显示printk的输出了。
