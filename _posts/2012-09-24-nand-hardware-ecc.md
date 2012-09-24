---
layout: post
title: "nand hardware ecc实现"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.nand_ecc_ctrl

	struct nand_ecc_ctrl {
	        nand_ecc_modes_t mode;
	        int steps;
	        int size;
	        int bytes;
	        int total;
	        int prepad;
	        int postpad;
	        struct nand_ecclayout   *layout;
		...
	        void (*hwctl)(struct mtd_info *mtd, int mode);
	        int (*calculate)(struct mtd_info *mtd, const uint8_t *dat,
	                        uint8_t *ecc_code);
	        int (*correct)(struct mtd_info *mtd, uint8_t *dat, uint8_t *read_ecc,
	                        uint8_t *calc_ecc);
		...其它函数都由nand_scan_tail设置了，需要实现的有上面三个
	};

##1.mode
NAND_ECC_SOFT,NAND_ECC_HW等
##2.steps & size
nand_read_page_hwecc这个函数里要读写steps次。一次会读size大小，然后计算一次bytes字节的ECC码。

如果是NAND_ECC_HW，size要设置大小，steps根据size计算出来的。
##3.bytes && total
一次读写会产生bytes字节的ecccode.total = steps * bytes.

如果是NAND_ECC_HW，bytes要手动设置。total是nand_scan_tail计算的。
##5.layout
见下面
##5.hwctl
`chip->ecc.hwctl(mtd, NAND_ECC_WRITE);`调用的。这个是在所有读写操作前的，NFCONT_INITECC，初始化ECC。
##6.calculate
从寄存器中读取ECC写入到传入的第三个参数。
##7.correct
返回值是修正的数据的数量。返回负值是出错的情况。见nand_read_page_hwecc。

#2.nand_ecclayout
这个的实例可以见nand_scan_tail引用的nand_oob_64等

	struct nand_ecclayout {
       		__u32 eccbytes;下面那个数组有有效数据的数量
	        __u32 eccpos[MTD_MAX_ECCPOS_ENTRIES_LARGE];
	        __u32 oobavail;
	        struct nand_oobfree oobfree[MTD_MAX_OOBFREE_ENTRIES_LARGE];
	};

	static struct nand_ecclayout nand_oob_64 = {
	        .eccbytes = 24,
	        .eccpos = { 
	                   40, 41, 42, 43, 44, 45, 46, 47,
	                   48, 49, 50, 51, 52, 53, 54, 55,
	                   56, 57, 58, 59, 60, 61, 62, 63},
	        .oobfree = { 
	                {.offset = 2,
	                 .length = 38} }
	}; 

eccpos：nand_read_page_hwecc读完一页后会有一个nand_ecc_ctrl.total数量的数据，会被写到eccpos指定的位置中去。

#3.nand_read_page_hwecc && nand_write_page_hwecc
如何执行到这个函数的见另外一篇文章。

这个是nand_ecc_ctrl的read_page成员的值，由nand_scan_tail设置。分析下它的流程以便知道如何操作ECC；

    static int nand_read_page_hwecc(struct mtd_info *mtd, struct nand_chip *chip,
                                    uint8_t *buf, int page)
    {
            int i, eccsize = chip->ecc.size;
            int eccbytes = chip->ecc.bytes;
            int eccsteps = chip->ecc.steps;
            uint8_t *p = buf;
            uint8_t *ecc_calc = chip->buffers->ecccalc;
            uint8_t *ecc_code = chip->buffers->ecccode;
            uint32_t *eccpos = chip->ecc.layout->eccpos;
    	    /* 读eccsteps次 i += eccbytes每次读写ecc_calc数组会增这么多*/
            for (i = 0; eccsteps; eccsteps--, i += eccbytes, p += eccsize) {
                    chip->ecc.hwctl(mtd, NAND_ECC_READ);
                    chip->read_buf(mtd, p, eccsize); /*读eccsize大小*/
                    chip->ecc.calculate(mtd, p, &ecc_calc[i]);
            }
            chip->read_buf(mtd, chip->oob_poi, mtd->oobsize);
            for (i = 0; i < chip->ecc.total; i++)
                    ecc_code[i] = chip->oob_poi[eccpos[i]];
    
            eccsteps = chip->ecc.steps;
            p = buf;
    
            for (i = 0 ; eccsteps; eccsteps--, i += eccbytes, p += eccsize) {
                    int stat;
    
                    stat = chip->ecc.correct(mtd, p, &ecc_code[i], &ecc_calc[i]);
                    if (stat < 0)
                            mtd->ecc_stats.failed++;
                    else
                            mtd->ecc_stats.corrected += stat;
            }
            return 0;
    }


    static void nand_write_page_hwecc(struct mtd_info *mtd, struct nand_chip *chip,
                                      const uint8_t *buf)
    {
            int i, eccsize = chip->ecc.size;
            int eccbytes = chip->ecc.bytes;
            int eccsteps = chip->ecc.steps;
            uint8_t *ecc_calc = chip->buffers->ecccalc;
            const uint8_t *p = buf;
            uint32_t *eccpos = chip->ecc.layout->eccpos;
    
            for (i = 0; eccsteps; eccsteps--, i += eccbytes, p += eccsize) {
                    chip->ecc.hwctl(mtd, NAND_ECC_WRITE);
                    chip->write_buf(mtd, p, eccsize);
                    chip->ecc.calculate(mtd, p, &ecc_calc[i]);
            }
    
            for (i = 0; i < chip->ecc.total; i++)
                    chip->oob_poi[eccpos[i]] = ecc_calc[i]; eccpos是干这个用的
    
            chip->write_buf(mtd, chip->oob_poi, mtd->oobsize);
    }

