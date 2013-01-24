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

alsa mixer用来调节音的吧。mixer_open打开的是/dev/snd/controlC%u。

alsa设备节点的格式:/dev/snd/pcmC%uD%u%c C-Card D-Device 最一个是字母c(captrue)或p(playback)。

#重要的东东

system/core/include/system/audio.h 定义了很多Android声音系统的东西

audio_utils/resampler.h 当声音编码不是44.1khz时，可以用这个转到这个频率。

#3.Android HAL

##LOG定义

    #define LOG_TAG "audio_hw_primary"
    /*#define LOG_NDEBUG 0*/
    /*#define LOG_NDEBUG_FUNCTION*/ 这两个取消注释才会有LOG显示
    #ifndef LOG_NDEBUG_FUNCTION
    #define LOGFUNC(...) ((void)0)
    #else
    #define LOGFUNC(...) (ALOGV(__VA_ARGS__))
    #endif

这些定义要在`#include <cutils/log.h>`之前。

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

    open_output_stream 这个放后面说，获得audio_hw_device_t后第一个调用的就是这个函数。

    close_output_stream

    open_input_stream

    close_input_stream

    dump

##open_output_stream
audio_hw_device_t第一个调用的函数以这样的方式调用：

    V/audio_hw_primary( 1493): adev_open_output_stream:devices=2, audio_config:sample_rate=44100,channel=2,format=1

devices=2为AUDIO_DEVICE_OUT_SPEAKER，format=1为AUDIO_FORMAT_PCM_16_BIT

输出audio_stream_out，设置传入的audio_config中format、channel_mask、sample_rate这几个参数。创建resampler。

函数原型：

    int (*open_output_stream)(struct audio_hw_device *dev,
                              audio_io_handle_t handle,
                              audio_devices_t devices,
                              audio_output_flags_t flags,
                              struct audio_config *config,
                              struct audio_stream_out **stream_out);

##open_input_stream
基本同上，保存audio_config的参数。

##3.audio_stream

    get_sample_rate

    set_sample_rate 暂时不可用，使用set_parameters搞定

    get_buffer_size 这个的计算让我纠结了一下，看OMAP的实现太纠结，然后看了下别人的现在就这么定了，一般是这个buffer_size要满足多少时间。假设20ms时间:buffer_size = 采样率 / (1000ms/20ms) * frame_size(channel * bit一帧为一样采样得到的声道数*采样深度(位数))。然后audio flinger要求buffer_size是16的倍数，然后omap是这么实现的：size = ((size + 15) / 16) * 16;看下面吧。这个算了。

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

    get_latency 一个重要的函数。

##get_latency与get_buffer_size
在这里讲下frame period。还没有深入alsa驱动的编程，可以这些东西到了后面需要修正。

frame就是一次采样所得的＝bit*chanel

A period is the number of frames in between each hardware interrupt. The poll() will return once a period.

get_buffer_size就是计算一个period所需要的buff。

    size_t size = (SHORT_PERIOD_SIZE * DEFAULT_OUT_SAMPLING_RATE) / out->config.rate; 这个采样率高buf小。
    size = ((size + 15) / 16) * 16;
    return size * audio_stream_frame_size((struct audio_stream *)stream);

get_latency算法：

    return (SHORT_PERIOD_SIZE * PLAYBACK_PERIOD_COUNT * 1000) / out->config.rate;

1000是1秒种有1000ms。SHORT_PERIOD_SIZE与PLAYBACK_PERIOD_COUNT实为pcm_config的.period_size和.period_count。

##5.audio_stream_out里函数调用顺序
V/audio_hw_primary( 1493): adev_open:audio_hw_if
V/audio_hw_primary( 1493): adev_init_check
I/AudioFlinger( 1493): loadHwModule() Loaded primary audio interface from tiny210 audio HW HAL (audio) handle 1
V/audio_hw_primary( 1493): adev_open_output_stream:devices=2, audio_config:sample_rate=44100,channel=2,format=1
V/audio_hw_primary( 1493): out_get_format(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_channels(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_sample_rate(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_sample_rate(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_channels(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_format(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_format(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_channels(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_buffer_size(0x40d5fd80)
I/AudioFlinger( 1493): HAL output buffer size 0 frames, normal mix buffer size 0 frames
V/audio_hw_primary( 1493): out_get_buffer_size(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_format(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_sample_rate(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_channels(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_latency(0x40d5fd80)
V/audio_hw_primary( 1493): out_get_latency(0x40d5fd80)
I/AudioFlinger( 1493): Using module 1 has the primary audio interface
V/audio_hw_primary( 1493): adev_set_mode(0x40d5fb90, 0)
V/audio_hw_primary( 1493): adev_set_master_volume(0x40d5fb90, 1.000000)
I/AudioFlinger( 1493): AudioFlinger's thread 0x40aa5008 ready to run
W/AudioFlinger( 1493): Thread AudioOut_2 cannot connect to the power manager service
V/audio_hw_primary( 1493): out_set_parameters(0x40d5fd80, routing=2)
V/audio_hw_primary( 1493): adev_set_voice_volume(0x40d5fb90, 0.000000)
I/AudioPolicyService( 1493): Loaded audio policy from LEGACY Audio Policy HAL (audio_policy)
V/audio_hw_primary( 1493): out_standby(0x40d5fd80)


#4.amixer
