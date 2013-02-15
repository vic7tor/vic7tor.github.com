---
layout: post
title: "gdb attach"
description: ""
category: 
tags: []
---
{% include JB/setup %}
为了研究sensorservice需要调试一下看个究竟。

有两套方案：第一套是从头开始运行进程。system_service是zyote的第一代进程。但是挂掉后zyote也会重启。所以要从init开始attach，然后fork时跟随子进程。

第二套是直接attach system_server的pid。最开始是gdbclient system_server，运行后那些什么动态库什么的全部没有认出来。看gdb手册，没有找到什么有用的。在网上找到说，gdb就这样，attach后要根据/proc/pid/maps手动add-symbol-file。

然后今天就试试直接运行gdbclient是个什么结果。后来发现动态库符号全部载进去了。。。

后来看到gdb开始的载符号的提示，gdbclient默认相当于gdbclient app_process(gdb app_process)，只要指定正确了这个进程实际运行的文件，就能把动态库的符号正确载入。网上说那事，应该是gdb版本太老的原因吧。

system_server是app_process fork出来的，fork出来后就使用了libsystem_server而不是用system_server这个程序，所以运行的程序还是app_process。

这个程序也可以从/proc/pid/maps里看出来。用了exec的会把原来的虚拟内存映射清除吧。

所以，只要指定了正确的正在运行的程序的符号文件，attach后，这些库的符号也是能正确载入的。

