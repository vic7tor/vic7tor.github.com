---
layout: post
title: "embed linux problem"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.g_mass_storage
一次g_mass_storage.file=/dev/mtdblock3。报打不开这个文件，当时，是编译进内核的，busybox的mdev还没运行，所以还没有设备结点。所以就打不开。

