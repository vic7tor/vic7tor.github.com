---
layout: post
title: "android 3rd jar"
description: ""
category: 
tags: []
---
{% include JB/setup %}
Java与c++通信时用那个DataInputStream的readInt是用大端序的。后面在网上找了个叫guava的库，它有LittleEndianDataOutputStream这样的类。

下面方法在Android工程中导入第三方jar。建一个source floder试的时候一定要是source floder，然后把第三方jar放到这个目录，右击这个文件夹/Build Path/Add to build path。

如果运行时报报不到，Project/clean一下就OK。

