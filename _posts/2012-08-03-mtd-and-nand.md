---
layout: post
title: "mtd and nand"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.从用户空间到mtd
##1.字符设备节点
在add_mtd_device中，有device_create，这么来说，udev又登场了。
##2.字符设备打开函数mtd_open
通过设备号minor右移得到`mtd->index`(来自add_mtd_device)，得到struct mtd后放入struct mtd_file_info，再把mtd_file_info放到`file->private_data`。打开完成。
##3.字符设备写函数mtd_write
根据mtd.mode的不同会调用`mtd->write_oob`、`mtd->write`等函数。
`mtd->write`等这些函数的来自于`nand_scan_tail`。
##4. nand_scan_tail
ecc相关、一些默认函数。在后面有：`mtd->write = nand_write;`

##5.nand_write


##6.nand_do_write_ops
`chip->select_chip`
nand_fill_oob
`chip->write_page`(在nand_scan_tail中chip->write_page = nand_write_page;)

##7.nand_write_page
`chip->ecc.write_page`(mtd, chip, buf);
`chip->ecc.write_page`在nand_scan_tail中设置

##6.nand_read_page_hwecc
每次读`chip->ecc.size`下。然后，计算`chip->ecc.bytes`个ECC。一共读`chip->ecc.steps`下。

在nand_write_page先`chip->cmdfunc(mtd, NAND_CMD_SEQIN, 0x00, page);`然后，调用`chip->ecc.write_page(mtd, chip, buf);`(这里就是nand_read_page_hwecc)，在nand_read_page_hwecc，有个循环，每次调用write_buf写`chip->ecc.size`大小，写完后，还计算ECC。循环完后，才调用`chip->write_buf`写OOB，看起来是没有连续写，但是，在整个过程中，都没有改变NAND的命令，就是那个`chip->cmdfunc`，所以，虽然停了下，但还是那个命令，做了别的事，但没改变对NAND的命令。

在nand_scan_tail中:

	chip->ecc.steps = mtd->writesize / chip->ecc.size;
	chip->ecc.total = chip->ecc.steps * chip->ecc.bytes;
	chip->ecc.size - 每次读写的大小
	chip->ecc.bytes - 每次读写ecc的字节数
	chip->ecc.steps - 一页要读多少次

那个s3c2410.c的nand驱动有一个bug，从nand_read_page_hwecc的代码来看，一页的读写会有多次，每次的ecc大小就是`chip->ecc.size`，然而，那个驱动设置的layout里的size只有3，一次就爆了，前3字节的layout的eccpos能用。这一页，读第二次的时候，问题就来了，后面eccpos没有设置，会初始化为0，下面的代码就出问题了

        for (i = 0; i < chip->ecc.total; i++)
                ecc_code[i] = chip->oob_poi[eccpos[i]];

所以，layout的eccbytes要大于`chip->ecc.total`。而且`chip->ecc.bytes`与layout的eccbytes不是一个概念，前者要比后者小。

##7.mtd_device_parse_register
在这个函数中，先parse_mtd_partitions。然后呢，有下面语句，mtd为mtd_device_parse_register的参数：

        if (err > 0) {
                err = add_mtd_partitions(mtd, real_parts, err);
                kfree(real_parts);
        } else if (err == 0) {
                err = add_mtd_device(mtd);
                if (err == 1)
                        err = -ENODEV;
        }

mtd就是在驱动中传来的mtd。讲起来这玩意没有什么用。如果parse_mtd_partitions成功的话，它是不会被add_mtd_device的。重中之重就在`add_mtd_partitions`。

在`add_mtd_partitions`中，对于每一个分区都，`allocate_partition`。

allocate_partition部分代码，master就是传进来的mtd，然后，`mtd->write_oob`、`mtd->write`等函数就是在这里填充的。这些函数调用master的相应函数，在nand_scan_tail中设置那些。

        slave->mtd.type = master->type;
        slave->mtd.flags = master->flags & ~part->mask_flags;
        slave->mtd.size = part->size;
        slave->mtd.writesize = master->writesize;
        slave->mtd.writebufsize = master->writebufsize;
        slave->mtd.oobsize = master->oobsize;
        slave->mtd.oobavail = master->oobavail;
        slave->mtd.subpage_sft = master->subpage_sft;

在add_mtd_partitions中，allocate_partition后就`add_mtd_device(&slave->mtd)`。

#bbt
#1.nand_set_defaults

        if (!chip->scan_bbt)
                chip->scan_bbt = nand_default_bbt;


bbt的以后用stap跟踪吧，现在能找了。

#mtd的一个文件系统

#一个mtd nand驱动的实现
##1.先设置一些默认值

	mtd->priv = chip; - 这个很多函数通过这个找到nand_chip
	chip->write_buf
	chip->read_buf - nand_scan_ident调用的nand_set_defaults中设置了，要不要自己实现看情况
	chip->select_chip - 如果第二个参数是-1就是取消选择，不为-1选中对应的chip，如果有很多个chip的话
	chip->IO_ADDR_W - 写数据的寄存器chip->write_buf的默认函数使用了。
	chip->cmd_ctrl - 用来写命令或地址，第三个参ctrl & NAND_CLE为真的话，当前第二个参数就是命令，否则就是地址。
	chip->dev_ready - 测试设备是否忙。只测试，不阻塞，忙返回0，反之1

	chip->ecc.layout
	chip->ecc.calculate - 
	chip->ecc.correct
	chip->ecc.mode
	chip->ecc.hwctl - 在读写之前调用的，初始化ECC，S3C2440的NFCONT有一位。

	chip->options - BUSWIDTH的需要设置，nand_scan_ident需要用到

s3c2410驱动上说的u-boot bbt什么的。

	chip->bbt_options |= NAND_BBT_USE_FLASH;
	chip->options |= NAND_SKIP_BBTSCAN;

##2.调用nand_scan_ident
这个函数一定返回，自己去看代码吧。

调用了nand_set_defaults和nand_get_flash_type

nand_set_defaults

nand_get_flash_type - 调用了nand_flash_detect_onfi，设置了mtd的erasesize、writesize、oobsize和chip的page_shift、pagemask、chip_shift、badblockpos等等。

nand_flash_detect_onfi设置了`chip->onfi_version`
这个以后可以看看。

##3.调用nand_scan_tail
这个也干了很多事的，还是去看代码吧。

##4.调用mtd_device_parse_register
最后一步了，处理分区并应用相应的mtd。

