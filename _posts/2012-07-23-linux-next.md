---
layout: post
title: "linux next"
description: ""
category: 
tags: []
---
{% include JB/setup %}
今天看lkml无意发现一个叫Stephen Rothwell声明linux-next的一些什么问题。在网上找了下资料。
linux-next的目的就是：当前linux代码有很多子树，当窗口期打开时，把这些子树合并在一起的话会出现很多问题。然后，linux-next出现了。它的维护者每天都拉取各个子树的代码，并把它们合并在一起，然后，把合并出现的问题报告出画。
linux-next与正常的内核源代码树相比多了一个名为Next的目录。下面的Trees文件内容为各个子树的地址。
从Next目录下的merge.log可以发现：
先执行git checkout master。然后git reset --hard stable（stable可以在gitweb的下面的heads里看到。其内容origin tree的内容是一样的。）这个命令的意思似乎是把index与当前工作目录指向stable。然后，就与Trees里面的树开始合并。产生这一天的linux-next。

