---
layout: post
title: "a binary kernel module RCE"
description: ""
category: 
tags: []
---
{% include JB/setup %}

XX之臂的开发板，audio模块又没有开放源代码。这下IDA又要上场了。

ASoC的驱动，要逆向的是Machine Driver那部分，昨天已经研究了下ASoC驱动了，但是，那书没带回来，一个普通的声卡驱动还不知道怎么搞，所以ASoC那几个成份的关系也没有搞清楚了。逆向过程还好，没有那个触屏驱动的那个把除法优化为乘法那么纠结，还以为是什么复杂算法，还好机缘巧合破解了。

这次呢，有两个大点的东西，昨天已经把snd_soc_card那部分搞定了，今天就init和params那两个函数。

init那些函数使用参数本是一个字符串，但是在我们反汇编代码中全部是0。在用IDA载入时也报了有无法识别的重定位。因为IDA版本有点老，我是在虚拟XP跑的。然后，用objdump -Dr破解了，这个会在反汇编代码中那重定位信息也贴上去，然后就发现些.LC9什么的，在.rodata.str节里也显示了，在IDA进这个节，然后就能正常逆向出来了。

难啃的一块大骨头是params这个函数，这个函数逆向过程中用了IDA的Graphic View功能。感觉这个功能挺重要的，用这个图比较好判断出if、for、switch这些语名，直接看汇编代码会被优化搞得分不清程序结构。

分析出程序结构是很重要的。

反汇编时，找了个现成的Machine Driver参考，也是三星的驱动。没有Machine Driver的的编程经验，用这个现成驱动来破解反汇编代码中一些奇怪的东西了。

遇上第一个奇怪的东西是param_format这个宏，他被switch(param_format())包住了，在switch语句的default直接return了。param_format是个宏，还有他完全被内联进来没有一点函数调用。刚开始以为params函数头部是一个if语句，但是后来，确定了，后面一个部分是switch语句，这个if语句又参与了后面switch语句的计算，后面参考那个三星驱动，确定是switch(param_format)。*这就是编程经验的重要性了，还有就是一些细节来确定那些看起来很复杂的算法其实是有原因的*。然后就破解了这个难题。后面的逆向也没什么难度了，另一个switch语句很显眼。IDA还是很好用的。

测试驱动，想用tinyplay来测的，但是没有合适的WAV文件，生成模块试试了。
