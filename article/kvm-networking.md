在玩hadoop，需要虚拟机，在弄虚拟机网络时头痛了。

在archlinux上找到了一个方案。

首先创建bridge设备：

brctl addbr br0
ip addr add 192.168.179.1/24 broadcast 192.168.179.255 dev br0
ip link set br0 up

在这个操作完成后，运行route命令发现：
192.168.179.0   *               255.255.255.0   U     0      0        0 br0

这个居然在表中

然后创建tap设备：
ip tuntap add dev tap0 mode tap
ip link set tap0 up promisc on

把tap0添加到bridge中：

brctl addif br0 tap0

在br0上启动dhcp:
dnsmasq --interface=br0 --bind-interfaces --dhcp-range=192.168.179.10,192.168.179.254

运行时如果报错，那么应该是已经有个实例在运行了，干掉之。

kvm启动的命令：

kvm -m 1024 -drive file=centos.img -enable-kvm -netdev tap,id=t0,ifname=tap0,script=no,downscript=no -device e1000,netdev=t0,id=nic0,mac=52:54:00:12:34:58

-device那一句是要的，要不然：
Warning: netdev t0 has no peer

如果不行，内核有个ipv4_forward什么的可能要开。

还有一个qemu权能的。

一个虚拟机需要一个tap，建了之后brctl addif br0 tap0。

在装的centos上，两个虚拟要是有相同的MAC，后开的用static地址也会失败。所以要在e1000最后加一个mac参数指定mac地址就好了。

