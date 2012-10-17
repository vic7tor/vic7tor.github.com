---
layout: post
title: "linux usb gadget"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#0.Makefile & Kconfig
对于linux内核中的一个子系统，读Makefile的确容易撇开驱动找到核心所在，比直接看文件名来猜测快得多。Kconfig用来解释Makefile。

那么从Makefile中得到gadget子系统的核心文件：udc-core.c

#1.gadget.h
##0.usb_request

    struct usb_request {
        void                    *buf;
        unsigned                length;
        dma_addr_t              dma;
        unsigned                stream_id:16;
        unsigned                no_interrupt:1;
        unsigned                zero:1;
        unsigned                short_not_ok:1;
        void                    (*complete)(struct usb_ep *ep,
                                        struct usb_request *req);
        void                    *context;
        struct list_head        list;
        int                     status;
        unsigned                actual;
    };

buf - 数据传输使用的buf是usb_gadget_driver分配的

length - buf中需要传送的数据长度。

dma - 

no_interrupt - 

complete - 传输结束时调用的函数。传输结束时，调用这个函数前，需要从queue中删除这个usb_request。

context - 可以用来让usb_gadget_driver放一些数据

list - 应该可以用来让usb_gadget把一个ep上的usb_request串在一起

status - 报告传输结束的状态，作为complete回调函数的返回值。`-ESHUTDOWN`表示设备disconnet。

actual - 实际传输成功的字节数

##1.usb_ep

    struct usb_ep { 
        void                    *driver_data;
        const char              *name;
        const struct usb_ep_ops *ops;
        struct list_head        ep_list;
        unsigned                maxpacket:16;
        unsigned                max_streams:16;
        unsigned                mult:2;  
        unsigned                maxburst:4;
        u8                      address;
        const struct usb_endpoint_descriptor    *desc;
        const struct usb_ss_ep_comp_descriptor  *comp_desc;
     };

name - ep的名字，这个名字可不能乱取，有格式的，见ep_matches这个函数。

    ep1, ep2, ... address is fixed, not direction or type
    ep1in, ep2out, ... address and direction are fixed, not type
    ep1-bulk, ep2-bulk, ... address and type are fixed, not direction
    ep1in-bulk, ep2out-iso, ... all three are fixed
    ep-* ... no functionality restrictions
    Type suffixes are "-bulk", "-iso", or "-int".  Numbers are decimal.
    Less common restrictions are implied by gadget_is_*().

ops - 见下面

ep_list - 与usb_gadget的这个成员串在一起，用来表示这个usb_gadget拥有的端点。

maxpacket - 填的是fifo size.难道一个包的长度只能是fifo大小?

mult - 

maxburst - usb3使用的

address - 

desc - 端点使能前就要被设置的

comp_desc - 

ops - usb_ep_ops 实现发送数据数据。

usb_ep_autoconfig_reset、usb_ep_autoconfig，gadget_driver用来分配端点。

##2.usb_ep_ops

    struct usb_ep_ops {
        int (*enable) (struct usb_ep *ep,
                const struct usb_endpoint_descriptor *desc);
        int (*disable) (struct usb_ep *ep);
        struct usb_request *(*alloc_request) (struct usb_ep *ep,
                gfp_t gfp_flags);
        void (*free_request) (struct usb_ep *ep, struct usb_request *req);
        int (*queue) (struct usb_ep *ep, struct usb_request *req,
                gfp_t gfp_flags);
        int (*dequeue) (struct usb_ep *ep, struct usb_request *req);
        int (*set_halt) (struct usb_ep *ep, int value);
        int (*set_wedge) (struct usb_ep *ep);
        int (*fifo_status) (struct usb_ep *ep);
        void (*fifo_flush) (struct usb_ep *ep);
    };

enable(usb_ep_enable) - 配置硬件使能这个端点，并设这个端点的描述符(usb_endpoint_descriptor)为传入的第二个参数。根据usb_endpoint_descriptor来设置端点的方向(bEndpointAddress USB_DIR_IN)。gadget_driver的setup处理了所有的描述符请求。在setup中，也是通过usb_ep_queue这样的机制来处理传输数据的。

disable(usb_ep_disable) - 看了名字你就知道。

alloc_request(usb_ep_alloc_request)、free_request(sb_ep_free_request) 简单的分配内存，同时初始化usb_request的list成员。usb_request的buf成员不需要分配。这个由gadget driver分配，见zero的alloc_ep_req函数。

queue(usb_ep_queue) - 刚进队的时候如果能进行数据传输的话就马上进行数据传输，如果不能的话，就只能等到当前传输完成后，在中断中处理了。*当usb_request完成时，需要从这个队列中删除这个usb_request。*还有，在把usb_request放入队列的时候，要初始化usb_request的actual成员和status成员(有见初始化为`-EINPROGRESS`。

dequeue(usb_ep_dequeue) - 以参数ECONNRESET调用完成函数。

set_halt - 这个需要实现，有的函数通过usb_ep_set_halt调用。set_halt后，是不是就不让usb_request入队了？在usb_ep_set_halt有解释。

##3.usb_gadget
usb_gadget - represents a usb slave device

    struct usb_gadget { 
        /* readonly to gadget driver */
        const struct usb_gadget_ops     *ops;
        struct usb_ep                   *ep0;
        struct list_head                ep_list;        /* of usb_ep */
        enum usb_device_speed           speed;
        unsigned                        is_dualspeed:1;
        unsigned                        is_otg:1;
        unsigned                        is_a_peripheral:1;
        unsigned                        b_hnp_enable:1;
        unsigned                        a_hnp_support:1;
        unsigned                        a_alt_hnp_support:1;
        const char                      *name;
        struct device                   dev;
    };

ops - 

ep0 - 

ep_list - gadget驱动的除ep0外的`struct usb_ep`结构的ep_list成员的链表头。这个成员要在注册usb_gadget时把那些usb_ep放进来。find_ep和usb_ep_autoconfig_ss就是用这个成员来查找usb_ep的。

dev - 在usb_add_gadget_udc时，并不会使用这个dev来添加到`/sys/class/udc`下面，而是新建一个。usb_gadget中的这个dev是用来将来与usb_gadget_driver里的driver配对用的，而且是那个usb_gadget_driver注册设备的父母(见msg_do_config调用的fsg_common_init)。这个dev在usb_add_gadget_udc那段时间初始化，在usb_gadget_ops的start初始化driver成员后用device_add注册。如果使用udc_start的话，还是不行，因为那个bind是在udc_start之前调用的，而在start中，是start调用bind的，看了下at91的驱动，在usb_add_gdaget_udc之前就使用register_device注册这个结构了。初始化init_name和parent

usb_gadget_ops里面的start在注册usb_gadget_driver时被传进来。

一个udc驱动就要使用usb_add_gadget_udc来注册usb_gadget.根据usb device control的个数来注册吧。

##4.usb_gadget_ops

    struct usb_gadget_ops {
        int     (*get_frame)(struct usb_gadget *);
        int     (*wakeup)(struct usb_gadget *);
        int     (*set_selfpowered) (struct usb_gadget *, int is_selfpowered);
        int     (*vbus_session) (struct usb_gadget *, int is_active);
        int     (*vbus_draw) (struct usb_gadget *, unsigned mA);
        int     (*pullup) (struct usb_gadget *, int is_on);
        int     (*ioctl)(struct usb_gadget *,
                                unsigned code, unsigned long param);
        void    (*get_config_params)(struct usb_dcd_config_params *);
        int     (*udc_start)(struct usb_gadget *,
                        struct usb_gadget_driver *);
        int     (*udc_stop)(struct usb_gadget *,
                        struct usb_gadget_driver *);
        /* Those two are deprecated */
        int     (*start)(struct usb_gadget_driver *,
                        int (*bind)(struct usb_gadget *));
        int     (*stop)(struct usb_gadget_driver *);
    };

udc_start - 注册usb_gadget_driver时使用。使usb_gadget的device结构的driver指向usb_gadget_driver的driver，然后device_add添加这个device结构，这么做的话，usb_gadget_driver中注册device就会出错，看上面usb_gadget中的解释。把usb_gadget_driver存起来，然后，使能初始化并使能硬件控制器。

udc_stop - device_del注销device结构，如果usb_gadget_driver.disconnect存在的话就调用。强制调用usb_gadget_driver.unbind。

start、stop同udc_start、udc_stop的功能。这两个函数将要被替换掉。见usb_gadget_probe_driver。

get_config_params - 

get_frame -

wakeup -

set_selfpowered -

vbus_session - 

###内核配置

    USB Gadget Support->USB Peripheral Controller(这个是个choice没有类型的，就变成了一个菜单吧，在drivers/usb/gadget/Kconfig，然后定义自己的udc的。)

##5.usb_gadget_driver
usb_gadget_driver - driver for usb 'slave' devices。应该是实现一个具体的功能，比方说串口，或者U盘什么的。

setup - 要实现所有的get_desciptor请求。get/set_interface、get/set_configuration也一定要实现。在setup中，也是通过usb_ep_queue这样的机制来处理传输数据的。

usb_gadget_driver与usb_gadget之间的数据交流不管输入输出都是用那个usb_request。是输入还是输出是由端点的类型决定的。

usb_ep_autoconfig使用一个usb_endpoint_descriptor描述符来分配一个端点。

#2.usb gadget传输过程
##1.在usb_gadget_driver中
因为ep有输入输出两种类型。这个结构读写都行？目的与urb一样吧。答案见的`drivers/usb/gadget/f_loopback.c`的loopback_complete。但其实是`struct usb_ep`结构中的usb_endpoint_descriptor(desc)的bEndpointAddress来决定的。在usb_ep_autoconfig时。

在f_loopback.c的loopback_complete中，如果当前usb_request成功完成(`usb_request.status`)，如果它是OUT（通过complete第一个参数usb_ep确定)，那么就再把usb_request使用usb_ep_queue(in_ep, req, ..)，放到IN ep的队列中。反之是IN的传输完成就把它放到OUT的队列。

在enable_loopback中，先配很多个usb_request放在out那个ep的队列上。然后就是，上面的过程了，如果out ep的队列上有usb_request完成了，然后这个usb_request就会放在in ep的队列上。

##2.在usb_gadget中


#2.udc驱动
在中断中处理请求，如果设备状态在没有配置情况下，处理一般的请求，其它的交给usb_gadget_driver.setup处理。usb_gadget_driver上方定义的文档写道。需要注意的是，当调用这个setup的时，在这个setup里会马上分配request并放入队列。

#3.usb_gadget_driver
usb_gadget_probe_driver - 注册gadget driver，只有这个函数，目前版本内核切掉了usb_gadget的bind成员，这个函数的第二个参数bind，要写出来。

bind要做的事情，稍后列出来。

usb_gadget_unregister_driver -

#3.处理控制传输
##1.include/linux/usb/ch9.h
###1.usb_ctrlrequest

    struct usb_ctrlrequest {
        __u8 bRequestType;
        __u8 bRequest;
        __le16 wValue;
        __le16 wIndex;
        __le16 wLength;
    } __attribute__ ((packed));

###2.bRequestType
这个一共分成三个域:传输方向、类型、接收者

    D7(方向): 没有MASK直接和USB_DIR_IN相与吧。USB_DIR_OUT、USB_DIR_IN(值为0x80)
    D6..5(类型)：与USB_TYPE_MASK相与分离这个域。USB_TYPE_STANDARD、USB_TYPE_CLASS、USB_TYPE_VENDOR、USB_TYPE_RESERVED
    D4..0(接收者)：与USB_RECIP_MASK相与分离出这个域。USB_RECIP_DEVICE、USB_RECIP_INTERFACE、USB_RECIP_ENDPOINT、USB_RECIP_OTHER。

###2.bRequest - USB_REQ_*
有下面这些宏：

    USB_REQ_GET_STATUS
    USB_REQ_CLEAR_FEATURE
    USB_REQ_SET_FEATURE
    USB_REQ_SET_ADDRESS
    USB_REQ_GET_DESCRIPTOR
    USB_REQ_SET_DESCRIPTOR
    USB_REQ_GET_CONFIGURATION
    USB_REQ_SET_CONFIGURATION
    USB_REQ_GET_INTERFACE
    USB_REQ_SET_INTERFACE
    USB_REQ_SYNCH_FRAME

这些请求由usb_gadget处理的请求有set_address、feature相关的get_status、set_feature、clear_feature。

usb_gadget_driver的setup处理get/set_descriptor、get/set_configuration、get/set_interface

#4.一般数据处理
关注usb_endpoint_descriptor的bEndpointAddress的第7位表示这个端点的传输方向。然后把这个队列上的usb_request依据这个传输方向来发出去或者接收。usb_endpoint_dir_in、usb_endpoint_dir_out这两个函数可以用来判断传输方向。

#5.控制传输的queue处理
一个控制传输需要传输一个结构体，就是那个usb_ctrlrequest的wLength把这次数据传输的总量标明出来了。但是因为控制端点能发的最大包的限制，然后，这个数据阶段会有多次数据传输，直到最后一次数据传输，才进入控制传输的最后的状态阶段(s3c2440中要IN/OUT_PKT_RDY和DATA_END同时设置)。在usb_gadget_driver的setup收到usb_ctrlrequest后，就会在buffer中放入wLength的数据。然后呢，在控制传输的数据阶段，每传送一定的数据，就把usb_request的actual加上这次传送的数据，没有调用usb_request的complete，usb_gadget_driver是不会动usb_request中的东西的。当一次数据传输的actual等于length的时候，这时候，就要让控制传输进入状态阶段了。

当中断发生时，并且有数据完成(IN_PKT_RDY(发送数据前检测/OUT_PKT_RDY收了数据后检测，就那个ep0_state=DATA_IN/DATA_OUT来确定检测IN/OUT_PKT_RDY)，检测是否有usb_request的actual等length的，然后这个usb_request就可以complete了。

维护一个状态机，USB控制器被复位时，初始化这个状态机为IDLE。根据usb_ctrlrequest显示当前的传输为IN或OUT来使状态机进入DATA_IN或DATA_OUT。然后让USB控制器进入数据阶段。然后处理usb_request(一个控制传输只处理一个usb_request，根据EP0的maxpacket的大小，分批传输数据，每次成功后，增加usb_request的actual的大小为传输的字节数。然后，当usb_request的actual等于length的时候，让USB控制器的状态阶段。同时，使状态机进入IDLE状态，并调用usb_request的complete函数。然后，调用complete前usb_request被从queue中删除。然后下次控制传输时又被入队。

当调用complete后。然后，下一次request来的时候，就修改下buf的内容length。actual的值在usb_ep_ops的queue中被初始化为0。在处理这个usb_request时，并进入数据阶段，不会有新的usb_ctrlrequest过来。然后，队列中，就只有这个usb_request并且只为IN或OUT。

#6.一般端点queue的处理
刚开始，以控制传输的那种队列处理方式来处理一般端点的传输。然后，查看printk的记录，在收到包后，没有调用usb_request的complete，printk的约20个时间单位后，被主机无情的复位了。

先就是按照控制传输的队列处理方式，要把usb_reqeust的actual读成length长度才调用complete。但一般传输与控制传输不一样。一次控制传输的数据量是SETUP事务的那个usb_ctrlrequest给出的。然后，这次控制传输就要传送其指定的数据量。因为控制端点的maxpacket小，所以会有多次数据传输。

而对于一般传输(BULK)就一个IN或OUT事务，并没有SETUP事务来指定长度。并且，其maxpacket主机已经通过端点描述符知道了。主机会传送合法长度的数据。

*说到底，一次传输的完成就需要调用一次usb_request的complete。一次控制传输，包含多次IN或OUT。而一次BULK传输就一次IN或OUT。*
