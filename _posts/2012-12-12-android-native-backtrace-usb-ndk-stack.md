---
layout: post
title: "android native backtrace usb ndk stack"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.ndk-stack的编译
在ndk源代码目录的：build/tools/build-ndk-stack.sh就可以编译出ndk-stack这个工具。

ndk源代码目录的docs/NDK-STACK.html有一份文档。

#2.使用

    adb logcat > /tmp/foo.txt
    $NDK/ndk-stack -sym $PROJECT_PATH/obj/local/armeabi -dump foo.txt

sym指向的目录下面就有那个库文件。在那个logcat backtrace中各个文件在不同的目录，切换下就行了。
