arm/arm/Makefile:

zImage-dtb: vmlinux scripts
        $(Q)$(MAKE) $(build)=$(boot) MACHINE=$(MACHINE) $(boot)/$@

CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE=y
8974的开了这个宏。

arch/arm/boot/Makefile:

 55 $(obj)/Image: vmlinux FORCE
 56         $(call if_changed,objcopy)
 57         @echo '  Kernel: $@ is ready'
 58 
 59 $(obj)/compressed/vmlinux: $(obj)/Image FORCE
 60         $(Q)$(MAKE) $(build)=$(obj)/compressed $@
 61 
 62 $(obj)/zImage:  $(obj)/compressed/vmlinux FORCE
 63         $(call if_changed,objcopy)
 64         @echo '  Kernel: $@ is ready'
 65 
 66 $(obj)/zImage-dtb:      $(obj)/zImage $(DTB_OBJS) FORCE
 67         $(call if_changed,cat)
 68         @echo '  Kernel: $@ is ready'

Image是从vmlinux objcopy来的，关于objcopy

##if_changed
220 if_changed = $(if $(strip $(any-prereq) $(arg-check)),                           \
221         @set -e;                                                                 \
222         $(echo-cmd) $(cmd_$(1));                                                 \
223         echo 'cmd_$@ := $(make-cmd)' > $(dot-target).cmd)

arch/arm/boot/.Image.cmd这个文件的内容是：

  1 cmd_arch/arm/boot/Image := arm-eabi-objcopy -O binary -R .comment -S  vmlinu    x arch/arm/boot/Image

cmd_objcopy来自scripts/Makefile.lib这个文件的232行。

看arch/arm/boot/compressed/.piggy.gzip.o.cmd:

这个文件是编译arch/arm/boot/compressed/piggy.gzip.S，这个文件是在源代码目录中的啦。

内容是：
        .section .piggydata,#alloc
        .globl  input_data
input_data:
        .incbin "arch/arm/boot/compressed/piggy.gzip"
        .globl  input_data_end
input_data_end:

有input_data和input_data_end就可以定位压缩了的数据了。

#.cmd文件
生成：

scripts/Kbuild.include中的make-cmd


引用：

scripts/Makefile.build：

targets := $(wildcard $(sort $(targets)))
cmd_files := $(wildcard $(foreach f,$(targets),$(dir $(f)).$(notdir $(f)).cmd))
