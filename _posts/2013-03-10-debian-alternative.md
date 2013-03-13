---
layout: post
title: "debian alternative"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#alternative干什么的
这玩意用来管理几个提供同一功能的程序。

如果你装了多个浏览器使用下面这条命令，你可以看到：

    $ update-alternatives --config x-www-browser
    There are 2 choices for the alternative x-www-browser (providing /usr/bin/x-www-browser).

      Selection    Path                       Priority   Status
    ------------------------------------------------------------
      0            /usr/bin/chromium-browser   40        auto mode
      1            /usr/bin/chromium-browser   40        manual mode
      2            /usr/bin/firefox            40        manual mode

#实现
用一个名字来描述提供特定功能的程序，比方像浏览器的是x-www-browser。

然后在/usr/bin/下就有一个x-www-browser的符号链接。这个符号链接会指向/etc/alternatives/x-www-browser，/usr/bin/下的那个符号链接会一直指向/etc的。

/etc/alternatives/x-www-browser会就根据update-alternatives --config x-www-browser选择的值分别指向firefox或者是chromium。

#java的实例
执行update-alternatives --install创建一个alternatives。

update-alternatives --install /usr/bin/javac javac /usr/local/jdk1.6.0_33/bin/javac 1

这样就创建了一个名叫javac的alternatives。

如果有多个同名的alternatives的话，就要用--config来选一个了。

