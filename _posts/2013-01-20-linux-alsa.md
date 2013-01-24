---
layout: post
title: "linux alsa"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#alsa框架
##1.snd_card
代表一块声卡，devices成员挂着snd_device。controls挂着snd_kcontrol

##2.snd_pcm
snd_pcm_new 分配一个snd_pcm结构体，并调用snd_device_new创建一个snd_device，snd_device被放在snd_card的devices成员上。snd_pcm被放在snd_device的device_data上。

snd_device的type区别SNDRV_DEV_PCM、SNDRV_DEV_RAWMIDI。。。

##3.snd_kcontrol
snd_ctl_new 从一个模板创建snd_kcontrol,这个模板是一个snd_kcontrol结构,但是access从参数中获得而不是从模板.

snd_ctl_new1 从模板snd_kcontrol_new中的信息创建一个snd_kcontrol。

snd_ctl_add 把snd_kcontrol挂在snd_card上去，当然，还做点别的事。

#asoc框架
asoc是建立在alsa框架上的,解决嵌入式设备上声音系统。

有一份文档在Documention/sound/soc里。

overview.txt：

    To achieve all this, ASoC basically splits an embedded audio system into 3 components :-
    
      * Codec driver: The codec driver is platform independent and contains audio controls, audio interface capabilities, codec DAPM definition and codec IO functions.
    
      * Platform driver: The platform driver contains the audio DMA engine and audio interface drivers (e.g. I2S, AC97, PCM) for that platform.
    
      * Machine driver: The machine driver handles any machine specific controls and audio events (e.g. turning on an amp at start of playback).

##1.Machine driver

这部分用platform_device_alloc("soc-audio", -1)分配一个platform_device，然后用platform_set_drvdata设置一个snd_soc_card的结构体。

这个platform_device对应的platform_driver在sound/soc/soc-core.c中。

platform_driver对应的probe调用snd_soc_register_card把asoc中的三个元素启用起来。

重要的就是snd_soc_card中的snd_soc_dai_link。

snd_soc_dai_link：

    name
    stream_name
    codec_name
    platform_name 指向的是platform_driver的名字
    cpu_dai_name - Platform driver中snd_soc_dai_driver的name，这个名字生成见下面。
    codec_dai_name

这些名字与对应驱动实现的platfrom_driver的名字有关联，因为snd_soc_register_dai、snd_soc_register_codec、snd_soc_register_platform都使用device结构作为参数来生成对应结构体的名字，大部分使用platform_device的device结构，也有i2c的。名字都是fmt_single_name生成的，具体规则见函数实现。不知道sound有没有从sysfs导出信息。

在platfrom_driver的probe中调用这些函数来注册。

与platform_driver对应的platform_device是在哪注册的呢？

看了下omap的是在arch/arm下的那些代码中。

##2.Platform driver
一个ASoC platform driver可以分成audio DMA和SoC DAI configuration and control。

1.Platform driver通过snd_soc_platform_driver导出DMA功能。

定一个有名字的platform_driver,像omap中的叫omap-pcm-audio，然后在probe中snd_soc_register_platform注册snd_soc_platform_driver


2.SoC DAI Drivers
一个snd_soc_dai_driver与Codec driver中的snd_soc_dai_driver不太一样，这个是用snd_soc_register_dai注册的，而Codec driver中的是用snd_soc_register_codec与snd_soc_codec_driver一起注册的。

这个snd_soc_dai_driver的name成员是由snd_soc_register_dai根据传入的device的名字生成的。所以snd_soc_dai_link中的cpu_dai_name与platform_driver的名字有关联。

##3.Codec driver
Codec driver中有snd_soc_codec_driver和snd_soc_dai_driver。用snd_soc_register_codec把这两个注册起来。

snd_soc_dai_driver的name是在定义结构体的时候设置的。
