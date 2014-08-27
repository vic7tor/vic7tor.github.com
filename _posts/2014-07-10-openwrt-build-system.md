---
layout: post
title: "openwrt build system"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.软件包下载
下载的脚本是：scripts/download.pl

include/download.mk引用

#2.Makefile
根目录的Makefile:

	89 world: prepare $(target/stamp-compile) $(package/stamp-cleanup) $(package/st    amp-compile) $(package/stamp-install) $(package/stamp-rootfs-prepare) $(targ    et/stamp-install) FORCE
	90         $(_SINGLE)$(SUBMAKE) -r package/index

	 88 prepare: .config $(tools/stamp-install) $(toolchain/stamp-install)

tools/stamp-install是在tools/Makefile中定义的：

	138 $(eval $(call stampfile,$(curdir),tools,install,,CONFIG_CCACHE CONFIG_powerp    c CONFIG_GCC_VERSION_4_5 CONFIG_GCC_USE_GRAPHITE CONFIG_TARGET_orion_generic    ))

参见include/subdir.mk中对stampfile的定义。

#3.其它程序编译
make的输出：

 make[2] toolchain/install
 make[3] -C toolchain/gdb prepare
 make[3] -C toolchain/gdb compile
 make[3] -C toolchain/gdb install

那些个程序编译是make -C进去的，不是在根目录的Makefile包含进去。

