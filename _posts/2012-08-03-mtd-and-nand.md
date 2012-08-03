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
`mtd->write`等这些函数的来历见后面。mtd_device_parse_register
##4.mtd_device_parse_register
先打断下，不讲这个函数不行。在这个函数中，先parse_mtd_partitions。然后呢，有下面语句，mtd为mtd_device_parse_register的参数：

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

allocate_partition部分代码，master就是传进来的mtd，他的作用体现在了这里。然后，`mtd->write_oob`、`mtd->write`等函数就是在这里填充的。

        slave->mtd.type = master->type;
        slave->mtd.flags = master->flags & ~part->mask_flags;
        slave->mtd.size = part->size;
        slave->mtd.writesize = master->writesize;
        slave->mtd.writebufsize = master->writebufsize;
        slave->mtd.oobsize = master->oobsize;
        slave->mtd.oobavail = master->oobavail;
        slave->mtd.subpage_sft = master->subpage_sft;

在add_mtd_partitions中，allocate_partition后就`add_mtd_device(&slave->mtd)`。

##5. mtd的write等函数

#mtd的一个文件系统
