---
layout: post
title: "linux设备驱动模型"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#0
这篇文章的函数介绍来自DocBook的device-drivers。原型什么的就没有弄出来了。看那篇文章吧。

#基本结构
linux/kobject.h
kobject、kset
ldd3说的subsystem结构已经被干掉了，在一个bus_type中，也只是一个kset了。或者说subsystem变成了subsys_private。DocBook那个也没有讲到kobject uevent那些，要是以后用到就补上吧。可以看看linux/kobject.h文件中定义的。


kobject_get_path — generate and return the path associated with a given kobj and kset pair.
在sysfs中的位置
kobject_set_name — Set the name of a kobject
kobject_init — initialize a kobject structure
文档上说，只要调用了kobject_init，就需要调用kobject_put以释放kobject。在kobject_init_internal中有kref_init。kobject_get实际也就调用kref_get。
kobject_add — the main kobject add function
文档上说，调用这个函数不会有"add" uevent。需要自己调用kobject_uevent。
kobject_init_and_add — initialize a kobject structure and add it to the kobject hierarchy
kobject_rename — change the name of an object
kobject_del — unlink kobject from hierarchy.
kobject_get — increment refcount for object.
kobject_put — decrement refcount for object.
kobject_create_and_add — create a struct kobject dynamically and register it with sysfs
kset_register — initialize and add a kset.
kset_unregister — remove a kset.
kset_create_and_add — create a struct kset dynamically and add it to sysfs


#设备驱动模型
linux/device.h
bus_type device_driver device class

为什么会出现这些东西？答案是为了支持像USB、PCI这样的总线的热插拨。当管理USB、PCI控制器的驱动发现新接入了设备后，创建一个包装了的device结构，像usb_device。然后，就是调用下面所说的device_add。找到设备对应的驱动，调用驱动的probe，最终注册字符设备等与用户空间通信。
##device_add
这家伙可是重头戏。bus_type.match与bus_type.p.bus_notifier都在这个函数中被调用了。bus_type.p.bus_notifier是直接在device_add中调用的。bus_type.match是先调用bus_probe_device，在bus_probe_device调用的device_attach中调用的。bus_probe_device仅在bus && bus->p->drivers_autoprobe存在时才调用device_attach。
device_attach中在device.device_driver不存在时，会寻找驱动。调用bus_for_each_drv遍历驱动，传给bus_for_each_drv的第4个参数是\__device_attach在这个函数调用的driver_match_device调用了bus_type.match
在\__device_attach中调用driver_match_device匹配到正确的驱动后，然后就是driver_probe_device。driver_probe_device最后会调bus_type的probe或device_driver的probe。
一般在usb这些driver的probe函数中，会调用包装过的函数，最终创建cdev等，以致于能与用户空间通信。
至此大功告成。

#设备驱动模型与sysfs
从bus_register说起吧。看下面代码，源自于bus_register

    struct subsys_private *priv;
    priv->subsys.kobj.kset = bus_kset;
    priv->subsys.kobj.ktype = &bus_ktype;
    priv->drivers_autoprobe = 1; 
    retval = kset_register(&priv->subsys); 

subsys在subsys_private中就是个kset。kobject.kset（subsys.kobj.kset）就是指向容纳它kset的。
调用的kset_register函数，然后把kset.kobj做为参数调用了kobject_add_internal。
在kobject_add_internal中，根据kobject.kset设置kobject.parent。然后，调用了create_dir（sysfs_create_dir），在sysfs中把这个kset的kobject放在了其parent所在的目录下。
在sysfs中，一个目录对应一个kobject不管是kset中的，还是单独的。
在上面代码出现的bus_kset应该就是最顶级的了，因为bus目录在sysfs的根目录下。没有parent的kobject就会出现在sysfs的根目录下。
