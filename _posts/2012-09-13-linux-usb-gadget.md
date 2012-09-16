---
layout: post
title: "linux usb gadget"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#0.Makefile & Kconfig
对于linux内核中的一个子系统，读Makefile的确容易撇开驱动找到核心所在，比直接看文件名来猜测快得多。Kconfig用来解释Makefile。

那么从Makefile中得到gadget子系统的核心文件：udc-core.c

#1.gadget.h
##0.usb_request
##1.usb_ep
ops - usb_ep_ops 实现发送数据数据。
usb_ep_alloc_request、usb_ep_free_request、usb_ep_free_request、usb_ep_dequeue

##2.usb_gadget
usb_gadget - represents a usb slave device

usb_gadget_ops里面的start在注册usb_gadget_driver时被传进来。

一个udc驱动就要使用usb_add_gadget_udc来注册usb_gadget.根据usb device control的个数来注册吧。

##3.usb_gadget_driver
usb_gadget_driver - driver for usb 'slave' devices。应该是实现一个具体的功能，比方说串口，或者U盘什么的。

setup - 要实现所有的get_desciptor请求。get/set_interface、get/set_configuration也一定要实现。

usb_gadget_driver与usb_gadget之间的数据交流不管输入输出都是用那个usb_request。是输入还是输出是由端点的类型决定的。

usb_ep_autoconfig使用一个usb_endpoint_descriptor描述符来分配一个端点。

#2.usb gadget传输过程
##1.在usb_gadget_driver中
因为ep有输入输出两种类型。这个结构读写都行？目的与urb一样吧。答案见的`drivers/usb/gadget/f_loopback.c`的loopback_complete。但其实是`struct usb_ep`结构中的usb_endpoint_descriptor(desc)的bEndpointAddress来决定的。在usb_ep_autoconfig时。

在f_loopback.c的loopback_complete中，如果当前usb_request成功完成(`usb_request.status`)，如果它是OUT（通过complete第一个参数usb_ep确定)，那么就再把usb_request使用usb_ep_queue(in_ep, req, ..)，放到IN ep的队列中。反之是IN的传输完成就把它放到OUT的队列。

在enable_loopback中，先配很多个usb_request放在out那个ep的队列上。然后就是，上面的过程了，如果out ep的队列上有usb_request完成了，然后这个usb_request就会放在in ep的队列上。

##2.在usb_gadget中


#2.udc驱动
在中断中处理请求，如果设备状态在没有配置情况下，处理一般的请求，其它的交给usb_gadget_driver.setup处理。usb_gadget_driver上方定义的文档写道。s

#3.usb_gadget_driver
usb_gadget_probe_driver - 注册gadget driver，只有这个函数，目前版本内核切掉了usb_gadget的bind成员，这个函数的第二个参数bind，要写出来。

bind要做的事情，稍后列出来。

usb_gadget_unregister_driver -
