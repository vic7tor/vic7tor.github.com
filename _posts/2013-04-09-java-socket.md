---
layout: post
title: "java socket"
description: ""
category: 
tags: []
---
{% include JB/setup %}
java socket比较简单直接上例子了。

这篇文章是TCP的。

#1.服务端

    ServerSocket serversocket;
    serversocket = new ServerSocket(端口);
    Socket socket = serversocket.accept();
    InputStream in = socket.getInputStream();

就这么简单，服务器端，bind，listen什么的都封装了。

后面说InputStream和OutputStream。

#2.客户端

    Socket socket = new Socket(IP, 端口);
    OutputStram out = socket.getOutputStream();

#3.InputStream和OutputStream

这三个类很相似

    read/write(int b); 写入一个字节，高24位扔掉。
    read/write(byte[] b); 把这个数组写进去。
    read/write(byte[] b, int off, int len); 把b[off]的len字节写进去。
    数组是按顺序的。

InputStream有个available函数返回有多少个字节可以读。OutputStream中有个flush函数。



