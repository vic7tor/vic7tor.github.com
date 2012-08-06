---
layout: post
title: "嵌入式方面的一些问题"
description: ""
category: 
tags: []
---
{% include JB/setup %}
1.jlink
今天用普通用户运行JLinkExe报，无法连接。然后用root行。udev也配好了，组什么的也是。后来发现是udev问题，见udev那篇文章。

2.中断发生时的LR寄存器
当调试裸机程序时，因为程序问题发生了数据或指令中断，一般可以通过LR判断出程序出错的大致位置。

但是，比方说，发生了数据中断，而你单步过这个发生错误指令。则会跳到未定义指令的中断。Jlink对中断处理得不怎么好吧。

