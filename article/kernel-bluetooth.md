#0.mgmt
对于bluez的lib/mgmt.h定义的MGMT_OP_READ_INDEX_LIST，内核中同样是有的：

include/net/bluetooth/mgmt.h:38:#define MGMT_OP_READ_INDEX_LIST		0x0003

#1.综述
蓝牙核心的代码在net/bluetooth。

看蓝牙核心的架构图，host端有L2CAP和更上层的SMP、ATT、SDP这些组件。

Linux中对Host部分实现，L2CAP是放在内核中的。SDP是放在bluez实现的。

纵观一下net/bluetooth下的文件，都看了下，af_bluetooth.c这个文件是老大。

在af_bluetooth.c的bt_init中，调用了hci、l2cap、sco的init函数。

##net综述
对于socket系统调用的原型：

int socket(int domain, int type, int protocol);

domain就是调用内核sock_register时注册的PF_或AF_系列的东西。

相对于inet，就是我们一般的网络。蓝牙创建网络使用的参数不一样。

一般网络：
socket(PF_INET,SOCK_STREAM,0)

蓝牙网络：sock = socket(PF_BLUETOOTH, SOCK_SEQPACKET, BTPROTO_SCO);

一般网络使用第二个参来区分不同的协议，蓝牙网络使用第三个参数来区分不同协议。

对于socket这个调用最后应该是直接到net_proto_family(sock_register参数)的create函数
###net_proto_family
这玩意与sock_register，是与用户态直接交互的。

###proto
这个是net_proto_family的create调用sk_alloc时使用到的，为sk_alloc第4个参数。

这个结构里也有些操作，不知道怎么玩的。

#2.net/bluetooth/af_bluetooth.c

##1.bt_init

#与应用层交互
##bind
用户态程序:

        struct sockaddr_hci addr;

        memset(&addr, 0, sizeof(addr));
        addr.hci_family = AF_BLUETOOTH;
        addr.hci_dev = index;
        addr.hci_channel = channel;

        if (bind(fd, (struct sockaddr *) &addr, sizeof(addr)) < 0)

内核态就是：

	static const struct proto_ops hci_sock_ops = {
	。。。
	.bind           = hci_sock_bind,
	};

hci_sock_ops引用的代码：

        sock->ops = &hci_sock_ops;
        sk = sk_alloc(net, PF_BLUETOOTH, GFP_ATOMIC, &hci_sk_proto);

#HCI
##hci_dev

hci_sock_bind->hci_dev_get

hci_register_dev注册设备

hci_register_dev都是drivers/bluetooth下面的东东注册的啦。


