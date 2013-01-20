---
layout: post
title: "audio hardware hal module"
description: ""
category: 
tags: []
---
{% include JB/setup %}

这篇文章来自于对TI panda的audio HAL的研究。

#1.编译

##1.Android.mk

    LOCAL_PATH := $(call my-dir)
    
    include $(CLEAR_VARS)
    
    ifneq (,$(findstring panda, $(TARGET_PRODUCT)))
        LOCAL_MODULE := audio.primary.panda
    else
        LOCAL_MODULE := audio.primary.generic
    endif
    
    LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
    LOCAL_SRC_FILES := audio_hw.c
    
    LOCAL_C_INCLUDES += \
    	external/tinyalsa/include \
    	$(call include-path-for, audio-utils) \
    	$(call include-path-for, audio-effects)
    LOCAL_SHARED_LIBRARIES := liblog libcutils libtinyalsa libaudioutils libdl
    LOCAL_MODULE_TAGS := optional
    
    include $(BUILD_SHARED_LIBRARY)

LOCAL_MODULE_PATH那玩意指出了模块输出的地方。

LOCAL_C_INCLUDES的那个include-path-for。

LOCAL_SHARED_LIBRARIES应该指示的是这个模块信赖的库，没有编译的话应该就会编译。

##2.编译这个模块

device.mk

    PRODUCT_PACKAGES += \
        audio.primary.panda

#2.tinyalsa

tinyalas与alsa的函数名不同。编程方式应该变化不大。tinyalsa使用内核头文件`<sound/asound.h>`与设备结点交互。

网上有一篇英文的A Tutorial on Using the ALSA Audio API。

snd_pcm_open变成pcm_open

snd_pcm_xx_params_xx这些函数变成了一个结构体`pcm_config`，不用再调用函数设置这些参数，设置好`pcm_config`后，调用pcm_open时，这些参数就设置好了。

pcm_config里有一些需要在pcm_open时设置的参数，同时还有些是pcm_open后的输出参数，像format、period_size、channels、period_count、rate。同时period_size、period_count还是输出参数，见pcm_open实现。

alsa mixer用来调节音的吧。

alsa设备节点的格式:/dev/snd/pcmC%uD%u%c C-Card D-Device 最一个是字母c(captrue)或p(playback)。

#重要的东东

system/core/include/system/audio.h 定义了很多Android声音系统的东西

audio_utils/resampler.h 当声音编码不是44.1khz时，可以用这个转到这个频率。

#3.Android HAL

##1.HAL通用的定义

    static struct hw_module_methods_t hal_module_methods = {
        .open = adev_open,
    };
    
    struct audio_module HAL_MODULE_INFO_SYM = {
        .common = {
            .tag = HARDWARE_MODULE_TAG,
            .module_api_version = AUDIO_MODULE_API_VERSION_0_1,
            .hal_api_version = HARDWARE_HAL_API_VERSION,
            .id = AUDIO_HARDWARE_MODULE_ID,
            .name = "OMAP4 audio HW HAL",
            .author = "Texas Instruments",
            .methods = &hal_module_methods,
        },
    };

audio_module是audio HAL定义的，大部分的xxx_module结构体只有一个hw_module_t common的成员。这就是C语言中的继承。

然后hw_module_methods_t的open操作就是输出一个继承hw_device_t的结构，这个结构里就东西多了。一般hw_module_methods_t的open是由HAL头文件中定义的一个函数调用了，不会写`module->methods->open`来调用。audio的是audio_hw_device_open。

还有这个open是初始化很多东西的一个时机，还有一个地方是audio_hw_device_t的init_check吧。

在omap的实现中：

1.它初始化了audio_hw_device_t中那些函数

2.先用mixer_open打开mixer，然后用mixer_get_ctl_by_name获得各种mixer_ctl，声音控制什么的。

3.然后设置了一些mixer_ctl的值，称这些mixer_ctl为route，这些值初始化后就不会再改变了。

4.切换为Normal模式，set_mode干那事。

5.初始化一些线程锁

##2.hw_device_t的继承者audio_hw_device_t

hw_device_t里面东西也不怎么多，tag、version、module、close这几个。成员名也为common。

audio_hw_device_t里派生了大量与audio有关的东东。

audio_hw_device_t的成员函数：

    get_supported_devices 返回HAL支持哪种类型的设备，system/audio.h里audio_devices_t类型的宏。

    init_check hw_module_methods_t的open调用后调用的一个函数，一些初始化工作可以放在这里，正常初始化返回0，失败返回-NODEV

    set_voice_volume

    set_master_volume omap的例子中这两个没有实现。

    set_mode 定义在system/audio.h中的audio_mode_t里的几种模式。

    set_mic_mute

    get_mic_mute omap的例子也没实现。

    set_parameters

    get_parameters 如果需要再弄吧

    get_input_buffer_size 这个

    open_output_stream 这个放后面说

    close_output_stream

    open_input_stream

    close_input_stream

    dump

open_output_stream　输出audio_stream_out，设置传入的audio_config中format、channel_mask、sample_rate这几个参数。创建resampler。

open_input_stream 基本同上，保存audio_config的参数。

##3.audio_stream

    get_sample_rate

    set_sample_rate 暂时不可用，使用set_parameters搞定

    get_buffer_size 

    get_channels 

    get_format 

    set_format 暂时不可用，使用set_parameters

    standby 使设备待命

    dump

    get_device 

    set_device 

    set_parameters 

    get_parameters 

    add_audio_effect 

    remove_audio_effect 

##4.audio_stream_out

#4.amixer
