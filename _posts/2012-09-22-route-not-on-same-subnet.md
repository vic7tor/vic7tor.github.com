---
layout: post
title: "网关不在同一子网"
description: ""
category: 
tags: []
---
{% include JB/setup %}
在渣渣校园网上时分配到的ip是172.19.55.59，128的掩码，但网关在172.19.55.254。以前好像搜网关不在同一网段没搜到什么的东西。然后今天搜英文的，有一个subnet这个词。一搜中文的有了结果。

当直接设置网关时报No Such Process.如下则没有这个问题

    route add -host 172.19.55.254 netmask 0.0.0.0 dev eth0 建立直接到172.19.55.254的连接 
    route add default gw 172.19.55.254 netmask 0.0.0.0 dev eth0 添加网关
