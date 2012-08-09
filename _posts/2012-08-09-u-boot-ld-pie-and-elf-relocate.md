---
layout: post
title: "u-boot ld -pie与elf 重定位"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#最开始的解决方案
u-boot编译好后那个`__u_boot_cmd_start`的值是0，导致任何命令都不认。在ld script中发现有赋值。

开始以为可能是extern这个符号的形式问题。内核的代码是把它extern成一个数组。后来经过测试，无论任何形式的extern都行。指针的，非指针，ld script里的赋值，都是设置地址。是指针的，直接就是，不是指针的用`&`。

然后以为，是在ld script中，定义的位置的问题，然后，试了下，还是不是因为这个。

最后，猜可能是参数问题。先gcc编译`.o`文件，然后，用ld来只ld这个`.o`文件。ld、arm-none-linux-gnueabi-ld都试了，排除了交叉编译器的问题。最后，看到，u-boot的那个ld参数里，有个`-pie`，删掉这个参数，发现，正常了。。。

`-pie`是Create a position independent executable。这个，参数，会在最后的文件中生成几个节。。

没用`-pie`的：

    [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
    [ 0]                   NULL            00000000 000000 000000 00      0   0  0
    [ 1] .text             PROGBITS        32000000 008000 051210 00  AX  0   0 32
    [ 2] .u_boot_cmd       PROGBITS        32051210 059210 000768 00  WA  0   0  4
    [ 3] .rodata           PROGBITS        32051978 059978 01088c 00   A  0   0  4
    [ 4] .ARM.exidx        ARM_EXIDX       32062204 06a204 000020 00  AL  1   0  4
    [ 5] .data             PROGBITS        32062224 06a224 001fc8 00  WA  0   0  4
    [ 6] .bss              NOBITS          320641ec 000000 042fb0 00  WA  0   0 256

使用`-pie`的：

    [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
    [ 0]                   NULL            00000000 000000 000000 00      0   0  0
    [ 1] .text             PROGBITS        32000000 008000 051210 00  AX  0   0 32
    [ 2] .u_boot_cmd       PROGBITS        32051210 059210 000768 00  WA  0   0  4
    [ 3] .rodata           PROGBITS        32051978 059978 01088c 00   A  0   0  4
    [ 4] .hash             HASH            32062204 06a204 000044 04   A  9   0  4
    [ 5] .ARM.exidx        ARM_EXIDX       32062248 06a248 000020 00  AL  1   0  4
    [ 6] .data             PROGBITS        32062268 06a268 001fc8 00  WA  0   0  4
    [ 7] .got.plt          PROGBITS        32064230 06c230 00000c 04  WA  0   0  4
    [ 8] .rel.dyn          REL             3206423c 06c23c 007910 08   A  9   0  4
    [ 9] .dynsym           DYNSYM          3206bb4c 073b4c 0000c0 10   A  0   3  4
    [10] .bss              NOBITS          3206423c 000000 043060 00  WA  0   0 256

生成了几个用于重定位的节吧，但是，又没有加载器来加载这个文件。所以失败了。

这个就是为什么失败的原因。

#回头来再看这个问题
在解决上面那上问题之后，开始研究那个报raise的问题。除0问题，发现，那个值是被赋值了的啊。但是，后面居然又变成了0。嗯，jlink的watch功能来了。这回是能中断的，那个MLLCON设置的那个不行是因为，并没有什么去改变内存，而是因为，时钟配置问题导致读取异常。中断之后，发现代码是在relocate_code附近。嗯，后面调用了clear_bss。。

因为，那个被置0的变量是放在个初始化为0的变量。所以放在了bss段。初步解决办法是把他放在data段吧。

下面才是重点。在relocate_code附近看到了fixrel。这不就是上面使用`-pie`来编译时，多出的那几个段中的一个吗？

重新用`-pie`编译u-boot。readelf -r来显示这个type为REL的Section。很大的一个东西，很多R_ARM_RELATIVE的条目，最后的几条R_ARM_ABS32指向的就是我找来找去找不到的`__u_boot_cmd_start`的地址。

在relocate_code的代码中，不relocate的话，就直接跳到clear_bss。最后几条R_ARM_ABS32也就没有处理，代码中引用`__u_boot_cmd_start`的值也就是0。

u-boot这么做，是有他的道理，但是，他或许没有想到这后面隐藏的bug。

`-pie`的作用就是：生成类型为REL的重定位节。当代码不在原定的基址加载时，就使用这些信息来进行重定位。R_ARM_RELATIVE类型的重定位意思是：在代码中引用的地址是在原定基址加载用的地址(硬编码，直接指向一个内存地址)。当不在原定基址加载时，R_ARM_RELATIVE类型的重定位就把这个硬编码地址，加上或减去基址移动的偏移量。

`-pie`还有个就是，把ld scripte中定义的符号，弄成R_ARM_RELATIVE

u-boot不重定位的道理就在这里，在原来地址加载的话，R_ARM_RELATIVE就不用修正了，但是他忘了还有R_ARM_ABS32这样的。

还有R_ARM_ABS32这样的重定位，当需要重定位时，他的目的地址也要相应修改。

总的来说，`-pie`的目的就是让u-boot能在任意地址加载，尽管有BUG。但是，处理那么多重定位表，u-boot会变大，还影响启动时间。还是干掉这个功能吧。

