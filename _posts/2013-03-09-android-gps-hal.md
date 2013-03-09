---
layout: post
title: "android GPS HAL"
description: ""
category: 
tags: []
---
{% include JB/setup %}
从HAL执行的流程来解析。

#整体架构
在gps_qemu.c中说上层是android_location_GpsLocationProvider.cpp
##1.gps_device_t
这里面就有一个get_gps_interface返回一个GpsInterface的数据结构。

##2.GpsInterface
这个结构里面有start、stop Gps的方法。

重要的是init方法。这个函数会传入一个GpsCallbacks的参数。这个函数要调用GpsCallbacks提供的回调函数来创建一个线程。

在这个线程里面与Kernel GPS接口通信，当有数据时调用GpsCallbacks里的`gps_location_callback location_cb`回调函数上Android上层传入数据。

GpsCallbacks是上层传过来的。

因为与上层是交互是在另一个线程里实现的。所以当要start、stop这个工作线程时，qemu的那个实现是使用socket的。

#其它细节

