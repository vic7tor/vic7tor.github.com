alps/mediatek/platform/mt6582/lk/dsi_drv.c

引用了一下disp_wait_reg_update，据说原来卡在这里死机。

disp_wait_reg_update定义在：
bootable/bootloader/lk/platform/mediatek/mt6582/lk/ddp_path.c

lk的platform/mediatek链接到根目录的mediatek/platform
所以在bootable/bootloader/lk/就是完整的源代码了。

头文件：platform/mediatek/mt6582/lk/include/
方便查看各种导出的函数。

#lk的配置文件
看AndroidBoot.mk的配置文件，lk的配置文件就是Android编译时TARGET_PRODUCT=flyaud82_we_kk指定的，在lk的project目录下面有这个文件啦。

#WITH_LIB_CONSOLE
这个宏是编译时生成的，在makefile中有相关代码，所有的DEFINES都弄到这个宏里来。

146 # add some automatic configuration defines
147 DEFINES += \
148         BOARD=$(PROJECT) \
149         PROJECT_$(PROJECT)=1 \
150         TARGET_$(TARGET)=1 \
151         PLATFORM_$(PLATFORM)=1 \
152         ARCH_$(ARCH)=1 \
153         $(addsuffix =1,$(addprefix WITH_,$(ALLMODULES)))

WITH_LIB_CONSOLE这个宏应该是由app/shell/rules.mk这一句产生的

  3 MODULES += \
  4         lib/console

在lk里MODULES会引起lib/console上面的这个来编译么。

#LCM系统流程
platform/mediatek/mt6582/lk/disp_drv_dsi.c

DISP_GetDriverDSI

platform/mediatek/mt6582/lk/disp_drv.c
disp_drv_init_context -> DISP_GetDriverDSI

DISP_Init有调用。

{
DSI_PowerOn
}

init_dsi->DSI_PowerOn
##
DISP_DetectDevice->disp_drv_get_lcm_driver


disp_drv_get_lcm_driver打印：

[LCM Auto Detect], we have 1 lcm drivers built in                               
[LCM Auto Detect], try to find driver for [unknown]                             
[LCM Specified] [cpt_clap070wp03xg_sn65dsi83]

mt_disp_init->DISP_Init

platform_early_init -> mt_disp_init

看到platform_early_init还是要照LK的流程来一遍才好。

platform/mediatek/mt6582/lk/platform.c中。

从platform_early_init可以看出printf是打印语句。

DISP_Init前面的log是platform_early_init中mt_disp_get_vram_size打出来的。
mt_disp_get_vram_size

第一遍报的DISP/ Polling DSI read ready timeout!!!是DSI_dcs_read_lcm_reg_v2这个函数引起的，在disp_drv_get_lcm_driver调用。

#mt_disp_init
mt_disp_parse_dfo_setting，我们的机子这个是没有设置的。

导致了后面的DISP_Change_LCM_Resolution报错。

后面调用DISP_Init这个函数，DISP_Init调用了disp_drv->init

这个错误的dfo resolution，最后在dsi_init，也就是disp_drv->init使用了。

disp_drv是在disp_drv_init_context中DISP_GetDriverDSI。

其实在DISP_Change_LCM_Resolution是没有把错误的分bian率使用的。

disp_drv->init非常重要，这玩意调用的_dsi_init_vdo_mode调用了lcm的init_power和init函数。

#mt_disp_update

前面DSI83没有初始化，在这里那个disp_wait_reg_update或许与DSI83没有初始化有关系，因为MIPI也可以从屏读数据嘛，MIPI应该是双向的，然后这个是在屏有反应的情况下这个DSI_RegUpdate才会成功？

#lk中寄存器的设置

在LK代码中只有DSI_BackupRegisters和DSI_RestoreRegsiter感觉，这些配置都是来自preloader。

init_dsi中调用的DSI_PS_Control有设置这个参数诶。

