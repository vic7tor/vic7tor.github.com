---
layout: post
title: "linux kernel in a nutshell 读书笔记"
description: ""
category: linux
tags: [linux]
---
{% include JB/setup %}

#第二章 构建和使用内核的要求
Documention/Changes构建和使用内核的最低软件版本

#第三章 内核源代码的获取
2.6.17
  ｜ ｜
  ｜ －－－--2.6.17.1
2.6.18-rc1      |
  |             |
2.6.18-rc2   2.6.17.2
  |
 ...
  |
2.6.18-rc5
  |
2.6.18

发布一个2.6.17的稳定内核之后，内核开发者们进行新特性的开发，并发行-rc版作为开发版内核，人们对这些特性进行测试。当所有人认为开发版已经足够稳定后，它就做为2.6.18版内核发布。新特性开发的同时，内核小组发布了包含漏洞补丁和安全更新的2.6.17.1版、2.6.17.2等等。
#第三章 配置和构建内核
make config make defconfig等配置内核
##部分构建内核
    make M=drivers/sub/serial
这条命令构建目录下的模块，但是不会影响到最终内核映像文件。最后执行make，让构建系统检查所有修改过的目标文件，并完成最终内核映像构建。
#第六章 内核升级
稳定版内核补丁应用于主内核版本。2.6.29.5补丁只能应用于2.6.29内核。
主内核补丁只能应用于上一个主内核补丁。
增量补丁将内核从一个特定版更新到下一个版本。
此前我们使用make mmenuconfig make config生成了可工作的配置。给内核打上补丁后，我们唯一需要做的就是根据新版内核添加的选项更新它。要做到这一点，应该使用make oldconfig make silentoldconfig方式。
________________________________________________________________________
#第七章 定制内核
当前系统内核配置 /proc/config.gz
##查找哪些模块是需要的
###示例：确定网络设备驱动
    ls /sys/class/net
    basename \`readlink /sys/class/net/eth0/device/driver/module\`
    find -type f -name Makefile | xargs grep 上条命令输出的模块名
###一个显示内核中所有加载模块的脚本
    \#! /bin/bash
    \#
    \# find_all_modules.sh
    for i in \`find /sys/ -name modalias -exec cat {} \;\`; do
    	modprobe --config /dev/null --show-depends $i;
    done | rev | cut -f 1 -d '/' | rev | sort -u
modalias文件包含相应信息。
##从零开始确定正确的模块
###pci
1.使用lspci查找该设备的PCI总线ID。输出条目的首部就是设备的PCI总线ID。
2./sys/bus/pci/devices/总线ID/{vendor,devices}
通过在 include/linux/pci_ids.h查找vendor的ID确定相应的宏名。
然后，该设备驱动程序会引用该宏名，搜索这个宏名就行。
###usb
通过对比插入和移除usb设备时lsusb命令的结果找到usb设备的制造商ID：产品ID。
搜索制造商ID和产品ID就能确定相应驱动程序了。
#第8章 内核配置秘笈
##磁盘
###USB存储设备
1.USB存储设备实际是通过USB接口通信的USB SCSI设备。因此，必须首先启用SCSI子系统。

    Device Drivers
	SCSI Device Support
		[*]SCSI Devices Support
2.同样，在SCSI系统中，为了使设备能够正常挂载，必须启用"SCSI disk support"。
###IDE磁盘
`lspci | grep IDE`
SCSI Devices Suppo2.同样，在SCSI系统中，为了使设备能够正常挂载，必须启用"SCSI disk support"。
###IDE磁盘
`lspci | grep IDE`
1.在内核中启用PCI支持。

    BUS options (PCI,PCMCIA,EISA,MCA,ISA)
	[*] PCI Support
2.启用IDE子系统和IDE支持

    Device Drivers
	[*] ATA/ATAPI/MFM/RLL support
	[*] Enhanced IDE/MFM RLL disk/cdrom/tape/floppy support
3.在ATA系统中，必须启用特定类型的IDE控制器支持才能使之正常工作。为了在你选错磁盘控制


