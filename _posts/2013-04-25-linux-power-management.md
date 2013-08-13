---
layout: post
title: "linux power management"
description: ""
category: 
tags: [workqueue]
---
{% include JB/setup %}
#1.
kernel/power/

内核中的文档：Documentation/power/


##1.kernel/power/main.c
这里实现用户态的接口，有一份文档在Documentation/power/interface.txt

    core_initcall(pm_init);

pm_init:

     power_kobj = kobject_create_and_add("power", NULL);

这个就是sysfs的power目录。

state文件：

    power_attr(state);
    
state_store就是处理往state文件写入信息的函数。

写入disk时交给hibernate()处理，在kernel/power/hibernate.c中。

如果不是hibernate，那就是suspend的处理了。

earlysuspend一共有on,standby,mem几种状态。非earlysuspend没有on这个状态。

earlysuspend的实现在kernel/power/earlysuspend.c中。early_suspend同样会休眠到内存。在request_suspend_state最终会跑到wake_unlock的函数，这个函数有个suspend的work_queue最终也会调用pm_suspend。

##1.earlysuspend的实现
看kernel/power/earlysuspend.c，earlysuspend是一种非常简单的机制。搞不明白为什么叫earlysuspend。

    struct early_suspend {
    #ifdef CONFIG_HAS_EARLYSUSPEND
        struct list_head link;
        int level;
        void (*suspend)(struct early_suspend *h);
        void (*resume)(struct early_suspend *h);
    #endif
    };

register_early_suspend就把early_suspend放到一个根据level排序的list里面。

如果支持early_suspend的话state_store就调用到这个文件中实现的request_suspend_state。

在request_suspend_state里用了workqueue机制。用它的原因是，能让写入sysfs state文件的操作马上返回。workqueue运行于进程上下文。

然后就是遍历链表，执行early_suspend的suspend函数指针。

##2.earlysuspend实例
drivers/input/misc/ltr502.c

    ltr502->early_suspend.level = EARLY_SUSPEND_LEVEL_BLANK_SCREEN;
    ltr502->early_suspend.suspend = ltr502_early_suspend;
    ltr502->early_suspend.resume = ltr502_late_resume;
    register_early_suspend(&ltr502->early_suspend);

在ltr502_early_suspend让设备进入低功耗模式了。

#2.suspend实现
在kernel/power/suspend.c这个是PC机用的吧，实现起来就复杂了很多。earlysuspend就那么样就完了，估计这个还会和driver/base/power有关系。

公司那个一个按键就让linux休眠其实就是使用的这个机制，因为earlysuspend只支持简单的suspend和resume，让部分设备进入休眠状态，不会像suspend把cpu关掉只留下内存的供电。公司做的驱动没弄到内核里面，没有源代码，通过内核日志可以确定是调用pm_suspend来进行休眠的。

##1.enter_state
pm_suspend直接调用enter_state。

enter_state:

    suspend_sys_sync_queue();
    suspend_prepare();
    pm_restrict_gfp_mask();

    suspend_devices_and_enter(state);

    suspend_finish();

suspend_sys_sync把文件系统的缓存写入磁盘吧。

suspend_prepare里面调用了suspend_freeze_processes。

`suspend_devices_and_enter就进入休眠，唤醒时就会从这个函数返回。`

suspend_finish唤醒时做的事。

##2.suspend_devices_and_enter
suspend_devices_and_enter:

    suspend_ops->begin(state);
    dpm_suspend_start(PMSG_SUSPEND);

    suspend_enter(state);

    dpm_resume_end(PMSG_RESUME);
    suspend_ops->end();

suspend_end进入休眠，唤醒时会从这个函数返回。

dpm_suspend_start内核里面用的就是这个动态电源管理来控制设备的休眠了。

###dpm
内核中文档：Documentation/power/runtime_pm.txt

##3.suspend_enter

这个函数里还有dpm

最终这一句让CPU进入了低功耗模式：

    suspend_ops->enter(state);

这个函数返回就是休眠的唤醒。它后面就是唤醒的代码了。

###suspend_ops

    static const struct platform_suspend_ops *suspend_ops;

这个是调用suspend_set_ops设置的。

cs f c suspend_set_ops的引用可以看到很多东西。

#drivers/power/
drivers/power并不是电源管理的部分，而是power supply class。
