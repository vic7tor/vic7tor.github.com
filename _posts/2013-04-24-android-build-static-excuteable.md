---
layout: post
title: "android build static excuteable"
description: ""
category: 
tags: []
---
{% include JB/setup %}

    LOCAL_STATIC_LIBRARIES := libc

    LOCAL_FORCE_STATIC_EXECUTABLE := true

    LOCAL_MODULE := bootrecovery

与动态链接不一样使用LOCAL_STATIC_LIBRARIES来引入库，abort这个函数就是在libc中。

