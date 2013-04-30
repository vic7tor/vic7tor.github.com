---
layout: post
title: "kernel locking"
description: ""
category: 
tags: []
---
{% include JB/setup %}
本文内容来自PLKA。

#1.atomic

    typedef struct {
            int counter;
    } atomic_t;
    
    #ifdef CONFIG_64BIT
    typedef struct {
            long counter;
    } atomic64_t;
    #endif

atomic_read、atomic_set、atomic_add、atomic_add_return...一系列，arch/arm/include/asm/atomic.h或者include/asm-generic/atomic.h，根据头文件搜索顺序来决定。

在ARM上，SMP时的实现是用指令的，非SMP时raw_local_irq_save禁止中断。

SMP还有一种local_t的数据类型，允许在单个CPU上原子操作，提供了与atomic_t相同的一组函数。

#2.spinlock
`自旋锁用于保护短的代码段，同时它其实是一个循环，这样相比于信号量花的时间要少。`

spinlock主要还是为SMP而存在的，在非SMP的机子上，一是，spinlock主要目的是为了快速获得释放锁，在一个处理器上自旋等待另一个处理器上的代码释放锁。如果是非SMP的话，这种情况决不会有，所以没什么意义。

而相对于信号量(互斥体)，一个CPU已经获得，另一个CPU等待锁的话，等待的那个会进行休眠。下面说信号量，可以看到信号量里有一个waitqueue。

如果是马上就获得锁，信号量与spinlock没有什么差异。

    spinlock_t lock = SPIN_LOCK_UNLOCKED;
    spin_lock(&lock);
    /* 临界区 */
    spin_unlock(&lock);

spinlock还有spin_lock_irqsave用于禁止`本地`CPU中断，还有spin_lock_bh用于禁止softIRQ。

拥有自旋锁的代码不能休眠，因为拥有自旋锁时会禁止内核抢占，下面的函数是spin_lock最终调用的：

    static inline void __raw_spin_lock(raw_spinlock_t *lock)
    {       
        preempt_disable();
        spin_acquire(&lock->dep_map, 0, 0, _RET_IP_);
        LOCK_CONTENDED(lock, do_raw_spin_trylock, do_raw_spin_lock);
    }

这个函数调用了preempt_disable禁止抢占。为什么要禁止抢占?

##内核抢占

preempt_disable最终会引用到：

    current_thread_info()->preempt_count()。

如果是处于中断中的自旋锁也会有thread_info？

内核中有一份文档Documention/preempt-locking.txt来讲述内核可抢占情况下的锁的使用。

为什么要出现内核抢占？启用了内核抢占的内核能比普通内核更快速地用紧急进程来替代当前进程。

没有开启内核抢占时，有的用户态的进程进入的内核代码可能消耗了太多时间，导致一些重要的进程不能得到响应。开启了内核抢占，可以让内核代码被抢占而让这些重要进程得到响应。

据说，在中断处理和系统调用返回时都会检测是否进行内核抢占，如果此前是执行内核代码的话。

上面为了描述内核抢占的目的。以及什么情况下会被抢占。

自旋锁的实现为什么要禁上抢占在这里已经能解释了，如果拥有锁后，被抢占了，然后另一个进程被运行了，如果这个进程进入到内核后仍然是要获得这个锁，这样事情就发生了。就算没有造成重大危害起码也景响了性能。

#3.semaphore
linux-3.2.1的semaphore长这个样了，不得不感叹时间的力量。

    struct semaphore {
        raw_spinlock_t          lock;
        unsigned int            count;
        struct list_head        wait_list;
    };

down:

    void down(struct semaphore *sem)
    {
        unsigned long flags;

        raw_spin_lock_irqsave(&sem->lock, flags);
        if (likely(sem->count > 0))
                sem->count--;
        else
                __down(sem);
        raw_spin_unlock_irqrestore(&sem->lock, flags);
    }

以前的实现没见到过了，不过现在这里弄个spinlock是这样的，如果信号量可以马上获得，spin_lock马上释放，没什么事，这个spinlock就是为了保护count成员。

但是如果不能获得信号量，这个spinlock没有释放，那么up时也不能获得这个spinlock。不过当然不是这样的，在down调用的__down中，在调用schedule_timeout睡之前这个spinlock是释放了的。

信号量家族的其它函数down_interruptible、down_trylock。

down对应的函数就是up了。

#4.RCU
RCU也依靠softIRQ实现。

RCU性能良好(相对于其它同步机制)。这种机制应用于读操作多于写操作的情况下。不能休眠，softIRQ实现的。

这个机制的原理是，记录了指向该共享机制的所有读取者(因为读取时调用rcu_read_lock)，如要休改这结构时，先保存在一个副本中(这个副本要新分配一块内存)，等所有读取操作完成后，才将原指针替换为这个副本。

rcu读取操作：

    rcu_read_lock();
    p = rcu_dereference(ptr);
    if (!p) {
        awesome_funcion(p);
    }
    rcu_read_unlock();

rcu更新操作：

    struct super_duper *new_ptr = kmalloc(...);
    new_ptr->of = 42;
    rcu_assign_pointer(ptr, new_ptr);

具体实现还是要看看内核中的文档才行，Documentation/RCU/。这里就不研究了。

还有一种支持RCU的链表。

#5.内存屏障和优化屏障
编译器和处理器都会指令重排来优化执行效率。

下面几个函数阻止`编译器和处理器`对代码进行重排。smp版本在之前加smp前缀。

   mb()、rmb(),wmb()

它保证屏障之后发出的任何读或写操作在屏障之前都已完成。

还有一个阻止编译器对代码重排的函数：

    barrier()

上面说的重排，是相对于屏障之前与屏障之前来讲。所有位于屏障之前的代码还是可以重排的。

#6.读者/写者锁
有spinlock和信号量两个版本。

对于spinlock

    read_lock read_unlock
    write_lock write_unlock

内核保证读可以并发，但是只有一个写入。

#8.互斥体
这个实现里面同样有个等待队列。

1.经典互斥体

    struct mutex;
    mutex_init();
    mutex_lock();
    mutex_unlock();

2.实时互斥体

    struct rt_mutex;
    rt_mutex_xxx();

这个存在的意义是这样的，如果有A、B两个进程，A的优先级比B高，但是，在B获得互质体后，A必须等待B，这样A的优先级比B还要低了。如果不只两个进程，A就有可能等很久了。

实时互质体的实现就是，当优先级低的进程获得锁之后，提高这个进程的优先级。

#9.近似的per-CPU计数器
如果系统中安装有大量的CPU，计数器可能成为瓶颈。

这个应该很少用到。

#10.锁竞争与细粒度锁
多个数据结构，一个驱动或者一个子系统由一个锁保护的话，在内核某个部分需要获取锁的时候，这个锁可能已经被其它部分获得。这种情况下，会出现较多的锁竞争，这个锁会成为内核的一个hotspot。

为了避免这种情况，用多个锁来锁定不同的地方，以提高性能。

`但是，使用多个锁时会有死锁的潜在危险。`

如果发现锁竞争造成的性能瓶颈呢？

