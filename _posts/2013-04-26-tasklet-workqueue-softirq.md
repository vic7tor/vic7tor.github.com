---
layout: post
title: "tasklet workqueue softirq"
description: ""
category: 
tags: []
---
{% include JB/setup %}
在LDD3中用延时执行来描述这些东西，可能最大的用途是用作中断的底半部，当然也有其它，像earlysuspend中的实现一样，为了让用户态的写入马上退出，用一个workqueue来在另外的上下文来执行suspend操作。

1.延时执行 2.使当前上下文快速结束，让花很多时间的任务在另外上下文运行

#1.综述
softirq和tasklet运行于原子上下文，关于什么是原子上下文，后面将有文章详述。处于原子上下文的不能休眠。workqueue处于进程上下文可以休眠。

#2.tasklet

    声明
    tasklet_func(unsigned long data);
    DECLARE_TASKLET(tasklet, tasklet_func, data);

    调度
    tasklet_schedule(&tasklet);

#3.workqueue

    struct work_struct wq;
    void wq_func(struct work_struct *work); 可以用container_of传递数据
    INIT_WORK(&wq, wq_func);

    schedule_work(&wq);

上面是向内默认队列提交任务：

    int schedule_work(struct work_struct *work)
    {
        return queue_work(system_wq, work); 
    }

还有一种就是create_workqueue创建一个workqueue然后queue_work。

#4.softirq
`softirq是非常重要的一种机制啊。见后面使用softirq的内核机制。`

tasklet与softirq密不可分，tasklet就是用softirq实现的。

##1.ksoftirqd

include/linux/interrupt.h:

    DECLARE_PER_CPU(struct task_struct *, ksoftirqd);
    这只是声明。。。

kernel/softirq.c：

    DEFINE_PER_CPU(struct task_struct *, ksoftirqd);

##2.do_softirq与invoke_softirq

do_softirq最终是执行softirq的处理函数的，有人说softirq是在原子上下文执行的，不能休眼。

`说softirq是在原子上下文执行的原因是，do_softirq调用了local_irq_save。do_softirq最终是执行softirq的中断处理函数的。休眠了的话就不会调用local_irq_restore来恢复中断了。`

invoke_softirq的实现如果没有定义CONFIG_IRQ_FORCED_THREADING它是唤醒ksoftirqd这个内核线程。

##3.使用softirq的机制
kernel/softirq.c：

    char *softirq_to_name[NR_SOFTIRQS] = {
        "HI", "TIMER", "NET_TX", "NET_RX", "BLOCK", "BLOCK_IOPOLL",
        "TASKLET", "SCHED", "HRTIMER", "RCU"
    };

这么看来softirq是非常重要的啊。
