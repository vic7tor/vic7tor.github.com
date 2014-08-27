---
layout: post
title: "go http pprof"
description: ""
category: 
tags: []
---
{% include JB/setup %}

文档上说是用
import _ "net/http/pprof"来导入这个包。_是只执行它的init?

init如下，已为已经搞掉了默认的ServeMux，所以，只能自己添加进去了。

func init() {
        http.Handle("/debug/pprof/", http.HandlerFunc(Index))
        http.Handle("/debug/pprof/cmdline", http.HandlerFunc(Cmdline))
        http.Handle("/debug/pprof/profile", http.HandlerFunc(Profile))
        http.Handle("/debug/pprof/symbol", http.HandlerFunc(Symbol))
}

使用import "net/http/pprof"，然后把init函数列出的给加进去。
