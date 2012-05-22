---
layout: post
title: "early adb"
description: ""
category: 
tags: []
---
{% include JB/setup %}

做刷机测试，但是容易出现问题导致出错。导致系统无法开机，变砖，只有重刷才能解决。写了个小程序叫early-adbd来解决这个问题。
调用bootmenu时，原来的logwrapper.bin要改成你命名的bootmenu名字,比方你把原来的logwrapper改成logwrapper.orig那么原来的logwrapper.bin要改成logwrapper.orig.bin见bootmenu源代码。
