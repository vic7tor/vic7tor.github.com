---
layout: post
title: "CM Porting"
description: ""
category: 
tags: []
---
{% include JB/setup %}
下下来CM的源代码兴冲冲的编译完。运行起来和官方的没有什么差别。研究了一番才搞定。很早就应该写这篇文章了，直到昨天解决了那个skia的问题。

#cm_xxx
vendorsetup.sh里要有`add_lunch_combo cm_tiny210-eng`这样以cm_xxx开头的东西，以这样来命名才会进行编译CM的东西，mgrep找到的。起这样的名，import-product用的是cm.mk否则像full_xxx这样的是用的是AndroidProduct.mk。

#PRODUCT_RESTRICT_VENDOR_FILES
这个为真的话，好像是不能继承vendor/cm/下的东东。

#trigger post-fs-data
发现把这句加在on fs里会导致停机，连启动时的开机动画都没有，放在on boot里很正常。

#skia崩溃
调试出来的，用gdbclient来定位，最后发现是少了etc下那些字体配置文件。

