---
layout: post
title: "v4l2 qcamera app"
description: ""
category: 
tags: []
---
{% include JB/setup %}
相比网上那简单的摄像头实现。高通的实现多了很多其它的东西。先是追到mplane，然后看到它用/dev/下面那些节点实现的共享内存实现的userptr。

今天把HAL改名，然后，摄像头还能用。。。然后通过logcat里打出的相机相关的函数名，找到了vendor/qcom/proprietary/mm-camera的实现。看到有server字眼，这个没有用到HAL的架构了。

然后，找到了v4l2-qcamera-app这个东东。研究它就可以知道怎么用高通的v4l2了。

#userptr
看了下这个，mplane的userptr填的是一个fd。

    int  pmem_fd = open("/dev/pmem_adsp", O_RDWR|O_SYNC);
    ret = mmap(NULL,
        size,
        PROT_READ  | PROT_WRITE,
        MAP_SHARED,
        pmem_fd,
        0);

pmem_fd就会作为userptr的值。`看到这里userptr只是一个可以用来存值的东西，并不一定如其名字所寓示的那样只能做为指针。可以是用户态的指针；也可以是这样的一个fd，然后，在内核里，使用相关机制，与用户态进行共享内存。

/dev/pmem_adsp是Android PMEM的结点。

当然，高通的用的是一个叫ION的与PMEM类似的东西吧。

#MPLANE到底什么意思

    struct v4l2_frame_buffer {
      struct v4l2_buffer buffer;
      unsigned long addr[VIDEO_MAX_PLANES];
      uint32_t size;
      struct ion_allocation_data ion_alloc[VIDEO_MAX_PLANES];
      struct ion_fd_data fd_data[VIDEO_MAX_PLANES];
    };

    struct v4l2_frame_buffer *in_frames;
    if (bufType == V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE) {
        if (usr_prev_format == CAMERA_YUV_420_YV12)
          in_frames[cnt].buffer.length = 3; //Y, Cb, Cr.
        else
          in_frames[cnt].buffer.length = 2; //Y, CbCr.
        in_frames[cnt].buffer.m.planes = (struct v4l2_plane *)
          malloc(in_frames[cnt].buffer.length * sizeof(struct v4l2_plane));
    }

plane用来存不同的分量了。

#mplanes时每个plane的大小的获得。

      in_frames[cnt].buffer.type = bufType;
      in_frames[cnt].buffer.memory= mem_type;
      in_frames[cnt].buffer.index = cnt;

      if (bufType == V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE) {
        if (usr_prev_format == CAMERA_YUV_420_YV12)
          in_frames[cnt].buffer.length = 3; //Y, Cb, Cr.
        else
          in_frames[cnt].buffer.length = 2; //Y, CbCr.
        in_frames[cnt].buffer.m.planes = (struct v4l2_plane *)
          malloc(in_frames[cnt].buffer.length * sizeof(struct v4l2_plane));
      }
      /* query buffer to get the length */
      rc = ioctl(fd, VIDIOC_QUERYBUF, &in_frames[cnt].buffer);

type、memory、index、length、m.planes(只是一个指针，要分配内存)，然后ioctl VIDIOC_QUERYBUF，从返回值的struct v4l2_plane就可以获得plane的大小了。


