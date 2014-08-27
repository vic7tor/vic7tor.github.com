#android目录下的那些txt文件
是bluetooth.org出的一个叫PTS的工具用的，怎么调节还不知道有需要研究一下吧。

#Android.mk
看这个文件可以看到bluez在Android下的全貌了。

##init.bluetooth.rc
这个服务启动bluetoothd这个服务。

##bluetoothd
###daemon的启动
是由android/hal-bluetooth.c中的init函数来的：

	property_set("bluetooth.start", "daemon")

init.bluetooth.rc是必需的。

###daemon的wrapper
bluetoothd在userdebug和eng编译的情况下，bluetoothd编译成bluetoothd-main。

bluez/android/bluetoothd-wrapper.c会编译成bluetoothd由它来运行bluetoothd-main。

###daemon的log
这个是直接打到stdio，要想使用Android那些的话，需要定义__BIONIC__这个宏。

打到stdio的log，使用logwrapper也就行了，可以用这个打到Android上。

###android/main.c

####1.options

debug mgmt-debug

        if (option_dbg || option_mgmt_dbg)
                __btd_log_init("*", 0);

####2.bt_bluetooth_start

bt_bluetooth_start(option_index, option_mgmt_dbg, adapter_ready)

注意最后一个参数adapter_ready啦，是一个函数，干了很多事的。

创建一个struct mgmt，这个mgmt要好好研究下。

        if (mgmt_send(mgmt_if, MGMT_OP_READ_VERSION, MGMT_INDEX_NONE, 0, NULL,
                                read_version_complete, cb, NULL)

read_version_complete这个回调也干了非常多的事，同时调用了adapter_ready。

#####read_version_complete
adapter_ready交给mgmt_register(mgmt_if, MGMT_EV_INDEX_ADDED, MGMT_INDEX_NONE,...)来处理了。

MGMT_EV_INDEX_ADDED就是新增了一个ADAPTER吧。


#####adapter_ready
adapter_ready的调用时机：

在read_version_complete（在bt_bluetooth_start中调用的）中，调用了一个MGMT_OP_READ_INDEX_LIST，这个MGMT_OP_READ_INDEX_LIST应该是获得系统中的蓝牙Controller，这个Controller应该是驱动中注册的控制器。

然后在read_index_list_complete调用了MGMT_OP_READ_INFO，read_info_complete调用的adapter_ready。

adapter_ready中初始化了ipc:

        hal_ipc = ipc_init(BLUEZ_HAL_SK_PATH, sizeof(BLUEZ_HAL_SK_PATH),
                                                HAL_SERVICE_ID_MAX, true,
                                                ipc_disconnected, NULL);

同时注册了核心的ipc:HAL_SERVICE_ID_CORE。

###ipc机制
ipc是在adapter_ready中初始化的。

使用ipc_register来注册各种不同的ipc。

void ipc_register(struct ipc *ipc, uint8_t service,
                        const struct ipc_handler *handlers, uint8_t size)
{               
        if (service > ipc->service_max)
                return;
        
        ipc->services[service].handler = handlers;
        ipc->services[service].size = size;
}

所有的services是一个数组，用HAL_SERVICE_ID_CORE来索引。同时每个service的handler也是一个数组，这个就是ipc_send中的opcode。

####ipc_send

static void ipc_send(int sk, uint8_t service_id, uint8_t opcode, uint16_t len,
                                                        void *param, int fd)

####HAL_SERVICE_ID_CORE
看看HAL_SERVICE_ID_CORE处理函数。一共有两个opcode：

service_register,service_unregister。

service_register：

这个是服务总管，根据ID，调用bt_bluetooth_register、bt_socket_register、bt_hid_register这些服务。

bluetooth可能是对应HAL中bluetooth那个总设备的实现。

bt_socket_register实现在android/socket.c之中。

bt_hid_register - android/hidhost.c

###mgmt机制
####1.mgmt_new_default
1.先bind蓝牙socket。

2.mgmt_new

struct mgmt *mgmt_new(int fd)

fd就是蓝牙socket。

一共创建了request_queue、reply_queue、pending_list、notify_list。

io_set_read_handler：

io_set_read_handler重要的函数里面封装了glib的g_io_add_watch_full相关的。g_io_add_watch_full的有数据回调，最终调用的是struct io的read_callback也就是io_set_read_handler的参数里的那个回调，can_read_data。

同时mgmt也传入了can_read_data。

####can_read_data
处理内核传来的数据。

这个算是mgmt的核心了，所有内核上来的消息都经过这里，有需要时好好研究下。

####mgmt_send
这个往内核发送请求。成功后调用回调函数。

调用的wakeup_writer是很重要的。这个完成向内核发送消息的过程。

wakeup_writer -> io_set_write_handler

io_set_write_handler与io_set_read_handler类似。

####mgmt_register
这个接收内核来的消息。有对应事件事调用回调函数。

##HAL
###bluetooth.default
HAL定义在：hal-bluetooth.c

###audio.a2dp.default

###audio.sco.default


##bluetoothd-snoop

##测试管理程序
###1.btmgmt

###2.hcitool

###3.l2ping

###hciattach

###4.avtest

##profile
对于每种不同的profile，需要在仔细研究。

比如handfree:

android/handsfree.c

src/shared/hfp.c


