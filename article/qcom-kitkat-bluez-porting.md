#1.bionic
bluez依赖新版的bionic这个c库中实现的一些函数。

但是高通的bionic库好像是高通自己维护的，看其git log，基本上是高通的人在维护。

解决方案是选用高通的bionic库，然后，新建一个指向bluez的那个bionic库的remote，再然后，merge这个remote上对应分支。

##2.netd编译失败

新的bionic提交：081db840befec895fb86e709ae95832ade2d065c修改了一个函数的声明，是为了修复一个bug。

提交信息里有详细的说明需要注意。

暂时处理是git revert这个提交。

要不然把netd上的更新拉过来。

#2.对bluedroid的依赖
原来高通有的部分对bluedroid的头文件有信赖。

保留bluedroid吧，只是把bluedroid下的Android.mk干掉。

libbt-vendor应该有人用。

#3.bluetoothd退出
I/bluetoothd( 1633): bluetoothd[1634]: Bluetooth daemon 5.21
I/bluetoothd( 1633): bluetoothd[1634]: Failed to access management interface
I/bluetoothd( 1633): bluetoothd terminated by exit(1)

##bluetooth调试的开启
persist.sys.bluetooth.debug

persist.sys.bluetooth.mgmtdbg


