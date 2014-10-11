打印后关机：

[    2.439718].(2)[56:bat_thread_kthr][Power/BatMeter] <Rbat,VBAT> at 50 = <230,
3762>

开ＬＯＧ
drivers/power/battery_common.c ->  76 int Enable_BATDRV_LOG = BAT_LOG_FULL;

#1.bat_thread_kthread

BAT_thread->

force_get_tbat->battery_meter_ctrl->read_adc_v_bat_temp

platform/mt6582/kernel/drivers/power/battery_meter_hal.c
read_adc_v_bat_temp:
MTK_PCB_TBAT_FEATURE这个宏

platform/mt6582/kernel/drivers/thermal/Makefile:
MTK_PCB_BATTERY_SENSOR

在force_get_tbat中把FIXED_TBAT_25这个宏开了，就是force_get_tbat一直返回25度。这样就能开机了，看起来是初始化时这个温度决定了是否能开机。后面有东西可能读了这个温度值。

