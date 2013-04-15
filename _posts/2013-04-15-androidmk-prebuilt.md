---
layout: post
title: "Android.mk prebuilt"
description: ""
category: 
tags: []
---
{% include JB/setup %}
长下面这个样子：

    #LOCAL_PATH := $(call my-dir)
    include $(CLEAR_VARS)

    LOCAL_SRC_FILES := openssl/server.pem
    LOCAL_MODULE := server.pem
    LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/../etc/
    LOCAL_MODULE_CLASS := FAKE
    LOCAL_MODULE_TAGS := optional
    include $(BUILD_PREBUILT)

一个Android.mk里只能一次LOCAL_PATH := $(call my-dir)，否则当前目录会变成build/core

LOCAL_MODULE_PATH指向文件安装的地方了

TARGET_OUT_SHARED_LIBRARIES在build/core/envsetup.mk文件中定义。

TARGET_OUT_ETC是system/etc
