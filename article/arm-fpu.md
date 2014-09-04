在装java for arm时，看到有三种浮点的实现。

-mfloat-abi=hard -mfpu=vfp
-mfloat-abi=softfp -mfpu=vfp
-msoft-float

在网上看到文章，意思是，应用程序是哪种浮点，要跟内核走。其实这句话不正确，那个人说这种的话应该是对c库不太理解。其实是跟c库走啦。

内核是用什么浮点实现与用户态是没关系的啦，内核与用户态交互的系统调用是跟EABI走的，所以与这个没关系啦。

保证c库与编译出来的程序是同一浮点实现。

判断应用程序与c库是哪种如下:

c库的ld名字为：ld-linux-armhf.so.3

应用程序：readelf -l 中显示的ld为ld-linux-armhf.so.3

