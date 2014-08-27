---
layout: post
title: "linux emmc"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#0.
Secure Digital Host Controller Interface (SDHCI)

SD/MMC

高通在mmc/host中有这两种驱动。

sdhci-msm.c － qcom,sdhci-msm

msm_sdcc.c － qcom,msm-sdcc

#1.linux mmc core
drivers/mmc/core

##1.mmc_host

##2.mmc_host_ops


##3.mmc_alloc_host


##4.mmc_add_host

##5.mmc_start_host

	void mmc_start_host(struct mmc_host *host)
	{
        mmc_power_off(host);
        mmc_detect_change(host, 0);
	}

mmc_detect_change中使mmc_rescan

##6.mmc_rescan

调用mmc_rescan_try_freq，这个函数检测host上挂载的卡：

        /* Order is important: probe SDIO, then SD, then MMC */
        if (!mmc_attach_sdio(host))
                return 0;
        if (!mmc_attach_sd(host))
                return 0;
        if (!mmc_attach_mmc(host))
                return 0;

###mmc_attach_mmc

###mmc_select_bus_speed

###hs400 hs200选择
mmc_init_card:

                err = mmc_get_ext_csd(card, &ext_csd);
                if (err)
                        goto free_card;
                card->cached_ext_csd = ext_csd;
                err = mmc_read_ext_csd(card, ext_csd);

mmc_read_ext_csd:

	mmc_select_card_type {
		card->ext_csd.card_type = card_type; card_type来自于ext_csd寄存器
	}
	mmc_part_add

##5.mmc_add_card
在2.0上的打印出来是：

mmc0: new HS200 MMC card at address 0001

在3.0上的打印出来是：

mmc0: new HS400 MMC card at address 0001

#2.sdhci
##1.sdhci_host
这玩意是对mmc_host的封装

sdhci_add_host


