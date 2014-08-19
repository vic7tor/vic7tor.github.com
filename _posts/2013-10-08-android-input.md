---
layout: post
title: "android input"
description: ""
category: 
tags: []
---
{% include JB/setup %}
https://source.android.com/devices/tech/input/index.html

来自这个网页对输入系统的描述：

EventHub从设备结点读入数据，然后InputReader解码输入事件，根据输入设备的class，转换为Android的输入事件。在这个过程中，会依据设备配置文件、键盘布局、还有一些映射文件。（adb shell su -- dumpsys window）似乎可以看到这些文件。

最后，InputReader发送这些输入事件给InputDispatcher。

这个网页的其它地方也给了这些配置文件所在的地方。


