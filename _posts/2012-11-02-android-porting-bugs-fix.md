---
layout: post
title: "Android Porting Bugs Fix"
description: ""
category: android
tags: [android]
---
{% include JB/setup %}

#1.卡在target Dex: framework
主要原因是内存不足。在archlinux中，swap默认是没有开的。然后swapon /dev/sdax。然后就过了这里。或者/etc/fstab:

    /dev/sdxx swap swap defaults 0 0

#2.找不到符号

    sdk/chimpchat/src/com/android/chimpchat/core/IChimpDevice.java:184: cannot find symbol
    symbol  : class Nullable
    location: interface com.android.chimpchat.core.IChimpDevice
        void broadcastIntent(@Nullable String uri, @Nullable String action,
                              ^
网上说换jdk7就行了。编译的是android ics。

