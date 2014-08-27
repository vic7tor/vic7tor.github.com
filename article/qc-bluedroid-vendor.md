#1.vendor初始化
libbt-vendor/src/bt_vendor_qcom.c

init函数调用get_bt_soc_type：

使用qcom.bluetooth.soc这个属性来区分。

对于ath3k和rome这两个平台，这两个会用到hci_uart.c这个文件。

对于msm8974和msm8x28的，这个属性没有设置，就是使用smd的了。

#2.op

op是

##1.BT_VND_OP_POWER_CTRL
使用bluetooth.hciattach这个属性来控制电源。


##2.BT_VND_OP_USERIAL_OPEN
对于BT_SOC_DEFAULT，调用bt_hci_init_transport来打开

arch/arm/mach-msm/smd_tty.c


