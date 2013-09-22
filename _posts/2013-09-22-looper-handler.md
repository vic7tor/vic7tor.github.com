---
layout: post
title: "looper handler"
description: ""
category: 
tags: []
---
{% include JB/setup %}
Android 里面Looper与Handler是个奇怪的东西，记得弄了几回了，弄了又忘了，网上的人也说不清，今天思考了下，总算弄明白了吧。

首先，Looper与Handler的使用是在同一进程的不同线程中，这样是有其原因的。

Looper所在的线程，是运行任务的线程。它运行的任务是Handler定义的任务。

调用Handler.sendMessage的线程是提交任务的线程。

Handler游走在这两个线程之间。

#1.Looper

使用Looper时就在一个需要干活的线程里:

    run() {
        Looper.prepare();
        ...
        Looper.loop();
    }

已经有HandlerThread来封装这个事情了。

##prepare
会创建一个Looper存在一个ThreadLocal之中。

在Looper的构造函数中会创建MessageQueue。

##loop

    public static void loop() {
        final Looper me = myLooper();
        final MessageQueue queue = me.mQueue;

        for (;;) {
            Message msg = queue.next(); // might block

            msg.target.dispatchMessage(msg);
        }
    }

queue.next()是阻塞的，用epoll来判断有没有事件，epoll的fd不知道是binder还是其它的什么。

Message的target就是一个Handler。

所以loop的行为就是，等待有消息来，来就就调用消息中Handler的dispatchMessage。需要强烈注意的是，这个dispatchMessage是运行在Looper所在的线程的。

这里也能指示为什么Looper与Handler的使用者为什么是在同一进程的不同线程，因为它们分配的内存什么的是共享的。

#Handler
调用Handler构造的时候一定需要一个Looper的实例的。

调用Handler.sendMessage这样，Handler定义的回调函数就在Looper所在的线程运行了。

这个回调函数有几种，dispatchMessage：

    public void dispatchMessage(Message msg) {
        if (msg.callback != null) {
            handleCallback(msg);
        } else {
            if (mCallback != null) {
                if (mCallback.handleMessage(msg)) {
                    return;
                }
            }
            handleMessage(msg);
        }
    }

1.Handle.sendMessage(msg)传入的msg本身有callback。

2.mCallback不会空，这个是一个接口。

3.Handler继承者实现的handleMessage()。


Looper与Handler也就这样了，了解了它们存在的目的就能很好理解它们了。

