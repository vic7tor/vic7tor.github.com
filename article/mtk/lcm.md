内核的：mediatek/custom/common/kernel/lcm/

lk也在mediatek/custom/common/这个目录下的里。

mediatek/custom/common/kernel/lcm/mt65xx_lcm_list.c -> lcm_driver_list

platform/mt6582/kernel/drivers/video/disp_hal.c的disphal_get_lcm_driver引用lcm_driver_list

mediatek/platform/common/kernel/drivers/video/disp_drv.c的 DISP_SelectDeviceBoot DISP_SelectDevice DISP_DetectDevice

disp_get_lcm_name_boot:

BOOL disp_get_lcm_name_boot(char *cmdline)
{
...
return DISP_SelectDeviceBoot(NULL);
...
}

mtkfb_probe->DISP_Init

到此，MTK的显示系统分为DISP_IF_DRIVER和LCM_DRIVER都实现在platform/common/kernel/drivers/video/disp_drv.c中了

lcm_drv->init()是在fbconfig_rest_lcm_setting_prepare中调用的。

fbconfig_ioctl->fbconfig_reset_lcm_setting->fbconfig_rest_lcm_setting_prepare
0.0这个fbconfig最终是一个debugfs中的文件。

看dsi83驱动的代码：mediatek/custom/common/kernel/lcm/cpt_clap070wp03xg_sn65dsi83/cpt_clap070wp03xg_sn65dsi83.c他的lcm_init在内核中只设置了一个参数，这说明，这玩意只在lk中初始化一遍寄存器。

dsi if的驱动实现在：platform/mt6582/kernel/drivers/video/disp_drv_dsi.c
