---
layout: post
title: "jlink gdb download problem"
description: ""
category: 
tags: []
---
{% include JB/setup %}
以前那个匪夷所思的奇怪的使用gdb下载的问题终于得到了解决。原来问题表现是这样的，使用load指令后，每4字节的东西，全部会重复成相同的东西。后来看人家的GDB初始化脚本，经过测试是，BWSCON的问题。然后呢，那个SDRAM接口是16位的嘛，我把BWSCON BANK6的DW6设为16位的，这下每4字节重复两次了。要设成32才行了，难道这个是控制器与CPU连接的宽度，还是当使用SDRAM时，这个要设成32，而SRAM时，才需要设成相应的？*答案是，MINI2440使用两片SDRAM并在一起*为什么会重复呢？这个应该是S3C2440 SDRAM控制器的原因了。

为什么内存控制器的设置为影响到GDB的下载呢，那是因为，JLink这类的调试器，通过ARM提供的调试接口，那个扫描链，使用LDR这样的指令去读内存。

