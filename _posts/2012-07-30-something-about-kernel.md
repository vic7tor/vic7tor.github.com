---
layout: post
title: "内核的一些东西"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.IS_ERR
这个宏定义`<linux/err.h>`中，当返回值是一个指针时，用来检测是否发生错误。

它的原理是这样的：当函数返回值是一个指针时，发生了错误，直接返回一个负的错误码就行。然后这个宏是这样判断`(x) >= (unsigned long)-MAX_ERRNO` MAX_ERRNO为4095，负的错误码转为无符号数的范围在0xFFFFF001-0xFFFFFFFF。IS_ERR就判断这个指针的值是否在这个范围。在这个地址空间内核应该没放什么东西吧。

这或许就是为什么内核需要返回负的错误码的原因，对于返回指针的函数就有用了。

#2.print_hex_dump

    void print_hex_dump(const char *level, const char *prefix_str,
                           int prefix_type, int rowsize, int groupsize,
                           const void *buf, size_t len, bool ascii);
    level - KERN_INFO KERN_DEBUG这样的
    prefix_str - 前缀输出，如果数据有多行，做为每一个的前缀输出。
    prefix_type - DUMP_PREFIX_NONE,DUMP_PREFIX_ADDRESS,DUMP_PREFIX_OFFSET
    rowsize - 一行有多大
    groupsize - 多少个字节组成一组
    buf - dump这玩意
    len - 长度
    ascii - 不懂

#3.request_irq的dev_id参数
这个参数还用来识别共享中断时，不同的action。见free_irq的实现。

#内核参数loglevel
这个可以控制printk，小于这个级别的都可以在用户态上显示。

#is not clean, please run make mrproper

    prepare3: include/config/kernel.release
    ifneq ($(KBUILD_SRC),)
        @$(kecho) '  Using $(srctree) as source for kernel'
        $(Q)if [ -f $(srctree)/.config -o -d $(srctree)/include/config ]; then \
                echo "  $(srctree) is not clean, please run 'make mrproper'";\
                echo "  in the '$(srctree)' directory.";\
                /bin/false; \
        fi;
    endif

上面代码中KBUILD_SRC不为空就会执行下面那些，当在命令行编译内核时(编译内核才会做这些检查)，使用了O=xxx参数，那么KBUILD_SRC就不为空。

AndroidKernel.mk内核编译文件，一般在内核源代码树中。

#内核的clean
    ###
    # Cleaning is done on three levels.
    # make clean     Delete most generated files
    #                Leave enough to build external modules
    # make mrproper  Delete the current configuration, and all generated files
    # make distclean Remove editor backup files, patch leftover files and the like
    
    # Directories & files removed with 'make clean'
    CLEAN_DIRS  += $(MODVERDIR)
    CLEAN_FILES +=  vmlinux System.map \
                    .tmp_kallsyms* .tmp_version .tmp_vmlinux* .tmp_System.map
    
    # Directories & files removed with 'make mrproper'
    MRPROPER_DIRS  += include/config usr/include include/generated          \
                      arch/*/include/generated
    MRPROPER_FILES += .config .config.old .version .old_version             \
                      include/linux/version.h                               \
                      Module.symvers tags TAGS cscope* GPATH GTAGS GRTAGS GSYMS
