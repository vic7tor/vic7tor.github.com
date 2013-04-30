---
layout: post
title: "linux内核原子上下文"
description: ""
category: 
tags: []
---
{% include JB/setup %}
最近又准备着一场面试，扫荡着内核的这些基础设施。

究竟什么是内核的原子上下文，今天在研究softirq的实现时想明白了这一问题。

do_softirq执行softirq的处理函数。

有这么一句话，softirq运行在原子上下文，然后我就搜索do_softirq在哪引用。一个是invoke_irq，它有可能直接运行do_softirq，或者在一个叫ksoftirqd的内核线程中运行，内核线程里能是原子上下文么？这个和用户进程差不多的样子吧。

后面看到了do_softirq里调用的local_irq_save，这下明白了什么叫原子上下文。local_irq_save禁止了所有的中断，如果休眠的话，这中断就一直禁止了。

原子上下文指定就是中断被禁止这样的一种状态，中断禁止了还休眠，那么系统就死锁了。

