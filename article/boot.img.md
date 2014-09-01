boot.img生成命令：

ut/host/linux-x86/bin/mkbootimg  --kernel out/target/product/msm8226/kernel --ramdisk out/target/product/msm8226/ramdisk.img --cmdline "console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37" --base 0x00000000 --pagesize 2048 --ramdisk_offset 0x02000000 --tags_offset 0x01E00000 --dt out/target/product/msm8226/dt.img  --output out/target/product/msm8226/boot.img

dt.img生成：
out/host/linux-x86/bin/dtbTool -o out/target/product/msm8226/dt.img -s 2048 -p out/target/product/msm8226/obj/KERNEL_OBJ/scripts/dtc/ out/target/product/msm8226/obj/KERNEL_OBJ/arch/arm/boot/

ramdisk生成：

ut/host/linux-x86/bin/mkbootfs out/target/product/msm8226/recovery/root | out/host/linux-x86/bin/minigzip > out/target/product/msm8226/ramdisk.img
