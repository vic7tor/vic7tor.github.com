---
layout: post
title: "Android Porting"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#0.基本
这篇文章来自一个什么Android Platform Development Kit中的文档，在那个文件中的内容有点老了。

在Android源代码下的`device/*/*/`下需要有Android.mk(编译这个目录下的东西)、BoardConfig.mk(用来定义一块板？还是根据CPU来确定的?)、AndroidProducts.mk(Android源代码编译时就是以Products为单位来编译的)、CleanSpec.mk这几个文件。

##1.各种*.mk文件中语法的含义

    LOCAL_PATH := $(call my-dir)
    include $(call all-makefiles-under,$(LOCAL_PATH))

#1.vendorsetup.sh
这个文件被build/envsetup.sh导入(搜索这个文件名)，导入build/envsetup.sh时有提示的。如果要你的product在lunch显示出来,就要编写这个文件.

    add_lunch_combo full_panda-eng

#1.Android.mk
这个文件与BoardConfig.mk、AndroidProducts.mk不同的是，后两个是配置文件，被Android编译系统所包含取得一些配置信息。这个Android.mk是用来编译这个目录下的东西的。

    LOCAL_PATH := $(call my-dir)
    include $(call all-makefiles-under,$(LOCAL_PATH))

#2.AndroidProducts.mk
Android编译时使用lunch命令来选择产品时，其中显示的条目就来自这个文件。

    PRODUCT_NAME := tiny6410
    PRODUCT_DEVICE := tiny6410 BoardConfig.mk的TARGET_BOOTLOADER_BOARD_NAME还是那个父目录的名字?
    PRODUCT_BRAND := Android
    PRODUCT_MODEL := 随便的描述？
    PRODUCT_PACKAGES += \ 包含的一些包，不止一个使用\转译
        LiveWallpapers \ 这个名字就是Andorid.mk里的LOCAL_PACKAGE_NAME变量指定的名字
	librs_jni
    PRODUCT_PROPERTY_OVERRIDES := \ 那个根文件下build.prop的?
        net.dns1=8.8.8.8 \
	net.dns2=8.8.4.4
    $(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk) SRC_TARGET_IDR指向build/target目录。这个函数就是包含full_base.mk，使用PRODUCT_PACKAGES包含一些基本的包吧。
    PRODUCT_COPY_FILES
    LOCAL_KERNEL

#.BoardConfig.mk
只定义vendorsetup.sh的话，就会在哪里引用了AndroidProducts.mk和BoardConfig.mk。

    build/core/config.mk:138: *** No config file found for TARGET_DEVICE tiny6410。

下面来看看这个文件。


