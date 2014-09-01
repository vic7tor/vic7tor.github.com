#1.java版本选择

关于编译内核时使用的浮点，导致java版本需要选择对。EABI问题。

一共有三种：

gcc编译使用时的选择：

-mfloat-abi=hard -mfpu=vfp
-mfloat-abi=softfp -mfpu=vfp
-msoft-float

这个三个选项在java embedded的下载页面有描述。

android编译内核时的选项：

arm-eabi-gcc -Wp,-MD,kernel/.module.o.d  -nostdinc -isystem /home/build/msm8226-1.8/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7/bin/../lib/gcc/arm-eabi/4.7/include -I/home/build/msm8226-1.8/kernel/arch/arm/include -Iarch/arm/include/generated -Iinclude  -I/home/build/msm8226-1.8/kernel/include -include /home/build/msm8226-1.8/kernel/include/linux/kconfig.h  -I/home/build/msm8226-1.8/kernel/kernel -Ikernel -D__KERNEL__ -mlittle-endian   -I/home/build/msm8226-1.8/kernel/arch/arm/mach-msm/include -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -Werror-implicit-function-declaration -Wno-format-security -fno-delete-null-pointer-checks -Os -Wno-maybe-uninitialized -marm -fno-dwarf2-cfi-asm -mabi=aapcs-linux -mno-thumb-interwork -funwind-tables -D__LINUX_ARM_ARCH__=7 -march=armv7-a -msoft-float -Uarm -Wframe-larger-than=1024 -fno-stack-protector -Wno-unused-but-set-variable -fomit-frame-pointer -g -Wdeclaration-after-statement -Wno-pointer-sign -fno-strict-overflow -fconserve-stack -DCC_HAVE_ASM_GOTO    -D"KBUILD_STR(s)=#s" -D"KBUILD_BASENAME=KBUILD_STR(module)"  -D"KBUILD_MODNAME=KBUILD_STR(module)" -c -o kernel/.tmp_module.o /home/build/msm8226-1.8/kernel/kernel/module.c

所以是msoft-float。

#java 8

