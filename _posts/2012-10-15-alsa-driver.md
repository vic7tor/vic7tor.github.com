---
layout: post
title: "alsa driver"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.音频编码
##.PCM
PCM的音频编码使用3个参数来描述，采样率(一般为44.1kHz)、采样大小(一般为16bit)、声道数(一般为2)。那么音频编码的比特率(码率)=44.1X16X2 kbps(kbit/s)，1411.2kbps。这个数值就是目前公认的最好音质了，音乐CD都会使用这个比特率，然后能保存72分钟的音乐。当然，有使用更高采样率的技术。但是，就这个编码就绝对足够了。

##.其它编码
比方说MP3这种格式，它通过libmad(MPEG audio decoder)把MP3格式的数据解码为PCM格式的数据，然后通过alsa的PCM接口来播放。

#2.alsa架构

