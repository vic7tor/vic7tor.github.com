---
layout: post
title: "linux i2c subsystem"
description: ""
category: 
tags: []
---
{% include JB/setup %}
在linux内核文档的i2c目录下有三篇不错的文档。dev-interface，从用户态访问i2c adapter创建i2c_client等与设备进行通信。instantiating-devices，讲述如何创建一个i2c device。writing-clients，讲述怎么实现一个i2c的客户端。

在i2c子系统中一共有4个元素，i2c_adapter、i2c_algorithm（总线驱动部分）；i2c_client、i2c_driver（设备驱动部分）。

i2c_adapter对应物理上的适配器，i2c_adapter对应一套通信方法。

i2c_client对应物理上的设备，i2c_driver对应设备驱动，实现功能供用户态使用。

只有调用i2c_new_device或i2c_new_probed_device才会创建一个i2c_client。查找这两个函数的引用。

在mach-*/mach-*.c中，使用i2c_board_info来描述一个设备，使用i2c_register_board_info注册到系统中。最终，在i2c_register_adapter的时候，在i2c_scan_static_board_info这个函数中，调用i2c_new_device以i2c_board_info为参数来创建i2c_client。

在instantiating-devices描述的几种创建i2c device的方法中，第一种是定义i2c_board_info，然后使用i2c_register_board_info。第二种是，定义i2c_board_info，然后调用i2c_new_device。其它的不说了。第一种适合在没有调用i2c_register_adapter之前已经调用了i2c_register_board_info这个函数，在mach-*/mach-*.c的代码中，是可以的。第二种任何时候都行了。

两种方法都最终调用了i2c_new_device，在i2c_new_device中会调用device_register这个函数。

在前面的文章，linux device driver model中研究过的，device_register、driver_register都会调用总线的match，最终调用驱动的probe函数。

这样，i2c_driver中的probe函数就被调用了。

i2c_board_info结构体，template for device creation，这个结构体的成员在i2c_new_device中都被复制到i2c_client里去了。i2c_board_info成员详解可以在这个结构定义处的上方看到。

    struct i2c_board_info {
        char            type[I2C_NAME_SIZE]; //chip type, to initialize i2c_client.name
        unsigned short  flags; //to initialize i2c_client.flags
        unsigned short  addr; //stored in i2c_client.addr
        void            *platform_data; //stored in i2c_client.dev.platform_data
        struct dev_archdata     *archdata; //copied into i2c_client.dev.archdata
        struct device_node *of_node; //pointer to OpenFirmware device node
        int             irq; //stored in i2c_client.irq
    };

来自instantiating-devices：

    static struct i2c_board_info sfe4001_hwmon_info = {
        I2C_BOARD_INFO("max6647", 0x4e),
    };

    #define I2C_BOARD_INFO(dev_type, dev_addr) \
        .type = dev_type, .addr = (dev_addr)

    i2c_register_board_info(1, h4_i2c_board_info,
                 ARRAY_SIZE(h4_i2c_board_info));

i2c_register_board_info第一个参数指定是哪个i2c_adapter。

每一个i2c设备都有一个自己的地址，当总线上有数据时，每个设备都会收到，总线上的数据会指定接收设备的地址，设备收到后，会与自己的地址比较，如果是发给自己的才会接收数据。i2c设备有7位和10两种长度的地址，10位寻址采用了保留的1111XXX 作为起始条件（S），或重复起始条件（Sr ）的后第一个字节的头7 位。

来自writing-clients：

    static struct i2c_device_id foo_idtable[] = {
        { "foo", my_id_for_foo },
        { "bar", my_id_for_bar },
        { }
    };

    MODULE_DEVICE_TABLE(i2c, foo_idtable);

    static struct i2c_driver foo_driver = {
        .driver = {
                .name   = "foo",
        },

        .id_table       = foo_idtable,
        .probe          = foo_probe,
        .remove         = foo_remove,
        /* if device autodetection is needed: */
        .class          = I2C_CLASS_SOMETHING,
        .detect         = foo_detect,
        .address_list   = normal_i2c,
    ...

probe会传入i2c_client，后面的i2c_master_send、i2c_transfer这样的函数都需要i2c_client做为参数。 
