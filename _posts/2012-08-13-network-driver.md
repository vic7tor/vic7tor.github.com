---
layout: post
title: "network driver"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.sk_buff
在网卡驱动使用到的有data成员，这个指针指向要发送的数据。还有一个成员是len与data_len，DM9000使用len做为数据长度，搞清楚再补上。data_len好像就是len减去头部的长度。有人说，len是数据总长度，data_len是分片的长度。。。以后调试下吧。

#2.net_device
有下列成员：

mtu - 最大传输单元值

type - 设备硬件类型

header_ops - 用于操作网络包硬件首部，create创建一个硬件首部，parse分析一个硬件首部。

为eth驱动时，以上三个成员由ether_setup设置。

name - ifconfig显示的网卡名字，是个字符数组。

dev_addr - 保存设备硬件地址

watchdog_timeo - watchdog超时，为多少jiffies。超时时调用tx_timeout。

netdev_ops - 指向net_device_ops

#net_device_ops

open、stop - 初始化和关闭网卡。ifconfig up down。初始化网卡。

hard_start_xmit - 发送数据，从释放sk_buff。

get_stats - 查询统计数据，ifconfig、netstat显示的，将数据封装成一个net_device_stats结构返回，net_device没有提供该数数。需要自己实现，可以在priv中实现。在新内核中，已经在net_device中设置了net_device_stats并且这个函数也不强制实现。

tx_timeout - 发送超时调用的函数。 dev_activate - `__netdev_watchdog_up`注册了一个定时器。

do_ioctl - 

change_mtu - 以太网设备设为eth_change_mtu。

set_mac_address - 设置mac地址，可设为eth_mac_addr。新的MAC地址在第二个参数中。要转成`struct sockaddr *`的类型。在其sa_data成员中，长为ETH_ALEN。

validate_addr - 可设为eth_valicate_addr

set_rx_mode - 这个函数被调用时，把mac addr写入到网卡中并开启rx? dump_stack看看，dump_stack结果是dev_set_rx_mode调用。`__dev_open`调用，dev_set_rx_mode。更多的见后面吧。

dev_open - `__dev_open` - 

#3.注册网络设备
1.分配net_device
alloc_netdev分配一个新的struct net_device。第一个参数为priv的大小。第二个参数为网卡名字。第三个参数为ether_setup这样的函数。

对于eth驱动可直接使用alloc_etherdev(sizeof(priv))来分配net_device。

2.设置net_device成员。参考上面的。

3.调用register_netdev(处理网卡名字中"%d"这样的格式化串)或register_netdevice注册net_device。

#4.打开关闭函数
ifconfig up down会调用open、close函数，在open函数中启用中断之类。见上面netdev_ops中的描述。open申请网卡中断、DMA、IO端口等资源。还有调用netif_start_queue、netif_stop_queue打开关闭传送队列。成功的话要返回0，出错也要返回相应值。否则使用这个接口的程序会得到打不开的错误。

#5.接收分组
确认数据正确之后，dev_alloc_skb。然后，skb_put把tail设置为包大小，并返回原来的tail指针的位置，读取数据的时候，就从这个原来的指针开始写入。

这个读的驱动，看不同的，有各种不同的写法。

skb_reserve(skb, NET_IP_ALIGN);

这个要明白那个skb_buf.length先吧

#6.发送分组
网卡忙时，start_xmit函数返回NETDEV_TX_BUSY不处理这个sk_buff。发送成功后dev_kfree_skb释放sk_buf并返回NETDEV_TX_OK。成功后注意统计net_device.stats。

还有，当预计到下个上层传来下一个要发送包肯定会返回NETDEV_TX_BUSY，那么可以调用，netif_stop_queue来停止队列，让上层不再提交发送请求。当空闲时，调用netif_wake_queue来唤醒队列。

发送的数据为sk_buff.data指向的。长度为sk_buff.len。

#7.ndo_set_rx_mode
这个函数有在dev_open中通过dev_set_rx_mode调用。在`__dev_set_rx_mode`上面的描述是：Upload unicast and multicast address lists to device and configure RX filtering.

然后在ndo_set_rx_mode中要做的事情有：
1.把单播地址和多播地址写入设备寄存器。单播地址存在net_device.dev_addr。

2.如果，net_device的flags中有IFF_PROMISC则开启网卡的混杂模式。如果，flags中有IFF_ALLMULTI则设置网卡接收所有的多播包。

多播地址的设置方法(64bit hash table)，来自DM9000驱动的代码：

    u16 hash_table[4];
    
    netdev_for_each_mc_addr(ha, dev) {
        hash_val = ether_crc_le(6, ha->addr) & 0x3f; 这个不像DM9000.md中描述的
        hash_table[hash_val / 16] |= (u16) 1 << (hash_val % 16); 16的原因是u16
    }


#一些函数

    alloc_etherdev - 分配一个net_device并用ether_setup初始化。
    free_netdev - 释放net_device结构
    netdev_priv - 获得与net_device结构一起分配的priv区域的指针。
    is_valid_ether_addr - 验证MAC地址是否有效
    random_ether_addr - 随机生成MAC地址
    netif_queue_stopped - tx队列是否停止

#初始化

