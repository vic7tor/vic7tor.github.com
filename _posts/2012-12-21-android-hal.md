---
layout: post
title: "Android HAL编写"
description: ""
category: 
tags: []
---
{% include JB/setup %}
android访问硬件除HAL之外，也有直接访问dev、sys接口的。frameworks/base/core/jni/下就是有直接的。

查找那里加载HAL，最好的方法就是搜索，模块那个ID。

分析一个现成的东东：device/samsung/tuna，是android 4.1.1里的。

在device/samsung/tuna下可以看到audio、liblight、libsensors这样的目录，这些目录就是HAL模块。

每个目录下都有一个Android.mk文件，这个文件用来定义编译这个这个模块的参数：

    LOCAL_MODULE := lights.tuna

然后，最终被AndroidProducts.mk那个device.mk里用下面语句，指示编译lights.tuna这个模块：

    PRODUCT_PACKAGES := \
        lights.tuna \
        charger \
        charger_res_images

#AndroidProducts.mk常用的宏

    PRODUCT_PACKAGES
    PRODUCT_COPY_FILES
    PRODUCT_PROPERTY_OVERRIDES
    PRODUCT_DEFAULT_PROPERTY_OVERRIDES

    PRODUCT_PACKAGES += \
        libnfc \
        libnfc_jni \
        Nfc \
        Tag

    PRODUCT_COPY_FILES += \
        $(LOCAL_KERNEL):kernel \
        device/samsung/tuna/init.tuna.rc:root/init.tuna.rc \
        device/samsung/tuna/init.tuna.usb.rc:root/init.tuna.usb.rc \
        device/samsung/tuna/fstab.tuna:root/fstab.tuna

    PRODUCT_PROPERTY_OVERRIDES := \
        wifi.interface=wlan0

#Android.mk
网上大把，看情况补不补吧。

#HAL的基础设施
##1.hardware/libhardware/hardware.c
实现hw_get_module函数，这个函数用一个字符串（HAL模块的名字)做为参数，与ro.hardware、ro.product.board、ro.board.platform、ro.arch，再与/system/lib/hw、/vendor/lib/hw合成库路径，然后用dlopen打开这个库。然后通过一个叫"HMI"的符号取得导出的hw_module_t。

hardware/libhardware/include/hardware/hardware.h:

##HAL_MODULE_INFO_SYM
hw_get_module

##hw_module_t

##hw_device_t

#各种HAL
在hardware/libhardware/include/hardware/目录下有这些文件：

    audio_effect.h     camera.h           hwcomposer_defs.h  nfc.h
    audio.h            fb.h               hwcomposer.h       power.h
    audio_policy.h     gps.h              keymaster.h        qemud.h
    camera2.h          gralloc.h          lights.h           qemu_pipe.h
    camera_common.h    hardware.h         local_time_hal.h   sensors.h

每个头文件里面都有详细的文档。描述结构体成员的作用。


#实现HAL
实现继承hw_module_t的结构体。

实现继承hw_device_t的结构体。

#使用HAL
包含HAL头文件，然后用hw_get_module(XXX_HARDWARE_MODULE_ID)得到继承hw_module_t的结构体。

调用xxx_open(调用module->methods->open)获得继承hw_device_t的结构体。

调用hw_device_t中的函数来操作设备。


