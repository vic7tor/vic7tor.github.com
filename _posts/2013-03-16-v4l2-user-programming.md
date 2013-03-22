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

    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    fmt.fmt.pix.width = 640;
    fmt.fmt.pix.height = 480;
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_MJPEG;
    ioctl(fd, VIDIOC_S_FMT, &fmt)

mplane的参数：

        memset(&fmt, 0x00, sizeof(struct v4l2_format));
        fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
        fmt.fmt.pix_mp.width = 640;
        fmt.fmt.pix_mp.height = 480;
        fmt.fmt.pix_mp.field = V4L2_FIELD_NONE;
        fmt.fmt.pix_mp.pixelformat = V4L2_PIX_FMT_NV21;
        fmt.fmt.pix_mp.num_planes = 2;
        ioctl(fd, VIDIOC_S_FMT, &fmt);

只要参数设置正确，G_FMT的时候肯定能打印出来的。

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

    index
    type
    memory
    union {
                __u32           offset;
                unsigned long   userptr;
                struct v4l2_plane *planes;
    } m;
    length

index指定buffer的序号。

type必须指定的。V4L2_BUF_TYPE_VIDEO_CAPTURE、V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE。

memory内存类型。V4L2_MEMORY_MMAP、V4L2_MEMORY_USERPTR。

m联合体，当type为V4L2_MEMORY_MMAP时，offset有意义。当不是type不是multiplane时，同时memory是V4L2_MEMORY_USERPTR，userptr是有效的。当type是multiplane时，memory为V4L2_MEMORY_USERPTR或V4L2_MEMORY_MMAP，此时planes有效，同时length指定planes有几个有效数据。planes成员怎么起作用(V4L2_MEMORY_USERPTR、V4L2_MEMORY_MMAP)见下面。

planes是个指针，有次崩溃了，在内核里找不到，然后在logcat里看到了崩溃信息，就是因为这个指针没有赋值就用了。

上面对v4l2_buffer解释或许不应该放在这个位置，当V4L2_MEMORY_USERPTR时，那些userptr或者v4l2_plane里的指针都来自用户态已经分配的内存。所以，V4L2_MEMORY_USERPTR没有必要调用VIDIOC_QUERYBUF。只有当为V4L2_MEMORY_MMAP时有必要获得mmap的信息。

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

一般的好搞定。如果是mplane和userptr的话。

    struct v4l2_buffer buffer;
    memset(&buffer, 0, sizeof(buffer));
    buffer.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    buffer.memory = V4L2_MEMORY_USERPTR;
    buffer.index = idx;
    buffer.m.planes = &(stream->frame.frame[idx].planes[0]);
    buffer.length = stream->frame.frame[idx].num_planes;
    buffer.length是VIDIOC_S_FMT里面指定了的

    struct v4l2_plane {
        __u32                   bytesused;
        __u32                   length;
        union {
                __u32           mem_offset;
                unsigned long   userptr;
        } m;
        __u32                   data_offset;
        __u32                   reserved[11];
    };

入队时，那个buffer.m.planes也就是v4l2_plane的几个成员都要设置。

v4l2_plane的成员的设置。

    bytesused - VIDIOC_DQBUF有用的吧，已用的数量
    length - buffer大小，VIDIOC_QBUF时指定的
    m.mem_offset - V4L2_MEMORY_MMAP时候使用的。
    m.userptr - V4L2_MEMORY_USERPTR时用的，指定用户空间buffer的地址。
    data_offset - 通常为0，如果你要定制头部的话，可以设置这个。

###出队缓冲区 - VIDIOC_DQBUF

设置type和memory。index为返回值。

如果是mplane

    struct v4l2_buffer vb;
    struct v4l2_plane planes[VIDEO_MAX_PLANES];
    memset(&vb,  0,  sizeof(vb));
    vb.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    vb.memory = V4L2_MEMORY_USERPTR;
    vb.m.planes = &planes[0];
    vb.length = stream->fmt.fmt.pix_mp.num_planes;


##图像获取
当入队缓冲区后，VIDIOC_STREAMON就开始了捕获视频。

有的人用select判断有没有buffer可以读。有数据时，用VIDIOC_DQBUF出队，出队时不用指定是哪个缓冲区。buffer出队之后就开始读，出队之后就不会改变buffer内容了吧。

读完数据后再入队。

###VIDIOC_STREAMON

    #define VIDIOC_STREAMON          _IOW('V', 18, int)

网上说这个int是一个指向enum v4l2_buf_type的指针。

    type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ioctl(fd, VIDIOC_STREAMON, &type)

#v4l2编程实战
epoll是可以来检测是否有捕获到帧的。

就算只入队一个v4l2_buffer也是可以捕获的。

读/dev/videoX设备节点的会返回-1，但是读v4l2_buffer中大小的字节数，虽然返回-1但是读到的数据是正确的。

使用YUYV的格式时，老是搞不定，后面在网上找到一个程序，试了下，它的能工作。然后，用我的来试成功了，主要是网上程序把格式弄成MJPG。

这说明我那个程序没有问题，YUYV转换RGB时出了问题。

用mplay播放出来了抓了很多次的视频。

    mplayer -demuxer rawvideo -rawvideo w=640:h=480:format=yuy2 ../abc.yuyv

    mplayer -rawvideo format=help 显示所有支持的格式

#内核的ioctl实现。

