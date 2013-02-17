---
layout: post
title: "linux user app sleep"
description: ""
category: 
tags: []
---
{% include JB/setup %}
不像内核态有大把休眠函数，用户态的有几个：sleep、usleep、nanosleep。

在Android中用usleep挂掉，SIGBUS这样的信号。

所以就用nanosleep了，填充struct timespec为需要休眠的时间就OK了。

