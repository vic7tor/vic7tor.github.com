---
layout: post
title: "linux共享库"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#共享库的编译
`gcc -fPIC -shared -o xxx.so xxx`

#动态加载共享库
linux动态加载动态库是通过`<dlfcn.h>`来实现的。
操作步骤为：

1. 使用dlopen来打开共享库
2. 使用dlsym根据函数名来取得函数地址
3. 使用dlclose来关闭共享库

这些函数都可以man它来查看详细的说明。
