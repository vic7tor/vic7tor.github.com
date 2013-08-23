---
layout: post
title: "device tree"
description: ""
category: 
tags: []
---
{% include JB/setup %}

本文综全宋宝华的文章＋Documentation/devicetree/usage-model.txt＋http://devicetree.org/Device_Tree_Usage

#device tree
起源就不说了。

device由一系列命名的node和property组成。node就是花括号，property就是等号。

property的类型:

    Text strings (null terminated) are represented with double quotes:
        string-property = "a string"
    'Cells' are 32 bit unsigned integers delimited by angle brackets:
        cell-property = <0xbeef 123 0xabcd1234>
    binary data is delimited with square brackets:
        binary-property = [0x01 0x23 0x45 0x67];
    Data of differing representations can be concatenated together using a comma:
        mixed-property = "a string", [0x01 0x23 0x45 0x67], <0x12345678>;
    Commas are also used to create lists of strings:
        string-list = "red fish", "blue fish";

和python一样，数据类型由右值决定。

##板级文件
不再是MACHINE_START而是DT_MACHINE_START。


    DT_MACHINE_START(MSM8226_DT, "Qualcomm MSM 8226 (Flattened Device Tree)")
        .map_io = msm_map_msm8226_io,
        .init_irq = msm_dt_init_irq,
        .init_machine = msm8226_init,
        .handle_irq = gic_handle_irq,
        .timer = &msm_dt_timer,
        .dt_compat = msm8226_dt_match,
        .reserve = msm8226_reserve,
        .init_very_early = msm8226_early_memory,
        .restart = msm_restart,
        .smp = &arm_smp_ops,
    MACHINE_END

dt_compat指向的：

    static const char *msm8226_dt_match[] __initconst = {
        "qcom,msm8226",
        "qcom,msm8926",
        "qcom,apq8026",
        NULL
    };

去arch/arm/boot/dts下面去grep可以找到同样定义的地方。这两个的联系还是来分析下usage-model.txt提到的arch/arm/kernel/setup.c will call setup_machine_fdt() in
arch/arm/kernel/devicetree.c which searches through the machine_desc
table and selects the machine_desc which best matches the device tree
data.

在arch/arm下grep -rn "dtb-" *就可以找到一个dts文件是怎么被引用的。

##setup_machine_fdt


##device tree语法追踪
看高通的这个的实现，msm8226-sim.dts包含了msm8226.dtsi。这里面有一个`/`开头的根结点，在这个根结点里有一句`soc: soc { };`然后在这个结点之外有`&soc `一个，这又是什么概念。soc:soc这是什么意思？

##devicetree调试
/proc/devicetree可以用来查看devicetree的信息

dtc位于scripts/dtc

#驱动上中使用device tree
来自device-tree-zynq

    static struct of_device_id xillybus_of_match[] __devinitdata = {
         { .compatible = "xlnx,xillybus-1.00.a", },
         {}
    };

    MODULE_DEVICE_TABLE(of, xillybus_of_match);

    static struct platform_driver xillybus_platform_driver = {
        .probe = xilly_drv_probe,
        .remove = xilly_drv_remove,
        .driver = {
            .name = "xillybus",
            .owner = THIS_MODULE,
            .of_match_table = xillybus_of_match,
        },
    };

compatible这个property就是用来配对的

##获取device tree中定义的资源

    xillybus_0: xillybus@50000000 {
      compatible = "xlnx,xillybus-1.00.a";
      reg = < 0x50000000 0x1000 >;
      interrupts = < 0 59 1 >;
      interrupt-parent = <&gic>;
      ...
    };

在代码中：

    of_address_to_resource(&op->dev.of_node, 0, &res);
    of_iomap(op->dev.of_node, 0);
    irq_of_parse_and_map(op->dev.of_node, 0);

