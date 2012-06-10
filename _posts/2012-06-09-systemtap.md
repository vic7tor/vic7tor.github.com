---
layout: post
title: "systemtap"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.安装
archlinux下要重新编译内核。使用abs吧，配置好后重新编译。wiki上有说明。其它发行版有debug版的内核。
menuconfig
    General setup->Kprobes kprobe与架构相关，有的架构还没有实现
只需打开kprobe就行了，systemtap是kprobe的封装。
#2.vim高亮
systemtap源代码目录中有个vim目录。
#3.stapdev组
把用户添加到stapdev组，这个用户就能使用stap运行systemTap脚本。
#4.运行
    stap -e 'begin {print("hello")}'
    stap begin.stp
    stap -l 'kernel.function(\*)' 显示所有匹配项。
#5.systemTap脚本
probe的定位，使用了debug info中的信息来确定像kernel.function("vfs_read")在内核中的具体位置。
有着awk一般的格式：
    probe event {statements}
SystemTap支持每个probe有多个event，它们使用","分隔，它们中任何一个event发生时，handler都会执行。
每个probe都有一个statement块，使用{}标记。statement块有着c语言一样的语法。
SystemTap支持函数。
    function function_name(arguments) {statements}
    probe event {function_name(arguments)}
同步event:
syscall._system_call_
vfs._file_operation_
kernel.function("_function_")
kernel.trace("_tracepoint_")
module("_module_").function("_function_")
以上都可以加.return代表函数返回
异步evnet:
begin
end
timer.ms() 还有us ns hz jiffies

不打算写完了，参考SystemTap Language Reference吧。

#6.内置函数
    execname()	进程名
    pid()	pid
还有的参考SystemTap Beginners Guide
#7.Basic SystemTap Handler Constructs
这一节内容来自SystemTap Beginners Guide
##Variables
变量可以自由的在handlers中使用。选择一个名字，然后对它赋值或在表达式中使用它。SystemTap会依据它的赋值自动确定它的类型。声明全局变量使用_global_语句。
##Target Variables
probe evnet映射到源代码中实际的位置。kernel.function("function")和kernel.statement("statement")允许使用_target variables_访问源代码中相应位置变量的值。你可以使用-L选项列出那个probe point可用的target variable。
    stap -L 'kernel.function("vfs_read")'
SystemTap track Target Variables的类型信息，可以使用"->"查看一个结构体的成员。
对于是指针的target variables，其指向的是integer或者string的话，这里有一些函数访问内核空间的数据。对于用户空间的，(accessing user-space Taget variables"。这些函数参考SystemTap Beginners Guide这一章节的内容吧。
###Pretty Printing Target Variables
$$vars $$loacls $$parms $$return都代表一个字符串。
###Typecasting
In most cases SystemTap can determine a variables's type form the debug information.
###Checking Target Variable Availablility
@defined用来测试一个target variable是否可用。不同的内核版本，target variable可能存在，可能不存在。
##Command-Line Arguments
$整数与@字符串
commandlineargs.stp:
    probe kernel.function(@1) { }
    probe kernel.function(@1).return { }
stap commandlineargs.stp kernel function
#Associative Arrays
An associative arrya is a collection of unique keys, each key in the array has a value associated with it.
    array_name\[index_expression\]()
#Array Operations

#Tapsets

#probe alias
对于这个例子，alias定义会在probe a之前运行。
    probe a = kernel.function("vfs_read") {
    	printf("alias definetion\n")
    	printf("%s", $$parms)
    }

    probe a {
    	printf("a\n")
    	printf("%s", $$parms)
    	exit()
    }
#关于对内核数据的一些访问

function call_printk() %{
	printk("this use printk\n");
	printk(KERN_INFO "init_task:%p\n", &init_task);
	printk("init_task.parent %p\n", init_task.parent);
	printk("init_task.children.next %p\n", init_task.children.next); 
%}

probe begin {
	call_printk()
	exit()
}

embed c在函数中定义。那个例子调用了printk，使用dmesg可以看到这些消息。为什么呢？
对于%{ %}包含的代码，会直接扩展为c代码。stap -v会显示出生成了一个c语言源文件，（_systemtap就是对kprobe的包装_,生成的c代码，就是一个kprobe模块），在c语言代码中可以看到。这个c语言代码中出现了#include "runtime.h"，runtime.h在/usr/share/systemtap/runtime/下，这个文件包含了内核的一些常用头文件，像linux/kernel.h，%{ %}中的c代码得已正常编译。
#Embedded C _functions_
    function <name>:<type>(<arg1>:<type>, ...) %{ <C_stmts> %}
1.使用kread()宏来dereference(读取数据吧)任何有可能是无效或危险指针。
2.访问输入输出变量使用THIS
    function add_one (val:long) %{
    	THIS->\__retvalue = THIS->val + 1;
    %}
THIS->\__retvalue代表返回值，THIS->val指向参数。

