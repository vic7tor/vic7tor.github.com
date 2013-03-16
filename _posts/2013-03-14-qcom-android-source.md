---
layout: post
title: "qcom android source"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.内核编译
##1.kernel/AndroidKernel.mk
这个文件是用来编译内核的。

内核配置KERNEL_DEFCONFIG来自device/qcom/msm7627a/AndroidBoard.mk

生成配置文件的内核规则：

    $(KERNEL_CONFIG): $(KERNEL_OUT)
        $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- $(KERNEL_DEFCONFIG

