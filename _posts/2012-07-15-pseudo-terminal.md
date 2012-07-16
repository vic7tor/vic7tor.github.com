---
layout: post
title: "pseudo terminal"
description: ""
category: 
tags: []
---
{% include JB/setup %}
wikipedia上面的词条pseudo terminal。一共有两种pseudo terminal。一种是BSD PTYS一种是UNIX98 PTYS。BSD的是那种从设备为/dev/tty[p-za-e][0-9a-f]，主设备为/dev/pty[p-za-e][0-9a-f]。UNIX98是主设备为/dev/ptmx，从设备为/dev/pts/N那种。/dev/ptmx是"pseudo terminal master multiplexer"，当它被打开时，一个从节点/dev/pts/N会出现（这就是为什么当年会存在devpts这种文件系统，现在由于强大的udev这种文件系统没有必要了）。试试cat /dev/ptmx，你会发现，在/dev/pts下，会有一个新的slave出现。
