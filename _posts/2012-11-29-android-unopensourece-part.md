---
layout: post
title: "android中不开源的部分"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#来源
android4.0源代码device/samsung/crespo

#1.sgx
今天看android4.0里device目录的东西，然后在device/samsung/crespo看到了extract-files.sh这个文件。这个文件就是从设备里拉取那些已经编译的二进制文件，然后放在vendor/制造商/设备下，然后还生成相应的PRODUCT_COPY_FILES。原来想找omap3530那个sgx的源代码，现在看来没有希望了，只能用二进制的了。

然后呢，如果执行了这个命令，在device.mk中的那句：

device.mk

    $(call inherit-product-if-exists, vendor/samsung/crespo/device-vendor.mk)

当extract-files.sh执行后，就会把它拉来的文件包含进来。

除了extract-files.sh还有unzip-files.sh，这个文件会把android源代码根目录的recovery包中的文件复制过来。

不过，有没有开源的还是不是很清楚。

