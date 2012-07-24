---
layout: post
title: "Jekyll Problem"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#1.category
在md文档，要是想填category的话要在":"后面加一个空格，要不然文章会乱码。
#2._site下不生成东西
当`.md`文件有语法问题时，`_site`下的东西在调用`jekyll --server`时不会生成。
