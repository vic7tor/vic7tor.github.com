---
layout: post
title: "u boot usb gadget"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#前奏
drivers/usb/gadget/Makefile中显示:

    如果CONFIG_USB_GADGET被定义，则COBJS-y += epautoconf.o config.o usbstring.o
    CONFIG_USB_ETHER和CONFIG_USB_DEVICE二选一。

1.CONFIG_USB_GADGET

这个是使用和linux中一样的那个gadget框架，只有s3c那个otg仅仅一个驱动实现了这个。那一句：

    COBJS-$(CONFIG_USB_GADGET_S3C_UDC_OTG) += s3c_udc_otg.o

然后，在这个框架下，没有任何像usb_gadget_driver一样的驱动。使用这个gadget框架，写个usb_gadget_driver驱动和linux的差不了多少吧。

    

2.CONFIG_USB_ETHER与CONFIG_USB_DEVICE

CONFIG_USB_ETHER应该实现的是以太网的设备。CONFIG_USB_DEVICE是老的usb device框架，linux内核中已经没有了。

决定要用gadget框架后发现就没什么好讲的了。写个usb_gadget驱动，然后，导出一些初始化函数到include/usb/，然后，在board/mini2440/mini2440.c的board_init什么调用这个初始化函数。

再然后，就是研究那个usb_gadget_driver怎么来编写。弄usb device这个功能的目的就是通过usb来下载内核。弄种简单的方式。比方把内存映射成什么，直接在主机生一个设备直接写入就到这个内存地址了。

在u-boot中是没有中断的。所有操作都只能用轮询来检测是否完成了。还有u-boot的这个gadget框架没有udc_start.

在那个usb_gadget_driver中，到底怎么传输，还是要看usb_gadget_driver的实现。比方说实现一个自定的控制传输，通知设备准备接收数据，这样子。控制传输肯定会调用usb_gadget_driver的setup，这样子的话，就知道在输入端点，或者输出端点使用usb_ep_queue入队usb_request了。如果不自定义控制传输，得先入个队才行了。

最后，因为u-boot没有中断(在arm920t这些机子上没有实现，如果用arm1176的VIC实现u-boot的中断还是挺方便的)，然后，usb_gadget_driver与usb_gadget的绑定就要阻塞，实现一个函数，开usb的上拉电阻后，轮询所有的数据收发，包括控制端点和一般端点。
