---
layout: post
title: "android jelly bean porting"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1. /system/bin/vold找不到
init.rc中修改那mount 到system的语句

#2. 开机后没有shell
找到init.rc中的console服务，把那个disabled去掉。

#3. shell root权限
把service console那里的user shell改成user root

#4.

E/libEGL  ( 1474): eglGetDisplay:121 error 300c (EGL_BAD_PARAMETER)
E/libEGL  ( 1474): eglInitialize:137 error 3008 (EGL_BAD_DISPLAY)
E/libEGL  ( 1474): validate_display:245 error 3008 (EGL_BAD_DISPLAY)

在报错`eglGetDisplay:121 error 300c`中，121是代码行号。

    #define setError(_e, _r)        \
    egl_tls_t::setErrorEtc(__FUNCTION__, __LINE__, _e, _r)

eglGetDisplay那个错在此：

    EGLDisplay eglGetDisplay(EGLNativeDisplayType display)
    {
        clearError();

        uint32_t index = uint32_t(display);
        if (index >= NUM_DISPLAYS) {
            return setError(EGL_BAD_PARAMETER, EGL_NO_DISPLAY);
        }

        if (egl_init_drivers() == EGL_FALSE) {
            return setError(EGL_BAD_PARAMETER, EGL_NO_DISPLAY); 这一句是121行的
        }

        EGLDisplay dpy = egl_display_t::getFromNativeDisplay(display);
        return dpy;
}   

有上面代码，跟了跟，后面想到egl.cfg那个文件，一看如下：

    0 0 POWERVR_SGX540_120

改改如下

    0 0 android
    0 1 POWERVR_SGX540_120 /如果没有SGX支持，使用软件的opengl也会导致无法开机

egl.cfg由EGL/Loader.cpp载入。每一行什么意思，以后再搞定了。

#init.rc中创建/data中目录语句无法执行
init.rc中有一句会把/挂载为只读，修改那一句就行了。

#skipping insecure file init.rc
把其权限设为644就ok了。

#/system/lib/libbinder.so打开/dev/binder权限不足
找出问题的过程不讲了，就是分析那个backtarce信息。

造成这个问题的原因是ueventd.rc权限问题导致这个文件没有起作用。


