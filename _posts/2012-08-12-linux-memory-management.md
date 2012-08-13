---
layout: post
title: "linux memory management"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.页表管理
传统内核是4级页表：PGD、PUD、PMD、PTE，在arm上是两级页表。在arm中，`<asm/pgtable.h>`包含了`<asm-generic/4level_fixup.h>`，在`4level_fixup.h`中，那些操作PUD、PMD的操作都成了空操作。

看一个函数吧，ioremap_page_range，把一个物理地址映射到虚拟地址(是哪部分还不知道)

相关的东西：

1.`mm_struct`定义在`linux/mm_types.h`中。

2.pgd_offset_k

    #define pgd_offset_k(addr)      pgd_offset(&init_mm, addr)

3.init_mm的初始化

在`mm/init-mm.c`中：

    struct mm_struct init_mm = {
            .mm_rb          = RB_ROOT,
            .pgd            = swapper_pg_dir,
            .mm_users       = ATOMIC_INIT(2),
            .mm_count       = ATOMIC_INIT(1),
            .mmap_sem       = __RWSEM_INITIALIZER(init_mm.mmap_sem),
            .page_table_lock =  __SPIN_LOCK_UNLOCKED(init_mm.page_table_lock),
            .mmlist         = LIST_HEAD_INIT(init_mm.mmlist),
            INIT_MM_CONTEXT(init_mm)
    };

pgd不需要动内分配内存，应该是初始化的时候全部都设置好了的。

pte分配需要调用get_free_page函数。不知道在early_init能不能用。

暂时不写了，其它代内容见PLKA书上吧。
