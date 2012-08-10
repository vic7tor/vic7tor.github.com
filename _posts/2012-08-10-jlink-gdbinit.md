---
layout: post
title: "jlink gdbinit"
description: ""
category: 
tags: []
---
{% include JB/setup %}

    
    define init_mini2440
    monitor MemU32 0x48000000 = 0x02000000
    monitor MemU32 0x4800001C = 0x00018001
    end
    
    
    define jlink
    target remote localhost:2331
    monitor speed 30
    monitor endian little
    monitor reset
    
    monitor reg cpsr = 0xd3
    monitor speed auto
    init_mini2440
    
    if $argc == 1
    	load $arg0
    else
    	load
    end
    end
    
    document jlink
    jlink [file]
    	file: file to load to board
    end
    
    define jlinknoreset
    target remote localhost:2331
    monitor endian little
    monitor speed auto
    
    init_mini2440
    
    if $argc == 1
    	load $arg0
    else
    	load
    end
    end
    
    
    document jlinknoreset
    jlink [file]
    	file: file to load to board
    end
    
    define jlinkconnect
    target remote localhost:2331
    monitor endian little
    monitor speed auto
    end
