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

#mms-common.jar
报

    D/dalvikvm( 1751): Unable to stat classpath element '/system/framework/mms-common.jar'

这个是因为init.rc中的export BOOTCLASSPATH里有/system/framework/telephony-common.jar:/system/framework/mms-common.jar造成的。

这个init.rc用的是4.2.1里那个init.rc。

看来，以后还是得用当前版本的init.rc修改才行。不能用别的。

#OPENGL_RENDERER
先用默认的软件opengl实现试试，但是有下面问题。

这个问题网上说是USE_OPENGL_RENDERER被设置，在framework下grep一下，发现有很多地方引用这个宏。

    E/AndroidRuntime( 1726): java.lang.RuntimeException: eglConfig not initialized
    E/AndroidRuntime( 1726):        at android.view.HardwareRenderer$GlRenderer.initializeEgl(HardwareRenderer.java:811)
    E/AndroidRuntime( 1726):        at android.view.HardwareRenderer$GlRenderer.initialize(HardwareRenderer.java:747)

在BoardConfig.mk里把这个宏定义成false吧。

#type password to decrypt storage

logcat时发现有一个叫CryptKeeper在动。

packages/apps/Settings/src/com/android/settings/CryptKeeper.java中搜vold.decrypt。在代码中可以看到，vold.decrypt这个属性为空或者另外一个值就直接返回，要不就是后面的输密码的框了。

在init.rc中，设置这个属性会自动创建/data下的目录。

    on property:vold.decrypt=trigger_post_fs_data
        trigger post-fs-data

#触屏见另外一篇文章了
