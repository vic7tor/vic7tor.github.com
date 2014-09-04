#1.报错
##1.LD_LIBRARY_PATH

LD_LIBRARY_PATH=/vendor/lib:/system/lib

有这个环境变量，运行程序后segment错误，然后什么也没有。

不加这个变量时，下面strace时会发现找libc.so、libcutils.so这个库，这个是Android下面的命名。怎么回事呢？

把这个变量干掉后就报libcutils.so找不到了，为什么ld-linux.so.3会去找这些库？

root@msm8226:/ # /lib/ld-linux.so.3 ./test

./test: error while loading shared libraries: libcutils.so: cannot open shared object file: No such file or directory

这么神奇，为什么会去找

strace /lib/ld-linux.so.3 ./test | busybox grep open

会发现有open libcutils.so的调用。

#2.源代分析
通过报错中的cannot open shared object file这一句，找到源代码在glibc/elf/dl-load.c的_dl_map_object这个函数。

ld.so的入口文件是：elf/rtld.c，找_dl_map_object时无意看到了一个do_preload，然后在引用的地方看到了一个LD_PRELOAD。

然后另开一个adb shell，printenv果真有这个环境变量：

root@msm8226:/ # echo $LD_PRELOAD                                              
/vendor/lib/libNimsWrap.so

然后把这个环境变量搞掉，一运行就OK了。

在strace中也有看到有：
mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb6f98000
open("/vendor/lib/libNimsWrap.so", O_RDONLY) = 3
read(3, "\177ELF\1\1\1\0\0\0\0\0\0\0\0\0\3\0(\0\1\0\0\0\0\0\0\0004\0\0\0"..., 512) = 512

就是这个库需要libcutils.so的啦。

victor@dream:~/disk/embeded-server/rootfs$ arm-linux-gnueabi-strings libNimsWrap.so | grep "\.so"
libdl.so
libc.so
libcutils.so
libNimsWrap.so
/system/vendor/lib/libcneconn.so
/system/lib/libc.so

#总结
完全是因为LD_PRELOAD引起的啦。与LD_LIBRARY_PATH没有一点关系。

理论上一个程序使用的库由readelf -l显示的ld来加载，这个ld都会指向自己的路径啦。比说64位机，有/lib64和/lib32两个路径。

所以库放在对应位置就没有问题啦。


