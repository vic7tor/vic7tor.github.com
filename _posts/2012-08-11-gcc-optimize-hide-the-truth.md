---
layout: post
title: "gcc优化隐藏的真相"
description: ""
category: 
tags: []
---
{% include JB/setup %}

又遇到一个从表像上看非常不科学的问题。arch/arm/boot/compressed/misc.c编译的代码反汇编后，一个b指令老是跳到自己这一行。然后，putstr这个函数居然没有出现在反汇编的列表中。看起来非常不科学啊。怎么会这样，gcc有问题么？

然后，make V=1取得编译misc.c的代码，一执行，再反汇编看，的确还是这样。然后，gcc -E看了下预处理的文件。putstr函数还在啊。最后，直接gcc -c 这个预处理文件。putstr函数出现了，一个putc的代码，最后一句老是b到自己。这怎么回事，回头看预处理完的那个文件发现putc是这样子：

{% highlight c %}

    static void putc(int ch)
    {
     while (!(((0x50000000 + 0x4000 * 0) + 0x10) & (1 << 2)))
      ;
    *(unsigned int *)((0x50000000 + 0x4000 * 0) + 0x23) = ch;
}

{% highlight %}

while语句那个表达式，是那样的，忘记用ioread这样的函数了。while语句这个表达值为1，是个死循环。

这个函数不会返回了，经过gcc一优化，putstr这个函数就没意义了。最后，就有了，那么奇怪的表现。

记得以前有一次也是逻辑表达式出了问题(最后求得的值是一个常量)，最后，编译的代码也非常奇怪。

这次偶然的，直接编译那个预处理后的c文件(内核编译的命令带有优化参数，gcc -E时，他们没有起作用)，让我关掉了gcc的优化，使这个问题浮现出来了。

