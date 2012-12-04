---
layout: post
title: "gcc arm stack frame"
description: ""
category: 
tags: []
---
{% include JB/setup %}
在网上弄了个别人为tiny210移植的u-boot但是，到我这块板上运行就报那个raise 8出错。并且不断重启。

这个问题当然要解决，好歹也玩过u-boot的。

在源码中找不到对raise函数的调用，郁闷，后面用objdump -d u-boot看下反汇编的。发现就是那个`__divsi3`这个的函数最终调用到了这个raise错误。除0时报这个错的。

源代码中对除法操作的引用有限吧。但是，不想这样盲目的找。后来就想到了linux内核的backtrace。

刚开始在u-boot的源代码中没有找到这样的函数。然后，看u-boot的反汇编代码，c函数的开头是这样的：

    23e0e11c <main_loop>:
    23e0e11c:       e92d40f8        push    {r3, r4, r5, r6, r7, lr}

push就是`stmfd sp!,`。括号里的寄存器就是会放入到堆栈中的寄存器。只保存个lr怎么backtrace上一个lr啊。后面看了下linux内核中的C函数开头：

    c05294f8 <start_kernel>:
    c05294f8:       e1a0c00d        mov     ip, sp
    c05294fc:       e92dd8f0        push    {r4, r5, r6, r7, fp, ip, lr, pc}
    c0529500:       e24cb004        sub     fp, ip, #4

这才有戏。

然后弄了个c程序用arm-none-linux-gnueabi-gcc编译，实验出是-mabi=aapcs-linux -mapcs中的-mapcs造成了这两个的差异。

优化选项也会对C函数的开头造成影响。

所以，在u-boot的编译选项加上这个，再弄个C语言函数也就能搞定了。

打算弄个宏能打开这个特性。

使用make -p找到CFLAGS赋值的地方。然后，用include/configs/xxx.h中使用宏控制是否开启-mapcs。


