---
layout: post
title: "linux mint"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#1.源更新时的问题
刚安装完后，更新源，报什么不是bizp2、xz文件啊，hash校验和不匹配啊。干掉｀/var/lib/apt/lists/*｀校验和问题就会不在了。部分不是bizp2是因为，`sources.list`文件中源地址URL有错误。
