---
layout: post
title: "android opengl hardware"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#编译
要打开硬件opengl支持需要下面的东西。

    BOARD_EGL_CFG := device/samsung/tiny210/egl.cfg
    BOARD_USES_HGL := true
    BOARD_USES_OVERLAY := true
    USE_OPENGL_RENDERER := true 这个见后面

#不开源的二进制文件
把下面这些东西放到system/vendor

    vendor
    ├── bin
    │   └── pvrsrvinit
    └── lib
        ├── egl
        │   ├── libEGL_POWERVR_SGX540_120.so
        │   ├── libGLESv1_CM_POWERVR_SGX540_120.so
        │   └── libGLESv2_POWERVR_SGX540_120.so
        ├── hw
        │   └── gralloc.smdkv210.so 看下面，需要改名
        ├── libglslcompiler.so
        ├── libIMGegl.so
        ├── libpvr2d.so
        ├── libpvrANDROID_WSEGL.so
        ├── libPVRScopeServices.so
        ├── libsrv_init.so
        ├── libsrv_um.so
        └── libusc.so

#pvrsrvinit服务

    service pvrsrvinit /system/vendor/bin/pvrsrvinit
        class core
        user root
        group root
        oneshot

#/dev下相关模块权限
ueventd.mini210.rc

    /dev/pvrsrvkm             0666   system     system
    /dev/pmem_gpu1            0660   system     graphics

设备结点权限出问题会报：

    eglInitialize(0x1) failed (EGL_BAD_ALLOC)

#build.prop
报这个错：

    E/SurfaceFlinger( 1488): ro.sf.lcd_density must be defined as a build property

在build.prop里加：

    ro.sf.auto_lcd_density=yes
    ro.sf.lcd_density=120

原来触屏和鼠标点软件键盘输入时都会错位，设了这两个后就正常了。

#库里一个空指针

    I/DEBUG   ( 1486): backtrace:
    I/DEBUG   ( 1486):     #00  pc 00000000  <unknown>
    I/DEBUG   ( 1486):     #01  pc 00001390  /system/vendor/lib/libpvrANDROID_WSEGL.so (WSEGL_InitialiseDisplay+72)

用神器反汇编了下这个模块看了下，发现在这个调用附近有hw_get_module gralloc。然后想起了vendor/lib/hw/gralloc.smdkv210.so。在看那个友善有个文件后面才把board那个属性改成mini210原来是smdkv210。然后，直接把这个改成gralloc.mini210.so。OK，android启动起来了。

最后，友善那个启动log是这样的：

    D/libEGL  ( 1484): loaded /system/lib/egl/libGLES_android.so
    D/libEGL  ( 1484): loaded /vendor/lib/egl/libEGL_POWERVR_SGX540_120.so

#关于感觉画面粗糙
USE_OPENGL_RENDERER影响到的地方:

    base/core/jni/Android.mk:22:ifeq ($(USE_OPENGL_RENDERER),true)
    base/core/jni/Android.mk:23:	LOCAL_CFLAGS += -DUSE_OPENGL_RENDERER
    base/core/jni/Android.mk:221:ifeq ($(USE_OPENGL_RENDERER),true)

    base/libs/hwui/Android.mk:4:# Only build libhwui when USE_OPENGL_RENDERER is
    base/libs/hwui/Android.mk:6:ifeq ($(USE_OPENGL_RENDERER),true)
    base/libs/hwui/Android.mk:42:	LOCAL_CFLAGS += -DUSE_OPENGL_RENDERER -DGL_GLEXT_PROTOTYPES

USE_OPENGL_RENDERER启用后需要hwcomposer？

