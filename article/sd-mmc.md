#1.基本
SD、MMC、EMMC用的总线都差不多，电源、地CLK、CMD、DAT[n]。EMMC有8位数据线。

其实命令和命令的回复都是在数据线上传送。

##SD MMC规范的差异
SD的在sdcard.org上面有。

MMC的非EMMC为JESD84-B42，JEDEC的。

CMD有很多条，还有SD规范中的ACMD，在MMC的规范中是没有提到的。

还有一些SD CARD中的命令的含义在MMC中的是不一样的。比如CMD8在MMC中为MMC_CMD_SEND_EXT_CSD，但是在SDCARD中就是SD_CMD_SEND_IF_COND。

还有一些行为不一样，如CMD3，在SDCARD中，SD_CMD_SEND_RELATIVE_ADDR这个是让卡发它的RCA，而在MMC中MMC_CMD_SET_RELATIVE_ADDR，这个是设置。

#2.命令
命令在CMD信号线上传送，有一个Start bit，然后是方向，。。。，参数。

不是所有的命令都有参数，但是仍需要传送这些字节，在相关文档中称为Stuff bit，就是可以为任意值啦。

CMD有50来个吧。R有有限的几个。

还有CMD55后面的ACMD会回复一个R1，R1中的第5位，表示下面的命令将是ACMD，或者，这个命令以ACMD执行完成。

CMD55只能跟一个ACMD，想执行别的ACMD需要再来一个CMD55。

#寄存器

sdcard的命令及寄存器在Physical Layer Simplified Specification中有详细定义。

SD卡寄存器，MMC的多了一个EXT_CSD少了SCR和SD_CARD_STATUS:

OCR Register (32 bits)
CID Register (128 bits)
CSD Register (128 bits)
RCA Register (16 bits)
DSR Register (16 bits, optional)
SCR Register (64 bits)
SD_CARD_STATUS (512 bits)

OCR - operation conditions register (OCR) stores the VDD voltage profile of the card and the access mode indication.

CID - The Card IDentification (CID) register is 128 bits wide. It contains the card identification information used during the card identification phase

CSD - Card-Specific Data (CSD) register provides information on how to access the card contents. The CSD defines the data format, error correction type, maximum data access time, data transfer speed, whether the DSR register can be used etc. 

RCA - relative card address

SCR - 这个寄存器是在数据线上传回的。

u-boot读SCR寄存器的代码：

        cmd.cmdidx = SD_CMD_APP_SEND_SCR;
        cmd.resp_type = MMC_RSP_R1;
        cmd.cmdarg = 0;

        timeout = 3;

retry_scr:
        data.dest = (char *)scr;
        data.blocksize = 8;
        data.blocks = 1;
        data.flags = MMC_DATA_READ;

        err = mmc_send_cmd(mmc, &cmd, &data);

mmc_send_cmd有一个data参数，这个就是读的data.还有flags为MMC_DATA_READ。blocks指定读多少块，blocksize是块的大小，这里是1*8字节，一共64位，是SCR寄存器的大小。



#3.初始化流程
这个可以参考SDCARD.org的SDIO spec.

一边初始化卡，一边初始化寄存器。

CMD6判断SDCARD是否有HS支持。见scard phy spec的4.3.10 Switch Function Command。

#4.SD HOST CONTROL
sdcard.org也有一份定义host control的文档，定义一些寄存器的。一些控制器的寄存器可能是这个规范的。

#应用
##1.HS
有一个卡在执行CMD16时总是失败。原因就是这个卡不支持HS模式。

在u-boot的mmc_startup函数中，ACMD6后，调用了mmc_set_bus_width，这个函数设置了寄存器中的HS位为高，代码缺陷引起的。那个函数实现是时钟和SDHCI_QUIRK_NO_HISPD_BIT可以决定寄存器中的HS位。

High Speed Enable
This bit is optional. Before setting this bit, the Host Driver shall check the High
Speed Support in the Capabilities register. If this bit is set to 0 (default), the Host
Controller outputs CMD line and DAT lines at the falling edge of the SD Clock (up to
25MHz). If this bit is set to 1, the Host Controller outputs CMD line and DAT lines at
the rising edge of the SD Clock (up to 50MHz).

SCR寄存器中的可以判断卡是不是HS？这个从SCR中定义的SCARD标准版本看出。见CMD6。

        err = sd_switch(mmc, SD_SWITCH_SWITCH, 0, 1, (u8 *)switch_status);

        if (err)
                return err;

        if ((__be32_to_cpu(switch_status[4]) & 0x0f000000) == 0x01000000)
                mmc->card_caps |= MMC_MODE_HS;
