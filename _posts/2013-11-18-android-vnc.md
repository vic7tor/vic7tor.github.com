---
layout: post
title: "android vnc"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.compile
使用Android源代码目录下的ndk。

##1.toolchain
ndk/docs/STANDALONE-TOOLCHAIN.html

./build/tools/make-standalone-toolchain.sh --toolchain=arm-linux-androideabi-4.7 --platform=android-5 --install-dir=/tmp/my-android-toolchain
