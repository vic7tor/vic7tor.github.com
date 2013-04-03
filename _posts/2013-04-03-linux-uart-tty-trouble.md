---
layout: post
title: "linux uart tty trouble"
description: ""
category: 
tags: []
---
{% include JB/setup %}
昨天弄那个tiny210和cc2530串口通信时发生了一个神奇的问题，13会变成10。然后，用IAR调试时发现发的时候还是0xd啊，我改了一个其它的数，一试，发过来就是我改的数。其它数据发得好好的。下班回家途中一不小心想到了是不是tty转译了。

今天早上来到公司，先看了下ASCII表，0xd是回车，0xa是换行，看来问题就是在这里了。看APUE，现在记录下来。

APUE那里面有个tty_raw函数，使用终端进入raw mode，也有叫非本地模式，非规范模式。

ttySAC，tty就是终端的意思，串口也是终端。

tty_raw对进入raw mode做了三件事。

    struct termios buf;

    tcgetattr(fd, &buf);

    buf.c_lfag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    ~ECHO - 关闭回显标志。
    ~ICANON - 使用终端处于非规范模式，输入数据不组成行(不等到回车才返回数据)，不处理下列特殊字符：ERASE、KILL、EOF、NL、EOL、EOL2、CR、REPRINT、STATUS、WERASE。规范模式每次返回一行数据。
    ~IEXTEN - 关闭对扩充字符的处理。
    ~ISIG - 关闭对产生信号字符的处理。

    buf.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    ~BRKINT - 禁用BRKINT使用BREAK字符不再产生信号
    ~ICRNL - 不将输入的CR转为NL
    ~INPCK - 奇偶校验不起作用
    ~ISTRIP - 不剥离字节的第8位，(输入一个字节时只有7位有效)
    ~IXON - 不进行输出流控

    buf.c_oflag &= ~(OPOST);
    Output processing off.

本次的这个问题就出在ICRNL这个标志上。


