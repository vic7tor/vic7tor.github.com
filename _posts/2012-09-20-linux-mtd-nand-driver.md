---
layout: post
title: "linux mtd nand driver"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#mtd结构
##1.mtd_info
用来描述一个设备或一个分区

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

##3.mtd_partion

    name - 分区名字
    size - 分区大小
    offset - 分区偏移
    mask_flags - 
    ecclayout - 
    mtdp -

    add_mtd_partitions
    del_mtd_partitions

#2.nand
##1.nand_chip

    IO_ADDR_R - 一般在读NAND的寄存器使用
    IO_ADDR_W - 一般在写NAND的寄存器时使用，这两个RW如何用，还是要看自己
    各种读写函数
    write_buf - 写buf中的指定字节
    read_buf - 读指定字节到buf中
    chip_delay - 等待这个时间后调用下面的dev_ready
    select_chip - 这个函数是要实现的，用来选择chip
    cmd_ctrl －第二个参数cmd，当cmd为NAND_CMD_NONE时直接返回，然后，当第三个参数ctrl & CLE为真时，那么就要写入到命令寄存器。否则写入到地址中。
    dev_ready - 判断设备是否忙
    cmd_func － 
    各种NAND的信息
    nand_ecclayout - ecclayout
    nand_ecc_ctrl ecc - 这个结构当然重要了，见另一篇文章。
    options - NAND_BUSWIDTH_16

##2.nand_ecc_ctrl

    nand_ecc_modes_t mode - NAND_ECC_SOFT,NAND_ECC_HW之类
    hwctl
    calculate - 硬件ECC要实现这个函数
    correct - 硬件ECC要实现这个函数
    各种读写函数

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
    设置nand_chip中的东西
    设置nand_chip.nand_ecc_ctrl中的mode、(size bytes layout这几个成员等nand_scan_ident后设置)
    nand_scan_ident
    nand_scan_tail
    mtd_device_parse_register
