---
layout: post
title: "tiny210 touchscreen"
description: ""
category: 
tags: []
---
{% include JB/setup %}

搞这玩意花了挺多时间的。先在网上找了个这个名字的驱动。改改后运行不了。发现报的点不对。

然后就是用IDA研究友善之臂那个模块了。刚开始还以为是个很复杂的算法，把这个算法用C语言表达出来后，再编译，不是那样的汇编代码。睡觉前想着这事，后来想到可能就是：从I2C那来的数据，的最大值并不是屏幕的分辨率，而是其它的值。然后，相对屏幕的值=屏幕宽(800) * 触屏读来值／ 触屏最大值。后面一验证，就是这值。

下面这程序：

    void calc(int with, int height, int x1, int y1)
    {
        int x, y;
        int ox = 1800;
        int oy = 1024;
        x = x1 * with / ox;
        y = y1 * height / 1024;
        printf("%d %d", x, y);
    }

用O2 march=armv7-a编译再反汇编：

    000083b4 <calc>:
        83b4:	e0000290 	mul	r0, r0, r2
        83b8:	e0020391 	mul	r2, r1, r3
        83bc:	e30b13c5 	movw	r1, #46021	; 0xb3c5
        83c0:	e34911a2 	movt	r1, #37282	; 0x91a2
        83c4:	e0c13091 	smull	r3, r1, r1, r0
        83c8:	e52d4004 	push	{r4}		; (str r4, [sp, #-4]!)
        83cc:	e2824fff 	add	r4, r2, #1020	; 0x3fc
        83d0:	e3520000 	cmp	r2, #0
        83d4:	e2844003 	add	r4, r4, #3
        83d8:	e1a0cfc0 	asr	ip, r0, #31
        83dc:	e0811000 	add	r1, r1, r0
        83e0:	b1a02004 	movlt	r2, r4
        83e4:	e3080490 	movw	r0, #33936	; 0x8490
        83e8:	e3400000 	movt	r0, #0
        83ec:	e06c1541 	rsb	r1, ip, r1, asr #10
        83f0:	e1a02542 	asr	r2, r2, #10
        83f4:	e8bd0010 	pop	{r4}
        83f8:	eaffffbf 	b	82fc <_init+0x44>

这样就把除以1800变成了smull一个常数，结果取其高位，然后再加，最后一个右移10位。最关键还是这个右移，表示了他是一个除法。

除以1024则是一个右移，还考虑到了小于0的情况。

#input驱动部分

1.input_set_abs_params要设置这个然后在，这个事件才会报到用户态去。

2.还有需要set_bit(ABS_MT_POSITION_Y, input_dev->absbit);

3.input_report_abs往上报数据。

然后一个触摸事件：

    /dev/input/event3: EV_ABS       ABS_MT_POSITION_X    000001d2                   
    /dev/input/event3: EV_ABS       ABS_MT_POSITION_Y    000000f0                   
    /dev/input/event3: EV_ABS       ABS_MT_TOUCH_MAJOR   000000c8                   
    /dev/input/event3: EV_ABS       ABS_MT_TRACKING_ID   00000000                   
    /dev/input/event3: EV_SYN       SYN_MT_REPORT        00000000                   
    /dev/input/event3: EV_SYN       SYN_REPORT           00000000                   
    /dev/input/event3: EV_ABS       ABS_MT_POSITION_X    000001d2                   
    /dev/input/event3: EV_ABS       ABS_MT_POSITION_Y    000000f0                   
    /dev/input/event3: EV_ABS       ABS_MT_TOUCH_MAJOR   000000c8                   
    /dev/input/event3: EV_ABS       ABS_MT_TRACKING_ID   00000000                   
    /dev/input/event3: EV_SYN       SYN_MT_REPORT        00000000                   
    /dev/input/event3: EV_SYN       SYN_REPORT           00000000                   
    /dev/input/event3: EV_SYN       SYN_MT_REPORT        00000000                   
    /dev/input/event3: EV_SYN       SYN_REPORT           00000000                   
    /dev/input/event3: EV_ABS       ABS_MT_POSITION_X    00000200                   
    /dev/input/event3: EV_ABS       ABS_MT_POSITION_Y    000000e9                   
    /dev/input/event3: EV_ABS       ABS_MT_TOUCH_MAJOR   000000c8                   
    /dev/input/event3: EV_ABS       ABS_MT_TRACKING_ID   00000000                   
    /dev/input/event3: EV_SYN       SYN_MT_REPORT        00000000                   
    /dev/input/event3: EV_SYN       SYN_REPORT           00000000                   
    /dev/input/event3: EV_ABS       ABS_MT_POSITION_X    00000200                   
    /dev/input/event3: EV_ABS       ABS_MT_POSITION_Y    000000e9                   
    /dev/input/event3: EV_ABS       ABS_MT_TOUCH_MAJOR   000000c8                   
    /dev/input/event3: EV_ABS       ABS_MT_TRACKING_ID   00000000                   
    /dev/input/event3: EV_SYN       SYN_MT_REPORT        00000000                   
    /dev/input/event3: EV_SYN       SYN_REPORT           00000000                   
    /dev/input/event3: EV_SYN       SYN_MT_REPORT        00000000                   
    /dev/input/event3: EV_SYN       SYN_REPORT           00000000

每个点后需要SYN_MT_REPORT、SYN_REPORT，最后还要加个SYN_MT_REPORT、SYN_REPORT才会起作用。

上面协议有点不正确，内核中文档Documentation/input/multi-touch-protocol.txt讲这部分。ABS_MT_TOUCH_MAJOR和ABS_MT_TRACKING_ID在内核中不需要。
