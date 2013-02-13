---
layout: post
title: "debug android native code use gdb"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.基础方法

##1.在设备上运行gdbserver
在最近版的的android中gdbserver已经集成在里面了。

    gdbserver :5039 /system/bin/executable
    gdbserver :5039 --attach pid

那个端口是监听设备上的端口。

##2.使用adb重定向端口

    adb forward tcp:5039 tcp:5039

这条命令把pc机上的端口重定向到设备上去。

##3.运行arm-eabi-gdb

    arm-eabi-gdb system/bin/executable

##4.指定动态库符号搜索路径

    set solib-absolute-prefix /absolute-source-path/out/target/product/product-name/symbols
    set solib-search-path /absolute-source-path/out/target/product/product-name/symbols/system/lib

##5.在gdb上连接到remote

    target remote :5039

连接到本机的5039，被adb forward重定向到设备的5039端口。

gdb的shared命令载入符号。

#2.高级方法
##让设备可调试

1.setprop debug.db.uid
运行这条命令：

    adb shell setprop debug.db.uid 10000

修改/default.prop也行，不过要注意这个文件的权限，不然不认。

设置这个属性后，pid小于10000的程序挂掉后（应该是会显示那个backtrace信息那种)，整个系统就会暂停，后面的服务不会运行。但是，shell还能执行命令。

2.按gdbclient提示手动运行gdbserver

##gdbclient

对于第一次情况

    运行logcat中显示的那条命令。
    gdbclient app_process :5039 pid(视情况而定)
    . build/envsetup.sh后就有gdbclient这条令了。可能要lunch下才能找到符号。

对于第二种情况

    运行gdbclient有提示

在现在版本调用的那个GDB是64位的，所以要装64位的库。

