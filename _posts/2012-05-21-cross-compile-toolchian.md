---
layout: post
title: 再来一次交叉编译器
description: ""
category: arm
tags: [arm]
---
{% include JB/setup %}

#1.包版本
binutils-2.22、
#2.环境变量

    export TARGET=arm-none-linux-gnueabi
    export PREFIX=/usr/local/arm/gnu/toolchain/
    export PATH=$PATH:${PREFIX}/bin
#3.binutils

    ../binutils-2.22/configure --target=$TARGET --prefix=$PREFIX --disable-nls --disable-werror --disable-multilib --enable-shared
#4.gcc pass 1

    ../gcc-4.6.3/configure --target=$TARGET --prefix=$PREFIX --without-headers --with-newlib --with-gnu-as --with-gnu-ld --disable-nls --disable-decimal-float --disable-libgomp --disable-multilib --disable-libmudflap --disable-libssp --disable-shared --disable-threads --disable-libstdcxx-pch --disable-libffi --enable-languages=c --without-ppl --without-cloog --with-float=soft --with-arch=armv4t --with-cpu=arm920t --with-tune=arm920t
    make all-gcc && make all-target-libgcc
    make install-gcc && make install-target-libgcc
    ln -vs libgcc.a \`$TARGET-gcc -print-libgcc-file-name | sed 's/libgcc/\&\_eh/'\`
#5.kernel header files

    sudo make ARCH=arm CROSS_COMPILE=${TARGET}- INSTALL_HDR_PATH=$PREFIX/$TARGET/ headers_install
#6.glibc
configure时有个问题，原来编译没事，看来与软件环境有关自己看情况打patch

    BUILD_CC=gcc CC=${TARGET}-gcc AR=${TARGET}-ar RANLIB=${TARGET}-ranlib ../glibc-2.12.1/configure --prefix=/usr --host=$TARGET --build=$(../glibc-2.12.1/scripts/config.guess) -with-binutils=$PREFIX/bin -with-headers=$PREFIX/$TARGET/include --with-tls --with-\__thread --enable-sim --enable-ntpl --enable-add-on --enable-kernel=2.6.37 --disable-profile --without-gd --without-cvs libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes libc_cv_arm_tls=yes libc_cv_gnu99_inline=yes
    make install_root=$PREFIX/$TARGET prefix="" install
昨晚死机，今天早上make后直接装了，没有PREFIX和TARGET环境变量，直接把pc上的libc干掉了，遇到这样的情况，不要惊慌，不要重装。我的archlinux用光盘启动demo，找到原来的glibc的安装文件，解压，拷lib目录的东西到archlinx lib就OK。
    vi libc.so libpthread.so
#gcc pass 2
对mpfr mpc gmp的依赖的是在宿主机上的。宿主机上有相应的开发包就能编译通过了。

    ../gcc-4.6.3/configure --target=$TARGET -prefix=$PREFIX --with-float=soft --enable-languages=c,c++ --enable-threads=posix --enable-c99 --enable-long-long --enable-shared --enable-\__cxa_atexit --enable-nls --disable-libgomp --with-arch=armv4t --with-cpu=arm920t --with-tune=arm920t
