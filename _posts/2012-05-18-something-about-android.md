---
layout: post
title: "Something about Android"
description: ""
category: android
tags: [android]
---
{% include JB/setup %}
#1.编译Native代码
    . build/envsetup.sh
    lunch
    mmm \*/\*/ - (你程序的代码)
#2.编译静态的可执行程序
在Android.mk加入下面代码:
    LOCAL_STATIC_LIBRARIES := libc
    LOCAL_FORCE_STATIC_EXECUTABLE := true
为什么会有*LOCAL_STATIC_LIBRARIES := libc*,因为我写的那个程序调用了*fork*。在android中，*fork*是在bionic的libc中实现的，因为，程序是静态链接，所以要使用*LOCAL_STATIC_LIBRARIES*声明要链接的静态库，否刚会出现链接错误。
#3.修改Android.mk后如何重新编译程序
在android的编译系统中，修改了Android.mk再使用mmm编译时，并不重新编译代码。而修改其源代码时，会重新编译。对于修改了Android.mk又要重新编译代码时，可以使用*touch*代码目录所有文件，这样，你懂的。
