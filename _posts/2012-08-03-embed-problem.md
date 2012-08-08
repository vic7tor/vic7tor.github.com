---
layout: post
title: "嵌入式方面的一些问题"
description: ""
category: 
tags: []
---
{% include JB/setup %}
1.jlink
今天用普通用户运行JLinkExe报，无法连接。然后用root行。udev也配好了，组什么的也是。后来发现是udev问题，见udev那篇文章。

2.中断发生时的LR寄存器
当调试裸机程序时，因为程序问题发生了数据或指令中断，一般可以通过LR判断出程序出错的大致位置。

但是，比方说，发生了数据中断，而你单步过这个发生错误指令。则会跳到未定义指令的中断。Jlink对中断处理得不怎么好吧。

应该好好看看那个，中断跳回的问题，发生数据中止中断时，lr会指向，发生中断这条指令地址+8

3.内存控制器BANKCON6设置问题
当BANKCON6/7的SCAN也就是那个Column address number设置错误时，会发生读取的东西全变为0的后果。没设置时是正常，一设置后再读内存就全0，再设置回来就又是正常的。


4.
`str	r3, [r0], #4`执行完后，再看r0的值已经就是当时的值加4了。

5.sp地址
当sp 为 0x3200FFFF这样的地址是gnu arm汇编中push指令执行时就会发现数据中断。。

但是sp为0x3200FFF0这样的地址就没有问题。

6.当在jlink中设置中断时，中断时，中断处的指令会执行完。PC会指向下一条指令。

7.一个代码执行很久的代码，ctrl+c时总中断在同一个地方。bt时，就会显示，他的父函数出了问题。

8.这是一个大问题，花了我10多个小时在这个问题上。

问题是这样的，一设MPLLCON，走过写寄存器的指令后，然后，内存数据就乱了，指令中第二个字节被加上了一个值。然后，大部分指令出了问题。

设clkdivn和pll，还有那个协处理器的那个总线模式。这三样东西的顺序如果乱来就会出问题。顺序乱了的话，导致产生时钟的电路供给sdram控制器的时钟出了问题，才导致内存数据读写出错。究竟是不是这样，我也不知道，S3C2440这款芯片在设计时，有没有这样的BUG我也没办法知道了。

最后以一个特定顺序设置这三个，就没有问题，与*sdram控制器的设置无关*。

这三个设置都要有，没有的话也会出问题。下面是正确顺序的代码。

        writel(0x00000005, &clk_power->clkdivn);
        writel(0, &clk_power->camdivn);

        /* to reduce PLL lock time, adjust the LOCKTIME register */
        writel(0xFFFFFF, &clk_power->locktime);


        /* configure UPLL */
        writel((U_M_MDIV << 12) + (U_M_PDIV << 4) + U_M_SDIV,
               &clk_power->upllcon);

        /* some delay between MPLL and UPLL */
        pll_delay(8000);

        /* configure MPLL */
        writel((M_MDIV << 12) + (M_PDIV << 4) + M_SDIV,
               &clk_power->mpllcon);

        /* some delay between MPLL and UPLL */
        pll_delay(4000);


        __asm__("mrc p15, 0, r0, c1, c0, 0\n"
                "orr r0, r0, #0xC0000000\n"
                "mcr p15, 0, r0, c1, c0, 0\n":::"r0");


后面又试了下，clkdivn与协处理器的设置在MPLLCON之前都可以。在MPLLCON之后不行。
不懂原来这么设为什么也不行。。

设置clkdivn后要不要个delay呢，然后才能做别的事。
