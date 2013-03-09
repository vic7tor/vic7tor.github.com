---
layout: post
title: "logcat filter"
description: ""
category: 
tags: []
---
{% include JB/setup %}
接手到一个GPS HAL的编写。logcat时大量其他人加入的调试信息，搞得都看不出来为什么Android框架干嘛老重启。

然后研究了下logcat的过滤。

过滤掉之后，整个世界清静了，才看到是因为自己弄的那个HAL有空指针访问。

过滤有两个元素：tag和priority。

如果只关心priority而不关心tag下面格式就行了：

    logcat *:priority

如果要关系到tag，priority里有个`S    Silent`。

你要想屏蔽某个tag的话，下面的语句：

    logcat tag;S

你要想只显示某个tag的话，你要列出这个tag，同时，要屏蔽其它的tag才行，要不然还是会显示所有。

    logcat vold *:S
    logcat -s vold

两条命令都行。


