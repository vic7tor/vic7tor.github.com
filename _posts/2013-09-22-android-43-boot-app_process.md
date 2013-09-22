---
layout: post
title: "Android 4.3 Boot app_process"
description: ""
category: 
tags: []
---
{% include JB/setup %}
想研究那个EventHub，然后找他是谁启动的，然后就这么顺着摸了下来。发现4.3与之前的好像不太一样，现在自己跟着源代码跑跑。

#app_process
这货的启动参数是：

	service zygote /system/bin/app_process -Xzygote /system/bin --zygote --start-system-server

frameworks/base/cmds/app_process/app_main.cpp这个文件下已经没有什么东西了。

参数--zygote和--start-system-server会让zygote和startSystemServer这个变量为真。

然后就这样：

    if (zygote) {
        runtime.start("com.android.internal.os.ZygoteInit",
                startSystemServer ? "start-system-server" : "");
    }

runtime是AndroidRuntime的一个子类继承了部分函数。

##AndroidRuntime
看它的start方法，感觉AndroidRuntime这个类是用来运行一个java类的。

AndroidRuntime被编译进libandroid_runtime，AndroidRuntime在./frameworks/base/core/jni/AndroidRuntime.cpp

所以libandroid_runtime里还有大量的jni接口。

在start方法中调用了startVm、startReg。startReg调用了register_android_util_Log这样的函数，这样的函数实现在对应的jni文件中注册几个JNI方法。

startVM很长，前面弄一些参数什么的最后调用了JNI_CreateJavaVM。这个方法实现在dalvik/vm/Jni.cpp之中。这个就不研究了吧。

现在有一个问题，整个系统运行过程中是不是只调用了一次AndroidRuntime的start函数？在JNI_CreateJavaVM调用时的上面有一句JavaVM每个进程都有，JNIEnv每个线程都有。

要解决这个问题还是看看fork之后干了什么。

##com.android.internal.os.ZygoteInit
./frameworks/base/core/java/com/android/internal/os/ZygoteInit.java

ZygoteInit的main：

    registerZygoteSocket();
    preload();
    gc();
    startSystemServer();
    runSelectLoop();

runSelectLoop()就是监听创建java的子进程的方法吧。

#system_server

startSystemServer();调用了Zygote.forkSystemServer();

./libcore/dalvik/src/main/java/dalvik/system/Zygote.java

##Zygote.forkSystemServer
调用了nativeForkSystemServer，定义在./dalvik/vm/native/dalvik_system_Zygote.cpp

这个只是fork一个进程，没有运行任何子进程。

##handleSystemServerProcess
要注意这个startSystemServer前面设置的参数，在这不会走WrapperInit.execApplication的分支，会走RuntimeInit.zygoteInit的流程。

zygoteInit的最后运行的zygoteInit就会运行startSystemServer开始设置的com.android.server.SystemServer这个类了。

##SystemServer.java
frameworks/base/services/java/com/android/server/SystemServer.java

它的main函数最后调用了一个init1这个是libandroid_server这个库中的不是libandroid_runtime。

frameworks/base/services/jni/com_android_server_SystemServer.cpp

然后，就走向了libsystem_server中的system_init函数。

system_init中定义的frameworks/base/cmds/system_server/library/system_init.cpp

system_init然后又转向了SystemServer的init2，这个流程可以参考下，怎么获得AndroidRuntim等等。

所以没有人执行system_server这个程序。

同时在system_init中都是使用AndroidRuntime* runtime = AndroidRuntime::getRuntime();来获得AndroidRuntime。这个要从fork的机制来获得。

不执行system_server的原因是不是因为调用exec系列函数后内存布局与父进程不一样了。

##fork
man 2 fork做了详尽的描述。

       Note the following further points:

       *  The child process is created with a single thread--the one that
          called fork().  The entire virtual address space of the parent is
          replicated in the child, including the states of mutexes,
          condition variables, and other pthreads objects; the use of
          pthread_atfork(3) may be helpful for dealing with problems that
          this can cause.

       *  The child inherits copies of the parent''s set of open file
          descriptors.  Each file descriptor in the child refers to the same
          open file description (see open(2)) as the corresponding file
          descriptor in the parent.  This means that the two descriptors
          share open file status flags, current file offset, and signal-
          driven I/O attributes (see the description of F_SETOWN and
          F_SETSIG in fcntl(2)).

两个的Virtual Address空间是一样的，用户态的也只有Virtaul Address。

还有大量的继承的或不继承的见man 2 fork吧，不描述了。

#java启动新的进程
runSelectLoop()

