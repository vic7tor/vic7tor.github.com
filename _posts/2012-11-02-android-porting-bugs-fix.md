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
网上说换jdk7就行了。编译的是android ics。jdk7不行，原来自己下的jdk是6u25的，报这个错误。然后，下了jdk6u37然后就行了。这个与JDK无关，在网上说是一个IDE的弄的，不是JAVA标准里面的东西，所以，应该就可以干掉了。看了下源代码，是`@Nullable String uri`这样，只是一个IDE里的，就想起了Netbeans里的那样的修饰符，干掉了就行了。

#3.webcore有个头文件找不到
搜了下，在android源代码里没有那个文件，删除了。

#4.mmm的使用
有时候出错了，全部重新编译很蛋疼。用mmm编译指定模块就OK了。关于mmm编译的怎么清除，那个CleanSpec.mk显示了要清除的东西。现在不知道怎么调用这个文件。手工执行这里面指示的命令就行了吧。

