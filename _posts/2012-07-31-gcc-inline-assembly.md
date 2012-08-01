---
layout: post
title: "gcc inline assembly"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#格式

    asm [volatile] (
        "汇编模板":
	"输出列表":
	"输入列表":
	"改变列表"
    );

#1.volatile
告诉gcc不要优化代码

#2.输出输入
这个顺序应该是`AT&T`风格，输入或者输入里有多个声明，使用逗号隔开。
有三种声明方法
##1.显式
`[别名] "修饰" (c符号)`
在汇编模板中使用`%[别名]`的方式来引用这个c符号。
##2.隐式
没有别名定义，引用时使用%num来引用，num为，这个声明在输出输入列表中的顺序，从0开始。
##3.不声明
这个只能引用寄存器%%r0这样的格式。

#3.改变列表
汇编代码中改变了哪些寄存器,比方说r0--"r0"，或者内存--"memory"

#4.例子

    asm ("fsinx %[angle],%[output]"
        : [output] "=f" (result)
        : [angle] "f" (angle));

    asm ("cmoveq %1,%2,%[result]"
        : [result] "=r"(result)
        : "r" (test), "r"(new), "[result]"(old));

##5.约束
经常用的就r代表寄存器。
其它看[这里](http://www.ethernut.de/en/documents/arm-inline-asm.html)

对约束的修饰
=	 Write-only operand, usually used for all output operands
+	 Read-write operand, must be listed as an output operand
&	 A register that should be used for output only
