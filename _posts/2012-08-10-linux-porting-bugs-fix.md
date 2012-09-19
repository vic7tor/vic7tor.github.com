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

找到原因了，这个问题曾经遇到过一次，新开一贴来讲这个问题。见`2012-08-11-gcc-optimize-hide-the-truth.md`。

#2.s3c2440_clk_init
这个函数是在early_init中执行的。这个时候，还没有调用map_init，访问那个寄存器地址后就会出错。

这个时候已经调用了map_init，不知道怎么出问题的。

log_buf是printk输出的地方，在还没有console的时候，可以通过gdb来查看这个。不过要先在gdb中`set print elements 0`才能显示出所有的内容。开了后，就可以使用`p log_buf`命令来显示printk的输出了。

#3.iotable_init错误
1.virtual要在VMALLOC区之外

2.virtual与物理地址写反了(郁闷，这种错也犯)

#4.时钟设置问题
1.`^`运算行不是求幂，而是按位异或。2的多少次幂就是1左移多少位。一个数乘以2的多少次幂就是这个数左移多少位。

2.m=MDIV+8; p=PDIV+2;s=SDIV。直接把MDIV、PDIV、SDIV代入公式，算的频率是错的。

#5.svc_preempt代码出错，与反汇编的不匹配
这个问题在我make clean然后再make后变得正常了。想想有两个原因。

1.真的问题，重新干净地编译下就正常了

2.tftp uImage下的是原来，新编译的没有拷过去。反汇编的是新的，gdb调试的时候用的新的符号，符号代表的地址，新的内核与旧的不一样。所以就会不同。

#6.get_irqnr_and_base未设置标志问题

    .macro  arch_irq_handler_default
    get_irqnr_preamble r6, lr
    1:      get_irqnr_and_base r0, r2, r6, lr
    movne   r1, sp
    @
    @ routine called with r0 = irq number, r1 = struct pt_regs *
    @
    adrne   lr, BSYM(1b)
    bne     asm_do_IRQ

在`get_irqnr_and_base`后几条指令都是ne结尾，当有中断时，get_irqnr_and_base要清除Z标志。

为什么前几个中断能处理呢？应该是前面几个中断发生时，cpu没有Z标志，cpu标志是共用的吧，当Z位被设置时，那个就不能被处理了。

#7.在__svc_irq中无法返回
看arch_irq_handler_default的代码，上面就有。有一句`adrne lr, BSYM(1b)`，lr就在get_irqnr_and_base那一句，asm_do_IRQ返回时，会跳到get_irqnr_and_base，再次，检测是否有中断。而这个写法：

        .macro get_irqnr_and_base, irqnr, irqstat, base, tmp
                ldr \irqnr, [\base, #INTOFFSET]
                tst \base, \base        @clear Z flag
        .endm

刚处理完，没有中断，此时也会INTOFFSET为0。但是还是设置了Z标志位。会让asm_do_IRQ运行，等asm_do_IRQ运行完，时钟中断也好了，然后就无限循环。

#8.s3c2440_uart_driver_init
注册uart_driver后，在错误处理代码前面没有加return，代码执行行到uart_unregister_driver又把uart_driver注销了，所以那个kgdboc找不到tty_driver...

#9.arch_idle panic
见port那一篇文章的system.h

#10. eint无穷中断
s3c2440_eint_demux取代了，原来的handle_level_irq，但是在s3c2440_eint_demux中没有mask、ack IRQ_EINT4_7所以就导至了无穷循环。

还有一个没有决定的东西是：对于level型中断，在没有清除控制器的之前。那个，中断会一直持续，对于s3c2440的EINTMASK又对EINTPEND没有作用。可能对上级EINT4_7有作用。尽管MASK掉了，但是，EINTPEND因为level型中断，仍然为1.这样又会再调用一次中断处理。

对level型的，在umask的时候又写一下pend寄存器吧。
