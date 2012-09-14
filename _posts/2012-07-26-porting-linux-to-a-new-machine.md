---
layout: post
title: "porting linux to a new machine"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.内核配置编译系统
##1.1 arch/arm/Kconfig
在这个文件中加入你的机器的定义。

    config ARCH_S3C2440
        bool "S3C2440 MACHINE"
	select CPU_ARM920T(来自arch/arm/mm/Kconfig)
    ...
    ...

    source "arch/arm/mach-s3c2440/Kconfig"

定义与这个机器相关的东西mach-s3c2440/Kconfig:

    if ARCH_S3C2440
    	menu xxxx
	...
	endmenu
    endif

###关于Kconfig的if..endif
假设你定义了`config ARCH_S3C2440`，使用if..endif语句，可以使用当使用menuconfig等工具配置内核时。可以动态的导入与这个机器相关的配置

    if ARCH_S3C2440
    	select HAVE_CLK

	config MY_CONFIG
	    bool
    endif

##1.2 arch/arm/Makefile
加入你机器的目录。
`machine-$(CONFIG_ARCH_S3C2440)          := s3c2440`

##1.3 arch/arm/tools/mach-type
? ARCH_XXX MACH_XXX

#2.内核编译必要的文件
配好上面的配置系统后就可以调用`make ARCH=arm uImage`开始编译。然后根据编译出错的信息来查找问题。

总结起来一个查找那些宏用来干什么的方法是：只建立文件，不定义宏。

##2.1 Makefile

    obj-y := irq.o timer.o
    obj-($CONFIG_MACH_MINI2440) += mach-mini2440.o

##2.2 include/mach/timex.h
内容为：

    #define CLOCK_TICK_RATE   123131

只建立文件不定义CLOCK_TICK_RATE时，编译的出错信息：

    include/linux/jiffies.h:257:31: warning: "CLOCK_TICK_RATE" is not defined [-Wundef]
然后在include/linux/jiffies.h：

    /* LATCH is used in the interval timer and ftape setup. */
    #define LATCH  ((CLOCK_TICK_RATE + HZ/2) / HZ)  /* For divider */

CLOCK_TICK_RATE表示时钟计数器的输入频率每秒多少次
LATCH表示时钟计数器的寄存器应该设的值
上面那个公式就相当于LATCH = (CLOCK_TICK_RATE/HZ + 1/2)
CLOCK_TICK_RATE是一秒钟多少次。每次时钟中断把HZ加1。LATCH就是HZ增加1，时钟计数器的输入振荡了多少下。

这个东西不知道还有什么用，由于输入定时器的时钟为PCLK而且还要被分频。LATCH是不能设为定时器的值的。CLOCK_TICK_RATE不知道还有没有别的意义。

##2.3 include/mach/vmalloc.h
内容为：

    #define VMALLOC_END       (0xe8000000UL)

只建立该头文件，不定义`VMALLOC_END`的错误信息为：

    include/linux/mm.h: In function ‘is_vmalloc_addr’:
    include/linux/mm.h:306:41: error: ‘VMALLOC_END’ undeclared (first use in this function)

查看is_vmalloc_addr这个函数可以确定VMALLOC_END的作用，当然，可以还有别的功能。

##2.4 include/mach/io.h
内容为：

    #define __io(a)         __typesafe_io(a)
    #define __mem_pci(a)    (a)

##2.5 include/mach/irqs.h
内容为：

    #define NR_IRQS 60
    还有代表一个中断的request_irq函数使用的宏
    为避免get_irqnr_preamble的Z标志位问题，可以使用第一个IRQ从不从0开始定义，因为这个IRQ编号类似数组索引(那个radix tree能不能从零开始，NR_IRQS就要是最大的IRQ编号加1(包括了开始处那些)。

##2.6 include/mach/entry-macro.S
    在这个文件中需要实现get_irqnr_preamble和get_irqnr_and_base和disable_fiq(entry-armv.S调用)、arch_ret_to_user(entry-common.S调用)

    .macro disable_fiq
    .endm

    .macro get_irqnr_preamble, base, tmp
    base 为irq控制器的基址，只传给后面调用的get_irqnr_and_base
        引用这个寄存器前面加\：ldr     \base, =VA_VIC0
    tmp 你可以使用的一个临时寄存器
    这个宏返回时还要清除Z位，见arch_irq_handler_default后面几条指令。
    关于arch_irq_handler_default还要处理一个问题。见后面arch_irq_handler_default代码。这个问题是，当asm_do_IRQ返回时，因为"adrne   lr, BSYM(1b)"会回到get_irqnr_preamble，再检测一下是否有中断。真有中断的话继续处理。因为get_irqnr_preamble写法失误，引起了一个bug。见bugs fix那篇文章。
    .endm

    .macro arch_ret_to_user, tmp1, tmp2
    .endm

    .macro get_irqnr_and_base, irqnr, irqstat, base, tmp
    irqnr 返回值
    irqstat 好像是个临时变量，用来读取irq的寄存器。
    base 传入的参数
    tmp 临时变量
    .endm

    irq_handler->arch_irq_handler_default->(get_irqnr_preamble,get_irqnr_and_base)

arch_irq_handler_default

    .macro  arch_irq_handler_default
    get_irqnr_preamble r6, lr
    1:      get_irqnr_and_base r0, r2, r6, lr
    movne   r1, sp
    @
    @ routine called with r0 = irq number, r1 = struct pt_regs *
    @
    adrne   lr, BSYM(1b)
    bne     asm_do_IRQ


##2.7 include/mach/system.h
这个文件需要实现arch_reset和arch_idle

在panic的消息发现了not imp这一句。然后cs f c panic。发现在这个system.h实现时arch_idle使用一句panic("not imp")实现的。

start_kernel - rest_init - cpu_idle - pm_idle(default_idle) - arch_idle

实现arch_idle:

    #include <asm/proc-fns.h>
    static void arch_idle(void)
    {
        cpu_do_idle();
    } 


##2.8 Makefile.boot
在生成vmlinux后，这个文件用于生成zImage。arch/arm/boot/Makefile需要这个文件。

    zreladdr-y   += 0x30008000

##2.9 include/mach/uncompress.h
与上个文件同样的作用。arch/arm/boot/compressed/misc.c
void arch_decomp_setup(void) 初始化等等
void putc(int ch) 输出一个字符
void flush(void) 刷新。。

为空的话:static inline void  arch_decomp_setup(void)


#3.机器初始化
##3.1MACHINE_START
这个宏定义在`asm/mach/arch.h`中，可以看到上面有个`for_each_machine_desc`的宏，这个宏使用的`__arch_info_begin`是在`vmlinux.lds`被赋值的：

    .init.arch.info : {
    __arch_info_begin = .;
    *(.arch.info.init)
    __arch_info_end = .;
    }

    #include <asm/mach-types.h> /* MACH_TYPE_MINI2440*/
    #include <asm/mach/arch.h> /* MACHINE_START MACHINE_END */
    MACHINE_START(MINI2440, "MINI2440")
        .init_irq	= xxx_init_irq,
	.map_io		= mini2440_map_io,
	.init_machine	= mini2440_init_machine,
	.timer		= &xx_timer,
    MACHINE_END

setup_machine_tags传入MACHINE_ID然后返回对应的machine_desc。
map_io、init_irq、timer、init_machine(按顺序被执行)，这些都通过MACHINE_START机制被调用，没有强制需要在什么文件中实现。

machine_desc中几个初始化成员执行顺序：

start_kernel:

    1.setup_arch-->paging_init-->devicemaps_init-->mdesc->map_io
    2.          -->mdesc->init_early
    3.init_IRQ-->machine_desc->init_irq()
    4.timer_init-->system_timer->init

vectors是在devicemaps_init中定义的，这里还映射了些别的东西。

##3.2 map_io
	
	#include <linux/page.h> /* __phys_to_pfn */
	#include <asm/mach/map.h> /* map_desc */
	#include <linux/kernel.h> /* ARRAY_SIZE */

	static struct map_desc s3c2440_map_desc[] __initdata = {
	{	
		.vritual	= S3C2440_VA_INT_CTRL,
		.pfn		= __phys_to_pfn(S3C2440_PA_INT_CTRL),
		.length		= SZ_4K,
		.type		= MT_DEVICE,
	},
	};

	iotable_init(s3c2440_map_desc, ARRAY_SIZE(s3c2440_map_desc));

##3.3 `init_irq`
###3.3.1 中断处理机制
代码会变动。基本还是一样。主要有三种数据结构参与进来。跟踪`asm_do_IRQ`你就会发现这些。

要禁止一个中断，看handle_xxx_irq的代码(irqd_irq_disabled) ，似乎只能使用irq_disable。irq_disable是没有导出的，能用的有enable_irq与disable_irq这对函数，irq_desc的depth就是供这两个函数使用，来确定enable的调用与disable的调用是否匹配。它们最终调用irq_enable、irq_disable，最终调用chip.irq_unmask、chip.irq_disable。需要实现。irq_desc.depth默认值是1。系统默认所有中断都是被禁止的，所以，要先enable_irq后才启用了中断。

enable_irq最终调用的irq_enable会有下面行为，如果irq_chip.irq_enable存在，就会调用irq_enbale。否则，会调用irq_unmask。irq_disable只会调用irq_chip.irq_disable

关于enable_irq与disable_irq还有一个问题。request_irq可能会调用irq_startup。这个要看irq_desc有没有设置过标志。

在request_irq调用的__setup_irq:

                if (irq_settings_can_autoenable(desc))
                        irq_startup(desc);
                else
                        /* Undo nested disables: */
                        desc->depth = 1;


1. `irq_desc`
这个是最基本的结构，有一个机制将`irq_desc`与irq号对应起来(`get_irqnr_base`)，得到irq号后使用`irq_to_desc`取得irq号对应的`irq_desc`。`irq_desc`是`early_irq_init`生成的。`irq_desc`指向`irq_chip`(`irq_data`中)和`irq_action`(`request_irq`函数使用那个)。
irq_desc在desc_set_defaults做一些初始化。irqnr存在`irq_desc->irq_data.irq`

2. `irq_chip`
`asm_do_IRQ`先取得得`irq_desc`后就调用`irq_desc->handle_irq`，_这个函数_使用了`irq_chip`的ack、mask、等等。然后，调用`irq_action`。

`irq_desc->handle_irq`是通过，`irq_set_chip_and_handler`设置的。在内核中可以设置的handler有:在他们的代码定义处有说明，或者跟踪这些函数，看它们如何进行。

    /*
     * Built-in IRQ handlers for various IRQ types,
     * callable via desc->handle_irq()
    */     
    extern void handle_level_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_fasteoi_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_edge_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_edge_eoi_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_simple_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_percpu_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_percpu_devid_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_bad_irq(unsigned int irq, struct irq_desc *desc);
    extern void handle_nested_irq(unsigned int irq);

### 3.3.2关于中断的level与edge
这些中断可能是level的(就是算edge在处理过程中mask掉也没关系):
	
	EINTx - 像按键这样的，键按下，中断会持续
	UARTx - S3C2440手册上说Generated whenever(无论何时) xxx就算是edge mask掉也没有关系吧

其它中断算edge

3. `irq_action`
就是设备驱动使用`request_irq`会注册一个`irq_action`。

### 3.3.3 `init_irq`
记得要set_irq_flags这个irq才能被request_irq申请。

	void xxx(struct irq_data *data)
	{
            data.irq irq号
	}

	struct irq_chip xxx_chip = {
	    .name = "xxx",
	    .irq_mask = xx, /* 使用INTMSK  */
	    .irq_unmask = xxx,
	    .irq_ack = xxxx, /*向SRCPND INTPND写1 */
	};
	
	irq_set_chip_and_handler(irqnr, &xxx_chip, handle_edge_irq);
	set_irq_flags(irqnr, IRQF_VALID);
	/* 对于sub int它们也需要一个chip来mask unmask(SUBINTMSK寄存器)和
			ack(SUBSRCPND) 视demux的实现情况，可能在这个chip
			的mask unmask ack处理INTMSK INTPND SRCPND等寄存器
			因为mask unmask ack是在系统提供的handle_edge_irq
			等函数中调用的*/
	void s3c_irq_demux_xx(unsigned int irq,struct irq_desc *desc)
	{
	    ..
	    generic_handle_irq(demuexd);
	    ..
	}

	irq_set_chained_handler(xxx, s3c_irq_demux_xx); /* 用于处理利用的中断
				实际调用__irq_set_handler	*/
##3.4 timer

    irqreturn_t s3c2440_timer_interrrupt(int irq, void *dev_id)
    {
        timer_tick();
	return IRQ_HANDLED;
    }

    struct irqaction s3c2440_timer_irq = {
        .name	= "S3C2440 TIMER TICK"
	.flags	= IRQF_DISABLED | IRQF_TIMER | IRQF_IRQPOLL, /*见定义的上方*/
	.handler = s3c2440_timer_interrupt,
    };

    void s3c2440_timer_init(void)
    {
        s3c2440_timer_setup();
	setup_irq(IRQ_TIMER4, &s3c2440_timer_irq);
    }

    struct sys_timer s3c2440_timer = {
        .init	= s3c2440_timer_init,
	.offset	= s3c2440_gettimeoffset,
	.resume	= s3c2440_time_setup,
    };

##3.5 init_machine

##3.6 init_early
在setup_arch的最后调用了init_early。setup_arch在(后面几个按顺序在start_kernel中调用)init_IRQ(`machine_desc->init_IRQ`)、time_init(`machine_desc->timer`)、console_init。
do_initcall是在后面后面创建一个内核线程才运行的。init_machine就在arch_initcall调用。

#4 clock
`<linux\clk.h>`定义了一些函数，但是没做其它任何实现，包括`struct clk`。想使用这套机制来实现机器时钟的初始化。预在init_early中做时钟初始化。

    struct clk_ops {
        void 
