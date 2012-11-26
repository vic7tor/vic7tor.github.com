---
layout: post
title: "something about linux"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.ibus
语言栏：`ibus preferences->font and style->show language panel->when active`
还是上面的embed preedit text in application window那个输入提示窗口就会出来。
#2.改变tmpfs大小
cscope -Rbkq总是报空间不足。一看/tmp大小为500m。下面这个命令可以使/tmp处的tmps改变大小。
`sudo mount -o remount,size=5g /tmp`

#3.开机挂载swap分区
在/etc/fstab中

    /dev/sda11	swap	swap	defaults	0	0

#4.界面变成中文
LANGUAGE这个环境变量。这个比LANG优先级高。
