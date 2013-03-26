---
layout: post
title: "Android Camera Framework"
description: ""
category: 
tags: []
---
{% include JB/setup %}
研究这个框架用Source Insight了，Android里面文件太多，vim+ctags吃不消。Source Insight真心厉害，算法效率高。

这个框架一个共有三大块吧。JNI、Camera、CameraService。

JNI使用Camera和CameraService吧。

Camera是ICamereClient的实现，Camera里面有很多静态函数，JNI里面就调用了这些静态函数。Camera是继承BnCameraClient的。有一个connect与ICameraService进行连接。

通过这个connect，BnCameraService就会获得一个BpCameraClient。这样就建立起连接了。

然后CameraService里面实现了ICamera和ICameraService。ICamera里提供了照像这些函数。

然后，JNI里有个什么JNICameraContex吧，他继承CameraListener，然后ICameraClient里有个函数setListerner的。还有JNI也调用ICameraService里的东东。

大致就这样，过了这么久可能有点记不清了。有需要深究的时候，在纸上画画图，理下它们的关系。


