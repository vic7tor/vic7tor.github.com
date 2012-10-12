---
layout: post
title: "kernel hacking"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.MAINTAINERS
这个文件现在在linux-3.2.1里有7519行，描述了内核哪个部分代码是由谁管理的，邮件列表，版本控制仓库之类的。不过，不是所有的“部分”的代码都有仓库的，这些的话应该是用patch吧，他们的改动比较少。

如过要提交代码到某个部分，直接进这些部分的邮件列表应该会比较直接。这个在kernel-hacking那篇DocBook中的11章是这么讲的。

看git仓库的记录应该可以查到这个文件如何被修改。

#2.CREDITS
这个文件描述了一些对linux有贡献的人的名字以一些描述。


