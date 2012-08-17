---
layout: post
title: "uart and console driver"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.console driver
##1.1 struct console

    <linux/console.h>
    struct console {
            char    name[16];
            void    (*write)(struct console *, const char *, unsigned count);
            int     (*read)(struct console *, char *, unsigned);
            struct tty_driver *(*device)(struct console *, int *);
            void    (*unblank)(void);
            int     (*setup)(struct console *, char *options);
            int     (*early_setup)(void);
            short   flags;
            short   index; /* 如果是系统第一个注册的console会被置为0 */
	    			/* preferred_console会根据内核console参数被设置 */
            int     cflag;
            void    *data;
            struct   console *next;
    };
name - console的名字内核使用的console参数用到这个吧

##1.2 实例

    struct console s3c2440_serial_console = {
    	.name = "ttySAC",
    	.device = uart_console_device, /*这个函数会返回放在console->data的
    					uart_driver对应的tty_driver*/
    	.index = -1, /*这里还是不要设为-1的好，这个是console的index要通过这个index访问uart_driver的uart_port */
    	.flags = CON_PRINTBUFFER,
    	.write = s3c2400_serial_console_write, /* 内核s3c2440驱动使用高级的uart_console_write，它的最后一个参数使用的函数写入实际的寄存器
    	.setup = s3c2400_serial_console_setup, /* 会传入option 使用uart_parse_options来传理内核的console参数可以使用uart_set_options来设置这些参数*/
    	.data = &s3c2440_uart_driver,
    };

    console_initcall调用register_console /* <linux/init.h>

console的write函数要用使用uart_console_write要么在自己代码中做如下转换：

                if (*s == '\n')
                        putchar(port, '\r');
                putchar(port, *s);

这个代码会把'\n'弄成'\r''\n'

#2. uart driver
`<linux\serial_core.h>`
##1.uart_driver

    struct uart_driver {
        struct module	*owner;
        const char	*driver_name;
        const char	*dev_name;
        int		major;
        int		minor;
        int		nr;
        struct console	*cons;
        ...
    };


uart_register_driver uart_unregister_drive要通过这个index访问uart_driver的uart_port
##2.uart_port
很大的一个结构。拿向个出来说了。*查看他们作用的一个方法是：到uart_register_driver的定义所在的文件，搜索它的名字*

    line - tty_register_device中的index
    iobase、membase、mapbase - 这三个，其中一个还是要设的uart_config_port检测到这几个都为0的话会返回。为了写出可复用的代码，选membase或mapbase作为这个uart端口的基址。
    icount - 记录cts, dsr等等的次数，tx, rx的字节数。
    fifosize - 主要用来计算uart_wait_until_sent使用的timeout
    ops - uart_ops

其它的没发现什么大用。

uart_config_port(这外在uart_add_one_port中调用)与uart_set_options的区别：
在s3c2440的驱动中uart_config_port调用的`uart_ops->config_port`最后只`request_mem_region(port->mapbase,...)`。看了下，uart_add_one_port中调用了这个uart_config_port来调用与uart_ops相关的函数，觉得，把初始化控制器的代码放在这是不错的。
uart_add_one_port uart_remove_one_port
##3.uart_ops

`uart_port->uart_ops`

###1.
startup - 这个函数被uart_startup在uart_open中调用。在这个ttyS被打开时调用的，s3c2440的做法是request_irq

start_tx - 这个函数被uart_start在*uart_write*中调用，同时uart_start又是tty_operations中的start。

stop_tx - uart_stop调用，uart_stop为tty_operations的成员。s3c2440的驱动是使用disable_irq_nosync。或者是INTMSK 

在uart对tty的封装消除了tty_operations的write函数，并不是直接下，将写也缓存起来，当缓存的数据合适时，调用start_tx来发送。

stop_rx - 在uart_close中被调用。

没有start_rx - uart_insert_char在rx处理函数中向tty核心发送数据。这么看来，这设计适合用中断来处理。怎么rx见后面大节。

start_tx的处理(如用中断处理，则在中断中):

1.如果`uart_port->x_char`
发送这个字符，然后将其赋为0，再然后`uart_port->icout.tx++;`。见uart_send_xchar

2.发送一般数据

    struct circ_buf *xmit = &port->state->xmit;
    if (uart_circ_empty(xmit)) {
        iowrite8(xmit->buf[xmit->tail], REG_UART(UTXH));
	ximt->tail = (xmit->tail + 1) & (UART_XMIT_SIZE - 1);

    if (uart_circ_chars_pending(xmit) < WAKEUP_CHARS)
                    uart_write_wakeup(port);

3.当circ空了的时候可能需要stop_tx

###2.
enable_ms、get_mctrl、set_mctrl都是与modem相关的。

###3.
poll_put_char、poll_get_char kgdoc必要的条件。

###4.
set_termios - uart_set_options、uart_change_speed调用。要使用这个来取得uart_get_baud_rate
`termios->c_cflag & CSIZE`
c_cflag中的:
1.CSTOPB
这个位被设置则两个停止位，否则为一个停止位
2.PARENB
这个位被设置则有校验，进一步检查PARODD设置则ODD奇校验，没有设置则偶校检。
3.CSIZE
数据位长度
4.BAUD
波特率使用uart_get_baud_rate获得。
5.CRTSCTS
自动流控
###5. config_port
用来初始化UCON了

#3.uart rx与sysrq
更多Documentation/sysrq.txt。

sysrq提供的handle_sysrq，在uart中是：uart_handle_sysrq_char

三星的驱动提供了对sysrq的支持。

要及时处理sysrq，对于开启了FIFO的情况，一般FIFO中的数据要达到触发数目才会引发中断，同时对于少量数据，这也是一个问题，所以，要开启UCON的Rx Time out，这样，当过一定时间后，即使，数据数量没有达到触发的数目也会产生中断了。

当port.flags设置UPF_CONS_FLOW，要清空fifo。这个暂时不知道有什么用。

下面是接收流程：

1.port.icount.rx++ 设置标志TTY_NORMAL

2.处理UERSTAT的4种错误：

1)如果是BREAK port.icount.brk++同时调用uart_handle_break，这个函数与uart_handle_sysrq_char联合工作的。同时ignore这个字符，后面的函数不处理。三星驱动设置了TTY_BREAK但是后面没有处理这个字符就不管了，

2)如果是FRAME port.icount.frame++同时，设置TTY_FRAME后面要传给uart_insert_char。

3)如果是OVERRUN port.icount.overrun++同时设置TTY_OVERRUN。

4)如果是PARITY port.icount.parity++同时设置TTY_PARITY。

3.先uart_handle_sysrq_char，如果函数返回真，就ignore这个函数。

4.uart_insert_char uart_insert_char(port, uerstat, S3C2410_UERSTAT_OVERRUN, ch, flag);

flag就是上面的TTY_OVERREN TTY_PARITY TTY_BREAK什么的。

5.退出函数之前tty_flip_buffer_push `struct tty_struct *tty = port->state->port.tty;`

uart_handle_break与uart_handle_sysrq_char是联合工作，看代码就知道。

还有个问题UERSTAT是对FIFO中字符是统一的，还是每个字符都有一个UERSTAT？
每个字符一个UERSTAT，S3C2440手册里有个图。

还有那个，UERSTAT的错误同时只发生的一个吧。所以，上面操作与三星驱动不一样了。


