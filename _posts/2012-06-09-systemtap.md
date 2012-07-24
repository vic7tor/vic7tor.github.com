---
layout: post
title: "systemtap"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#0.man pages
man pages有更详细的信息
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

    stap -e 'probe begin {print("hello")}'
    stap begin.stp
    stap -l 'kernel.function(*)' 显示所有匹配项。(这一句已经不行了，要用：stap -l 'kernel.function("*")'才行了。

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

SystemTap track Target Variables的类型信息，可以使用`"->"`查看一个结构体的成员。
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
    `array_name[index_expression]()`
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
    `function <name>:<type>(<arg1>:<type>, ...) %{ <C_stmts> %}`
0.对于函数定义括号是需要的
1.使用kread()宏来dereference(读取数据吧)任何有可能是无效或危险指针。
2.访问输入输出变量使用THIS

    function add_one (val:long) %{
    	THIS->\__retvalue = THIS->val + 1;
    %}

`THIS->\__retvalue`代表返回值，`THIS->val`指向参数。

    function access_task_struct (pid:long) %{
    	struct task_struct *head;
    	struct task_struct *cur;
    	int i;
    	head = &init_task;
    	printk("search pid:%lld\n", THIS->pid);
    	cur = head;
    	do {
    		if (cur->pid == THIS->pid) {
    			printk("pid %d: name %s\n", cur->pid, cur->comm);
    			break;
    		}
    		cur = next_task(cur);
    	} while (cur != head);
    %}
    probe begin {
    	access_task_struct($1)
    	exit()
    }

3.想要包含c的头文件

    %{
    #include \<linux/tty_driver.h\>
    %}

#debug
stap -p NUM 会中断在systemTap的处理相应阶段。
-p NUM     stop after pass NUM 1-5, instead of 5
                 (parse, elaborate, translate, compile, run)
会显示转换的c代码

#problem
运行stap时说，Checking "/lib/modules/3.3.8-1-ARCH/build/.config" failed with error: No such file or directory。在archlinux上就是linux-headers-3.3.8-1-x86_64.pkg.tar.xz这个包没有安装。
#小技巧
##1.引用target变量时，将指针转换为string使用kernel_string函数
probe kernel.function("pty_write@drivers/tty/pty.c:113") {
        printf("%s:call pty_write\n", execname());
        printf("\t %d data:%s\n", $c, kernel_string($buf));
}
##2.systemTap有引用内核源文件出现的任何符号（全局的）的能力
1.函数
`stap -L 'kernel.function("*")'`会列出内核中所有的函数。像file_operations这样的结构初始化时使用的那些函数。像上一个例子中pty_write是static const struct tty_operations pty_unix98_ops;中的那个。
2.任意变量
就是下面那个例子，自己的systemTap是1.7版的，也不知道现在多少版本号了。那个@var的方试报错。还有好像systemTap做了一下大的变化。就下面这个例子前面下的那个文档里根本没有说，就是那个SystemTap_Beginners_Guide，似乎要再看下才行了，现在好像比以前多了很多功能。刚才在官网看到了，systemTap1.8出来了，这个guide也根据1.8的变化做了些改动。在lwn.net上看到SystemTap1.8是在6月17发布的，@var的确是1.8新增的。1.8在学校下了才能用得到了。。

    probe kernel.function("vfs_read") {
        printf("current files_stat max_file:%d\n",
                @var("files_stat@fs/file_table.c")->max_file);
        exit();
    }

#fuction::*
这个man pages里没有，只有到SystemTap的官网去看了。
比方说今天用到的fuction::print_backtrace()--显示调用堆栈。
那个exit函数 execname都在`function::*`之中
#module
`stap -l 'module("*")`是没有反应的`stap -l 'module("usbcore").function("*")'`才会有反应，不指定模块是不行的。

下面程序查看了以模块形式加载的usbcore模块中的usb_bus_notify的调用堆栈。

    probe module("usbcore").function("usb_bus_notify") {
    	print_backtrace();
    	exit();
    }


