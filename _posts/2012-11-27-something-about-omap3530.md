---
layout: post
title: "something about omap3530"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#gpmc
omap3530中管理CS0-CS7的是GPMC。在linux内核的mach-omap2/gpmc.c为管理这个模块的代码。

gpmc.c:

    gpmc_cs_request(int cs, unsigned long size, unsigned long *base)
    最后一个参数是一个输出参数保存这个cs控制的基址

开了cs6后dm9000就能工作了

#gptimer
见mach-omap2/timer-gp.c

是哪些函数自己看了

弄了这个后，那块板屏幕就亮了

#gpio keys
omap3530的gpio能开中断
