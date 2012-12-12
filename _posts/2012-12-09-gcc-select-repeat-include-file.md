---
layout: post
title: "gcc如何选择名字重复的头文件"
description: ""
category: 
tags: []
---
{% include JB/setup %}
arch/arm/Makefile中有下面一句

    plat-$(CONFIG_PLAT_S5P)         := s5p samsung

这样会导致两个plat的include都会包含进来。看一个的编译命令中指定头文件的路径。

	-I/home/victor/embed/linux/android/samsung/arch/arm/include 
	-Iarch/arm/include/generated
	-Iinclude  -include include/generated/autoconf.h -D__KERNEL__ -mlittle-endian 
	-Iarch/arm/mach-s5pv210/include 
	-Iarch/arm/plat-s5p/include 
	-Iarch/arm/plat-samsung/include

plat-s5p的在plat-samsung的前面。所以，当搜索一个文件时，两个目录都有时，会选择前面的。前面的没有才会选择后面的。

