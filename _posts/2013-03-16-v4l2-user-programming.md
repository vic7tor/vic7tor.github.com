---
layout: post
title: "v4l2 user programming"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#v4l2设备信息
##1.VIDIOC_QUERYCAP

struct v4l2_capability

有driver、card、bus_info、version这几个成员。

##2.VIDIOC_ENUM_FMT

struct v4l2_fmtdesc

这个结构中index、type两个成员都要设置。

index指定获取哪个的信息。

type为v4l2_buf_type类型设置信息的类型。v4l2_buf_type的更深理解见v4l2_format这个结构体的使用。

##3.VIDIOC_G_FMT,VIDIOC_S_FMT,VIDIOC_TRY_FMT

struct v4l2_format

根据type的值，union的内容不一样。

    struct v4l2_pix_format          pix;     /* V4L2_BUF_TYPE_VIDEO_CAPTURE */
    struct v4l2_pix_format_mplane   pix_mp;  /* V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE */
    struct v4l2_window              win;     /* V4L2_BUF_TYPE_VIDEO_OVERLAY */

v4l2_pix_format的pixelformat的生成见v4l2_fourcc。V4L2_PIX_FMT_XXX这样的宏。

#图像采集
如果没有pixformat需不需要设置？
##缓冲区管理
###1.申请缓冲区－VIDIOC_REQBUFS

    struct v4l2_requestbuffers {
        __u32                   count;
        enum v4l2_buf_type      type;
        enum v4l2_memory        memory;
        __u32                   reserved[2];
    };

    enum v4l2_memory {
        V4L2_MEMORY_MMAP             = 1,
        V4L2_MEMORY_USERPTR          = 2,
        V4L2_MEMORY_OVERLAY          = 3,
    };

v4l2_memory能用的就那几种类型。

V4L2_MEMORY_MMAP应该是在内核分区一块内存区，然后可以用mmap映射到用户空间。

V4L2_MEMORY_USERPTR这个不太清楚，猜测是内核不需要分区内存，驱动填冲用户态的内存。

申请buffer时，count、type、memory这几个值都要填充。

###2.获取VIDIOC_REQBUFS分配的缓冲区信息 － VIDIOC_QUERYBUF

struct v4l2_buffer

index、type、memory这三个值都需要设置？

在m成员中offset(文件中的偏移,打印了下这个值是0)是对应V4L2_MEMORY_MMAP，见v4l2_buffer上方注释。

length为buffer的大小。

###3.mmap

    void *mmap(void *addr, size_t length, int prot, int flags,
                  int fd, off_t offset)

addr指定映射到用户态的地址。length为映射的长度了，prot设置PROT_READ、PROT_WRITE、PROT_EXEC这样的权根。

flags有MAP_SHARED和MAP_PRIVATE这些还有其它的。

fd就不需要说了。

offset从哪里开始映射。v4l2_buffer.m.offset了。

###.入队缓冲区 - VIDIOC_QBUF

入队VIDIOC_QUERYBUF返回的v4l2_buffer就行了。

或者设置type、memory、index入队。

###出队缓冲区 - VIDIOC_DQBUF

设置type和memory。index为返回值。

##图像获取
当入队缓冲区后，VIDIOC_STREAMON就开始了捕获视频。

有的人用select判断有没有buffer可以读。有数据时，用VIDIOC_DQBUF出队，出队时不用指定是哪个缓冲区。buffer出队之后就开始读，出队之后就不会改变buffer内容了吧。

读完数据后再入队。

###VIDIOC_STREAMON

    #define VIDIOC_STREAMON          _IOW('V', 18, int)

网上说这个int是一个指向enum v4l2_buf_type的指针。

    type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ioctl(fd, VIDIOC_STREAMON, &type)

#内核的ioctl实现。

