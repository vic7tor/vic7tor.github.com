#0.WHY
需要知道一个设备节点对应的驱动是什么，这个还真不好找。

于是想使用ftrace的function graph来探测sys_open最终调用了哪里。

到时cat一下设备节点就open了。

不想trace的函数可以用notrace修饰的。

#1.遇到的问题
内核启动时问题出在ftrace_init调用的ftrace_process_locs失败。

<6>[    0.043770] ftrace faulted on writing [<c01003a0>] asm_do_IRQ+0x10/0x1c

##1.ftrace实现
ftrace使用自己的数据结构来记录每个函数调用。

3747         p = start;
3748         while (p < end) {
3749                 addr = ftrace_call_adjust(*p++);
3750                 /*
3751                  * Some architecture linkers will pad between
3752                  * the different mcount_loc sections of different
3753                  * object files to satisfy alignments.
3754                  * Skip any NULL pointers.
3755                  */
3756                 if (!addr)
3757                         continue;
3758                 if (!ftrace_record_ip(addr))
3759                         break;
3760         }

start是__start_mcount_loc

这个变量的定义流vmlinux.lds.S->INIT_DATA->MCOUNT_REC->

102 #define MCOUNT_REC()    . = ALIGN(8);                           \
103                         VMLINUX_SYMBOL(__start_mcount_loc) = .; \
104                         *(__mcount_loc)                         \
105                         VMLINUX_SYMBOL(__stop_mcount_loc) = .;

__mcount_loc这个section是怎么来的呢？是scripts/recordmcount.pl这个脚本生成的。

ftrace_record_ip初始化dyn_ftrace这个结构，指向调用__gnu_mcount_nc函数的地方。

ftrace_update_code：
这个修改dyn_ftrace指向的ip，让其指向FTRACE_ADDR。

FTRACE_ADDR为ftrace_caller

299 #ifdef CONFIG_DYNAMIC_FTRACE
300 ENTRY(ftrace_caller)
301         __ftrace_caller
302 ENDPROC(ftrace_caller)
303 #endif

__ftrace_caller是在这个文件中定义的一个宏最终指向ftrace_stub。

ftrace_update_code:

ftrace_update_code->__ftrace_replace_code->ftrace_make_call->ftrace_modify_code->probe_kernel_write

##probe_kernel_write

long __probe_kernel_write(void *dst, const void *src, size_t size)
{
        long ret;
        mm_segment_t old_fs = get_fs();

        set_fs(KERNEL_DS);
        pagefault_disable();
        ret = __copy_to_user_inatomic((__force void __user *)dst, src, size);
        pagefault_enable();
        set_fs(old_fs);

        return ret ? -EFAULT : 0;
}
EXPORT_SYMBOL_GPL(probe_kernel_write);

这玩意能写内核地址？注意那一句set_fs(KERNEL_DS);

#current_trace
写这个文件会跳转到tracing_set_trace_write。

#pc上的实践
ls -l set_graph_function这个文件时，显示权限:

-r--r--r-- 1 root root 0 Aug  4 16:57 set_graph_function

这时只要这个函数能trace，echo do_sys_open > set_graph_function仍然是能写入的。

#没办法
probe_kernel_write失败的原因搞不定，只能把DYNAMIC_FTRACE关了。

##高通板子上的实战
写了一个小程序来打开/dev/smd2。

然后set_ftrace_pid的pid指向这个小程序，设置set_graph_function。current_trace开trace。然后慢慢找吧。

最后找到了smd_tty_open，猜测就是这个啦。arch/arm/mach-msm/smd_tty.c

static struct smd_config smd_configs[] = {
        {0, "DS", NULL, SMD_APPS_MODEM},
        {1, "APPS_FM", NULL, SMD_APPS_WCNSS},
        {2, "APPS_RIVA_BT_ACL", NULL, SMD_APPS_WCNSS},
        {3, "APPS_RIVA_BT_CMD", NULL, SMD_APPS_WCNSS},
        {4, "MBALBRIDGE", NULL, SMD_APPS_MODEM},

2,3都是蓝牙的啦。


让小程序打开文件，
