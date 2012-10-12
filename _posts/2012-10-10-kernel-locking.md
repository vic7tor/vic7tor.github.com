---
layout: post
title: "kernel locking"
description: ""
category: 
tags: []
---
{% include JB/setup %}
看到内核中的驱动使用锁的时候，我都很纠结，这里用锁真的有用吗？我的一向原则是，不知道他是干什么的就不照抄，直到出错我才知道为什么会这样。

现在发现一篇专门讲锁的文档了，DocBook下面的一份`kernel-locking`。

贴目录：

Unreliable Guide To Locking

Rusty Russell


      <rusty@rustcorp.com.au>
     

Copyright © 2003 Rusty Russell

This documentation is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

For more details see the file COPYING in the source distribution of Linux.

Table of Contents

1. Introduction
2. The Problem With Concurrency
Race Conditions and Critical Regions
3. Locking in the Linux Kernel
Two Main Types of Kernel Locks: Spinlocks and Mutexes
Locks and Uniprocessor Kernels
Locking Only In User Context
Locking Between User Context and Softirqs
Locking Between User Context and Tasklets
Locking Between User Context and Timers
Locking Between Tasklets/Timers
The Same Tasklet/Timer
Different Tasklets/Timers
Locking Between Softirqs
The Same Softirq
Different Softirqs
4. Hard IRQ Context
Locking Between Hard IRQ and Softirqs/Tasklets
Locking Between Two Hard IRQ Handlers
5. Cheat Sheet For Locking
Table of Minimum Requirements
6. The trylock Functions
7. Common Examples
All In User Context
Accessing From Interrupt Context
Exposing Objects Outside This File
Using Atomic Operations For The Reference Count
Protecting The Objects Themselves
8. Common Problems
Deadlock: Simple and Advanced
Preventing Deadlock
Overzealous Prevention Of Deadlocks
Racing Timers: A Kernel Pastime
9. Locking Speed
Read/Write Lock Variants
Avoiding Locks: Read Copy Update
Per-CPU Data
Data Which Mostly Used By An IRQ Handler
10. What Functions Are Safe To Call From Interrupts?
Some Functions Which Sleep
Some Functions Which Don't Sleep
11. Mutex API reference
mutex_init — initialize the mutex
mutex_is_locked — is the mutex locked
mutex_lock — acquire the mutex
mutex_unlock — release the mutex
mutex_lock_interruptible — acquire the mutex, interruptible
mutex_trylock — try to acquire the mutex, without waiting
atomic_dec_and_mutex_lock — return holding mutex if we dec to 0
12. Further reading
13. Thanks
Glossary
List of Tables

2.1. Expected Results
2.2. Possible Results
5.1. Table of Locking Requirements
5.2. Legend for Locking Requirements Table
8.1. Consequences
