#1.命令对应函数的原型
libedify的func原型

参考MountFn：

Value* MountFn(const char* name, State* state, int argc, Expr* argv[])

name:
为命令名字。

State:
为edify内部数据结构。

argc,argv:
参数获得使用ReadArgs来获得。使用见MountFn或RenameFn这两个函数。

返回值：
命令失败：return StringValue(NULL);
命令成功：return StringValue("非空字符串");
这样做的目的是可以用脚本中的if语句来判断命令是否执行成功。见IfElseFn中对BooleanString的调用。

升级LPC、T123等到时参数是一个升级bin文件的路径，只有一个参数。

#2.开发指导
##lpc
lpc升级命令暂定为update_lpc

请实现在flyaudio/lpc.c

函数名为:UpdateLPCFn

到时统一由flyaudio/flyaudio.c来注册所有函数:
RegisterFunction("update_lpc", UpdateLPCFn);

##t123
t123升级命令为update_t123

函数名为:UpdateT123Fn

#3.recovery浅析
recovery.img的组成是由kernel+recovery的ramdisk。

ramdisk的内容是：out/target/product/msm8974/recovery/root/

看其中的init.rc 可见到recovery是一个服务，要想增加其它服务，可以放在这里面做。

recovery这个程序运行后，最终，调用压缩包安装程序的是：

install.c的try_update_binary函数。

至此控制权转移到updater这个程序，这个文件在zip包有另外名字。

updater源代码在recovery根目录的updater下。

想了解它可以从其main函数开始看。

这个程序引用了libedify这个静态库，libedify这个库的源代码在edify这个目录下。这个库完成对zip升级包中脚本的解析与运行。

#adb shell移植
android 默认开了个adb，但是没有toolbox和mksh

readelf -l 查看toolbox的加载器，当然是/system/bin/linker啦。

然后一些库弄到recovery的rootfs去。

#console
直接和正常init.rc一样就行了。

