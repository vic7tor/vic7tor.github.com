---
layout: post
title: "linux epoll"
description: ""
category: 
tags: [epoll linux 休眠]
---
{% include JB/setup %}
#用户态编程

函数信息来自于man，更详细的参见man了。

##epoll_event

    typedef union epoll_data 
    { 
      void *ptr; 
      int fd; 
      uint32_t u32; 
      uint64_t u64; 
    } epoll_data_t; 
 
    struct epoll_event 
   { 
      uint32_t events;      /* Epoll events */ 
      epoll_data_t data;    /* User data variable */ 
   } __attribute__ ((__packed__)); 

这是glibc里定义的结构体。

linux内核的是：

    struct epoll_event {
        __u32 events;
        __u64 data;
    } EPOLL_PACKED;

##epoll_create

       int epoll_create(int size);
       int epoll_create1(int flags);

size是监视多少个文件描述符。

返回值也是一个文件描述符。

##epoll_ctl

    int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);

op为EPOLL_CTL_ADD、EPOLL_CTL_MOD、EPOLL_CTL_DEL

epoll_event的events用来描述关心什么事件：EPOLLIN、EPOLLOUT、EPOLLRDHUP...

在epfd上添加、修改、删除fd

##epoll_wait

    int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);

等待epfd上面注册的文件描述符发生事件。

#内核实现

fs/eventpoll.c

##epoll_ctl

    SYSCALL_DEFINE4(epoll_ctl, int, epfd, int, op, int, fd,
                struct epoll_event __user *, event)

    epoll_ctl-->ep_insert-->f_op->poll

file_operations的poll调用poll_wait传入的wait_queue_head_t，在其他地方唤醒这个wait_queue后，epoll_ctl实现的其它机制就会唤醒epoll_wait了。

##epoll_wait

    epoll_wait->ep_poll(会在这里面休眠，由ep_insert设置的机制唤醒)

说下linux休眠的机制，在ep_poll里面，init_waitqueue_entry初始化一个wait_queue_t，其第二个参数是task_struct，有task_struct在在waitqueue上唤醒时，为什么进程会醒来了。

epoll_wait的休眠唤醒后，当有事件时就是调用ep_send_events向用户态传递事件了。

事件怎么获得呢？ep_send_events里调用ep_scan_ready_list。

ep_scan_ready_list的参数ep_send_events_proc。

ep_send_events_proc里有一句：

    revents = epi->ffd.file->f_op->poll(epi->ffd.file, NULL)

又重新调用一下file_operations的poll函数，但是，poll_table是NULL，poll里调用poll_wait不会起作用。

LDD3里scull_p_poll里的：

    poll_wait(filp, &dev->inq, wait);
    ...
    if (dev->rp != dev->wp)
	mask |= POLLIN | POLLRDNORM;

这个if语句是必要的，ep_send_events_proc里调用的file_operations的poll才会有用。


