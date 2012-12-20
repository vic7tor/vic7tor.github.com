---
layout: post
title: "android never suspend"
description: ""
category: 
tags: []
---
{% include JB/setup %}

packages/apps/Settings/res/values/arrays.xml文件的screen_timeout_values和screen_timeout_entries自己在下面加个新的项目。

然后，对应的翻译项目，比方说中文：

packages/apps/Settings/res/values-zh-rCN/arrays.xml下面的screen_timeout_entries

在values-zh-rCN/arrays.xml有一个msgid的属性，这玩意暂时不知道有什么用。在其它非英语中，对应值是一样的，有人说，这玩意不要也行。

