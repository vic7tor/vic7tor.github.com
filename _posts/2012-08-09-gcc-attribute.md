---
layout: post
title: "gcc attribute"
description: ""
category: 
tags: []
---
{% include JB/setup %}
一共有三种Attribute：Function、Variable、Type。用`gcc attribute`一搜就能出官方的文档。这篇文章只是简单讲下。官方文档这三种都有。

attribute　specifier的格式是

    __attribute__ ((attribute-list))

有两个括号。原因就是，在头文件里使用，不会认为是宏。。


