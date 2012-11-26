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

#5.-fpermissive
从这里开始使用官方源代码库里的android-4.0.3.然后遇到个问题.

    ‘indexOfKey’ was not declared in this scope, and no declarations were found by argument-dependent lookup at the point of instantiation [-fpermissive]

把出错文件所在的目录的Android.mk的CFLAGS加上-fpermissive就行了.出错的文件比较多把build/core/config.mk这一行加上:`HOST_GLOBAL_CPPFLAGS += $(COMMON_GLOBAL_CPPFLAGS) -fpermissive`。这个只能用在C++而且是用在HOST的程序编译时用到。

#6.setrlmit没有定义
dalvik/vm/native/dalvik_system_Zygote.cpp这个文件使用setrlimit但是没有包含sys/resource.h这个文件。报的时struct rlimit不兼容，setrlimit没有定义。

#7.selected processor does not support 'qadd16 ip,r0,r3'
1.在BoardConfig.mk中加TARGET_ARCH_VARIANT := armv5te-vfp

2.external/webrtc/src/common_audio/signal_processing_library/main/interface/spl_i
nl.h修改这个文件中相应地方，反汇编中也只是做单纯加法，没有用到处理器那些符号位。

#8.external/mesa3d/src/glsl/linker.cpp
网上说：

    Problem comes from host libstdc++. Since version 4.6 <cstdio> does not include <cstddef> anymore.

    Downgrade host package to libstdc++ 4.5 or add '#include <cstddef>' into linker.cpp

#9.原因同上

    external/gtest/include/gtest/internal/gtest-param-util.h
     #include <vector> 
    +#include <cstddef> 
     #include <gtest/internal/gtest-port.h> 

#10.Werror

    external/llvm/include/llvm/ADT/PointerUnion.h:56:10: error: enumeral mismatch in conditional expression: ‘llvm::PointerLikeTypeTraits<clang::QualifiedTemplateName*>::<anonymous enum>’ vs ‘llvm::PointerLikeTypeTraits<clang::DependentTemplateName*>::<anonymous enum>’ [-Werror=enum-compare]

Try to edit frameworks/compile/slang/Android.mk:

    -local_cflags_for_slang := -Wno-sign-promo -Wall -Wno-unused-parameter -Werror
    +local_cflags_for_slang := -Wno-sign-promo -Wall -Wno-unused-parameter
