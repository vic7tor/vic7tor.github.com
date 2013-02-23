---
layout: post
title: "z stack programming"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#z-stack编程初步
在z-stack里有两个数组，一个是保存一些初始化函数的数组，还有一个是事件处理函数的数组。

这个初始化函数会传入一个task_id，这个task_id应该就是这个初始化函数的数组下标。然后，ZDO_RegisterForZDOMsg的第一个参数就是task_id，当以后有ZDOMsg时，都会交由task_id指向的事件处理函数来处理。

##事件处理函数

这块先空着，以后来补。


#Generic App编程
这种是自定profile吧。

afRegister函数注册一个endpointDesc_t类型的结构，这个结构里还指向simpDescriptionFormat_t的结构。

endpointDesc_t里还有个task_id，然后，AF_INCOMMING_MSG_CMD类型的会发到task_id指向的处理函数。

ZDO_RegisterForZDOMsg当有ZDO那些东东来时，会交给对应的处理函数。

#HA
见z-stack的ZCL那篇文档，要有zcl_xx.c zcl_xxx_data.c这些文件。

zcl_samplight_data.c实现SimpleDescriptionFormat_t的结构体，其成员deviceid那个就指向ZCL_HA_DEVICEID_DIMNBIE_LIGHT(0x0101)。这个就是HA Profile里定义的Device ID。

zcl_samplight.c里实现初始化和事件处理函数。

##ZCL
ZCL属性的实现相当好理解。

关于Command的实现，ZCL是分类的，像Genneral、Closures这样的。对于Genneral里就那几个Cluster，其command也就已知的。对于On/off这属于Genneral的，其Command由zcl_genneral_AppCallback_t里实现。

对于Closures这类的，其command在zcl_Closures_AppCallbacks_t里实现。


##light与switch的相连
开关，灯泡都作为通用设备。这个灯泡被这个或那个开关控制。

light与switch看他们，是后面通过bind才能联系起来的。好像有两种方法:ZDP_EnddeviceBindREq和ZDP_MAtchDescReq。

例子中的那个ZDP_ENDDEVICEBINDREQ是发给协调器，说是要协调器来帮忙bind?

