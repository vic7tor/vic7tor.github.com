ramparse.py --vmlinux ~/msm8974/out/target/product/msm8974/obj/KERNEL_OBJ/vmlinux --ram-file DDRCS0.BIN 0x00000000 0x3FFFFFFF --ram-file DDRCS1.BIN 0x40000000 0x7FFFFFFF --ram-file MSGRAM.BIN 0xFC428000 0xFC42BFFF

--vmlinux是一定要指定的，关于ramparse运行时所有的问题都会输出到dmesg_TZ.txt。

还有需要指定gdb的路径，需要arm-none-linux-gnueabi-，安装Sourcery_G++_Lite吧。

完整命令：
ramparse.py --vmlinux ~/msm8974/out/target/product/msm8974/obj/KERNEL_OBJ/vmlinux --ram-file DDRCS0.BIN 0x00000000 0x3FFFFFFF --ram-file DDRCS1.BIN 0x40000000 0x7FFFFFFF --ram-file MSGRAM.BIN 0xFC428000 0xFC42BFFF -n ~/CodeSourcery/Sourcery_G++_Lite/bin/arm-none-linux-gnueabi-nm -g ~/CodeSourcery/Sourcery_G++_Lite/bin/arm-none-linux-gnueabi-gdb -d

-d 是显示dmesg这个dmesg会在追加到dmesg_TZ.txt

https://www.codeaurora.org/patches/quic/la/

ramparse从上面网址下载。

ramdump是机器重启后用打开QPST，QPST自动抓的。

