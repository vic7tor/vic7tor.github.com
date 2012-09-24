---
layout: post
title: "linux mtd nand driver"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#mtd结构
##1.mtd_info <linux/mtd/mtd.h>
用来描述一个设备或一个分区

    name - 名字，很重要一个结构，u-boot使用mtdids、mtdparts(linux内核使用)环境变量时要用到这个东西
    type - MTD_RAM MTD_ROM MTD_NORFLASH MTD_NANDFLASH
    flags - MTD_WRITEABLE MTD_BIT_WRITEABLE MTD_NO_ERASE ...
    read write read_oob write_oob erase 读写函数，可以看另一篇文档

    add_mtd_device
    del_mtd_device



##2.mtd_part

    mtd - 该分区的mtd
    master - 该设备的mtd
    offset - 该分区的偏移
    index － 分区编号

##3.mtd_partion <linux/mtd/partitions.h>

    name - 分区名字
    size - 分区大小
    offset - 分区偏移
    mask_flags - 
    ecclayout - 
    mtdp -

    add_mtd_partitions
    del_mtd_partitions

#2.nand
##1.nand_chip <linux/mtd/nand.h>

    IO_ADDR_R - 一般在读NAND的寄存器使用
    IO_ADDR_W - 一般在写NAND的寄存器时使用，这两个RW如何用，还是要看自己。这个还有东西用到的，那个nand_set_defaults设置的nand_read_byte，这个要指向NFDATA。
    各种读写函数
    write_buf - 写buf中的指定字节
    read_buf - 读指定字节到buf中
    chip_delay - 等待这个时间后调用下面的dev_ready
    select_chip - 这个函数是要实现的，用来选择chip，第二个参数为-1表示取消选择
    cmd_ctrl －第二个参数cmd，当cmd为NAND_CMD_NONE时直接返回，然后，当第三个参数ctrl & NAND_CLE为真时，那么就要写入到命令寄存器。否则写入到地址中。
    dev_ready - 判断设备是否忙，返回1 ready。
    cmd_func － nand_scan_tail自动设置
    各种NAND的信息
    nand_ecclayout - ecclayout
    nand_ecc_ctrl ecc - 这个结构当然重要了，见另一篇文章。
    options - NAND_BUSWIDTH_16 NAND_NO_SUBPAGE_WRITE(MLC不支持SUBPAGE)

##2.nand_ecc_ctrl

    nand_ecc_modes_t mode - NAND_ECC_SOFT,NAND_ECC_HW之类
    hwctl
    calculate - 硬件ECC要实现这个函数
    correct - 硬件ECC要实现这个函数
    各种读写函数

###1.硬件ECC的实现
另开一篇文章吧

##3.nand_scan_ident
###1.nand_set_defaults
这个函数设备大量前面初始化过程中没有设置的成员。

    nand_chip - chip_delay、cmdfunc、waitfunc(默认的实现会调用LEDS最终调用chip->dev_ready)、select_chip、read_byte、read_word、block_bad、block_markbad、write_buf、read_buf、verify_buf、scan_bbt、controller

###2.nand_get_flash_type
设备下面的成员

    nand_chip - chipsize pagesize page_shift pagemask bbt_erase_shift badblockbits badblockpos erase_cmd cmdfunc(nand_command_lp，根据writesize设备的)
    mtd_info - writesize oobsize erasesize

##4.nand_scan_tail
设备下面的成员

    nand_chip - write_page
    nand_ecc_ctrl - layout 根据mode设置了read_page write_page read_page_raw write_page_raw read_oob write_oob size bytes steps(size要先被设置)
    mtd_info - type flags erase read write read_oob ecclayout

最后调用了一个函数

    chip->scan_bbt(mtd)

##5.mtd_device_parse_register

#3.驱动实现
#1.初始化过程

    mtd->priv设为nand_chip
    mtd->owner = THIS_MODULE;
    设置nand_chip中的东西
    设置nand_chip.nand_ecc_ctrl中的mode、(size bytes layout这几个成员等nand_scan_ident后设置)
    nand_scan_ident
    nand_scan_tail
    mtd_device_parse_register

#4.mtd test
这玩意只能编译成模块

#5.BUG
##1.ECC ERROR
弄UBIFS挂载文件系统的时候报`UBI error: ubi_io_read: error -74 (ECC error) while reading 64 bytes from PEB 0:0, read 64 bytes`。不像网上说的不支subpage读写什么的。看到这句话的上面还有几句`uncorrectable error`在drivers/mtd目录下grep了一下，发现问题出现在`drivers/mtd/nand/nand_ecc.c`的`__nand_correct_data`。`chip->ecc.correct`指向这个函数。看来应该是u-boot与内核的SOFT ECC不兼容。

那么就实现硬件ECC吧。放在上面。
