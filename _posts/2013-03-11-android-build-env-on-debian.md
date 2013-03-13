---
layout: post
title: "Android Build Env On Debian"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#32位libc
装gcc-multilib就行了

#g++-multilib

没有装g++-multilib时报下面的错。

/usr/bin/ld: skipping incompatible /usr/lib/gcc/x86_64-linux-gnu/4.6/libstdc++.so when searching for -lstdc++
/usr/bin/ld: skipping incompatible /usr/lib/gcc/x86_64-linux-gnu/4.6/libstdc++.a when searching for -lstdc++

#zlib
从zlib源代码会编译出几个包。zlib1g和lib32z1。从ubuntu官网上查来的。他们的source都是zlib。

#lib32ncurses

#java

    add_alternative () {
      for i in javac java javaws jar javadoc; do
        update-alternatives --install /usr/bin/$i $i /usr/local/jdk1.6.0_39/bin/$i 1
	update-alternatives --config $i
      done
    }

    add_alternative
