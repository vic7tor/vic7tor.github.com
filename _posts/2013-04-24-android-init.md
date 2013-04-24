---
layout: post
title: "android init"
description: ""
category: 
tags: []
---
{% include JB/setup %}
这次我也来分析下init，打算在st25i上面运行起cm10。机子是卓越上买的行货，bootloader没有解锁。所以只能弄卡刷了。

在网上找到了个cwm什么的，看了下他的实现，用的是chargemon。看起来chargemon会阻寨系统运行，所以来分析下init看个究竟。

#1.init_parse_config_file
在这个函数中也只是解析，并没有执行。

在parse_config这个函数中：


    int kw = lookup_keyword(args[0]);
    if (kw_is(kw, SECTION)) {
                    state.parse_line(&state, 0, 0);
                    parse_new_section(&state, kw, nargs, args);
    } else {
                    state.parse_line(&state, nargs, args);
    }

state.parse_line有在parse_new_section中赋值。

我们感兴趣的是在early-init起来的chargemon，所以看看on语句对应的parse_line_action(见parse_new_section)。

parse_line_action：

    kw = lookup_keyword(args[0]); 对于exec kw会是K_exec
    ...
    cmd->func = kw_func(kw);

跟踪kw_func会发现exec是由do_exec这个函数执行的。

在do_exec中:

    pid = fork();
    if (!pid)
    {
        char tmp[32];
        int fd, sz;
        get_property_workspace(&fd, &sz);
        sprintf(tmp, "%d,%d", dup(fd), sz);
        setenv("ANDROID_PROPERTY_WORKSPACE", tmp, 1);
        execve(par[0], par, environ);
        exit(0);
    }
    else
    {
        while(wait(&status)!=pid);
    }

在init.rc中的exec会让init等待子程序结束。so，使用exec的chargemon果断可以让android继续运行了。

#2.action_for_each_trigger

    action_for_each_trigger("early-init", action_add_queue_tail);

这个语句依然没有执行init.rc中解析出的的东西。

action_for_each_trigger：

    list_for_each(node, &action_list) {
        act = node_to_item(node, struct action, alist);
        if (!strcmp(act->name, trigger)) {
            func(act);
        }
    }

这个代码对所以满足trigger条件(early-init)的执行func(action_add_queue_tail)。在init.rc的解析中，对每个看到的on early-init都会创建一个数据结构，这个就是把它们都添加一个list里面去，并且新来的是加到尾部。

#3.执行

在main函数：

    for(;;) {
        int nr, i, timeout = -1;

        execute_one_command();
        restart_processes();


