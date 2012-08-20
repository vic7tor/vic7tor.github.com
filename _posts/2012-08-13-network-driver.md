---
layout: post
title: "network driver"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.sk_buf
在网卡驱动使用到的有data成员，这个指针指向要发送的数据。还有一个成员是len与data_len，DM9000使用len做为数据长度，搞清楚再补上。

#2.net_device
有下列成员：

mtu - 最大传输单元值

type - 设备硬件类型

header_ops - 用于操作网络包硬件首部，create创建一个硬件首部，parse分析一个硬件首部。

为eth驱动时，以上三个成员由ether_setup设置。

name - ifconfig显示的网卡名字，是个字符数组。

dev_addr - 保存设备硬件地址

watchdog_timeo - watchdog超时，为多少jiffies。超时时调用tx_timeout。

下面这个函数已经封装在了net_device_ops，并加了前缀`ndo_`，netdev_ops成员。

open、stop - 初始化和关闭网卡。ifconfig up down。初始化网卡。open申请网卡中断、DMA、IO端口等资源。还有调用netif_start_queue、netif_stop_queue打开关闭传送队列。

hard_start_xmit - 发送数据，从释放sk_buf。

get_stats - 查询统计数据，ifconfig、netstat显示的，将数据封装成一个net_device_stats结构返回，net_device没有提供该数数。需要自己实现，可以在priv中实现。在新内核中，已经在net_device中设置了net_device_stats并且这个函数也不强制实现。

tx_timeout - 发送超时调用的函数。

do_ioctl - 

change_mtu - 以太网设备设为eth_change_mtu。

set_mac_address - 设置mac地址，可设为eth_mac_addr

validate_addr - 可设为eth_valicate_addr

set_rx_mode - 这个函数被调用时，把mac addr写入到网卡中并开启rx? dump_stack看看

#3.注册网络设备
1.分配net_device
alloc_netdev分配一个新的struct net_device。第一个参数为priv的大小。第二个参数为网卡名字。第三个参数为ether_setup这样的函数。

对于eth驱动可直接使用alloc_etherdev(sizeof(priv))来分配net_device。

2.设备net_device成员。参考上面的。

3.调用register_netdev(处理网卡名字中"%d"这样的格式化串)或register_netdevice注册net_device。

#4.打开关闭函数
ifconfig up down会调用open、close函数，在open函数中启用中断之类。

#5.接收分组
确认数据正确之后，dev_alloc_skb。然后，skb_put把tail设置为包大小，并返回原来的tail指针的位置，读取数据的时候，就从这个原来的指针开始写入。

这个读的驱动，看不同的，有各种不同的写法。

skb_reserve(skb, NET_IP_ALIGN);

这个要明白那个skb_buf.length先吧

#6.发送分组
网卡忙时，start_xmit函数返回NETDEV_TX_BUSY不处理这个sk_buf。发送成功后释放sk_buf并返回NETDEV_TX_OK。成功后注意统计net_device.stats。

还有，当预计到下个上层传来下一个要发送包肯定会返回NETDEV_TX_BUSY，那么可以调用，netif_stop_queue来停止队列，让上层不再提交发送请求。当空闲时，调用netif_wake_queue来唤醒队列。

发送的数据为sk_buff.data指向的。长度为sk_buff.len。


