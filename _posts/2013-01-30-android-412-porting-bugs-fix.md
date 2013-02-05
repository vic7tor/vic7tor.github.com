---
layout: post
title: "android 4.1.2 porting bugs fix"
description: ""
category: 
tags: []
---
{% include JB/setup %}

其实不算什么大问题，都是因为4.1.2与4.1.1的init.rc有差异所致，看来以后还是应该以system/core/rootdir/init.rc为准，然后init.machine.rc里做为辅助。或者是，复制这里的init.rc来修改。

这两个版的差异用眼睛看很难分辨，然后，我用diff看，把原来的init.rc少的东西补上去，系统正确启动了。

这次编译的是CM下弄来的代码，编译后，看起来和Android官方发布的没有什么区别，难道我repo init时选的jellybean分支是不对的，要有CM名字的分支才对？

这次init.rc差异造成了两个问题。

#1.本地代码注册JNI时找不到JAVA类
查了下Android.mk文件，编译没有问题。然后发现那个类是弄到了framework2.jar里面去的。用dexdump查看jar里的classes.dex发现有那类。后面看到一老外的文章，是BOOTCLASSPATH没有framework2.jar这个文件。4.1.2把framework.jar拆成两个了。然后加上后能正常注册了。

#2.创建dalvik-cache的问题
找了半天找不到原因。问题现象是这样的，preload class时能创建cache，但是到后面一点时间后就不行了。晚上看logcat的时候，发现是一个进程在创建cache，死了后会被再次运行，同时有新的pid。后面这个创建cache应该不是系统初始化那个弄的。然后脑子里一想，既然不是相同进程，可能是权限问题了。然后diff了下编译输出的那个init.rc（PRODUCT_COPY使用了4.1.1的init.rc）和system/core/rootdir/init.rc发现有权限设置

    mkdir /data/dalvik-cache 0771 system system
    chown system system /data/dalvik-cache
    chmod 0771 /data/dalvik-cache

改了后就OK

