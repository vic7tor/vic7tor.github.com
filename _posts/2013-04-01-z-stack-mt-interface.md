---
layout: post
title: "z stack MT interface"
description: ""
category: 
tags: []
---
{% include JB/setup %}
今天已经弄得可以启动协调器了，用抓包工具可以看到协调器的心跳了。

TI抓包工具的使用就是在下面选项卡里有个要设置的radio Configuration，设置要抓的频道。

TI里那个ZNP由于模块的只有一个串口，后面就改GenericApp，使用MT interface，其实那个ZNP用的也是MT接口。

怎么改这个GenericApp，就是定义MT_TASK、ZTOOL_P1这些宏。GenericApp里有启用MT_TASK的。
