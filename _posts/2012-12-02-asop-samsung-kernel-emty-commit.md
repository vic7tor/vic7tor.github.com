---
layout: post
title: "asop samsung kernel emty commit"
description: ""
category: 
tags: []
---
{% include JB/setup %}
从asop clone下来samsung的kernel一看当前目录什么都没有。git log一下empty commit。然后，.git/refs目录没有任何东东。看到.git/packed-refs这个文件，看到其内容：

    # pack-refs with: peeled 
    f5f63efcc08ad67b25dfc7e20f99ebff8c499854 refs/remotes/origin/android-samsung-2.6.35-gingerbread
    665612374970f5dba43b65510b52b72130818541 refs/remotes/origin/android-samsung-3.0-ics-mr1
    3b0c5d2887fca99cab7dd506817b1049d38198a1 refs/remotes/origin/android-samsung-3.0-jb
    58941501e897aa344317efeed8c14f5e6da89a10 refs/remotes/origin/android-samsung-3.0-jb-mr0
    eef8e7b4bd22c91c2b227662da03f232d49a0245 refs/remotes/origin/master

后来看了下refs/remotes/origin里什么东东都没有。但是运行git checkout refs/remotes/origin/android-samsung-3.0-jb-mr0就能把东西checkout到工作目录了。
