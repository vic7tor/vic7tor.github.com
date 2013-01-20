---
layout: post
title: "android mount sdcard"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#1.init.goldfish.rc
on early-init
    export EXTERNAL_STORAGE /mnt/sdcard
    mkdir /mnt/sdcard 0000 system system
    # for backwards compatibility
    symlink /mnt/sdcard /sdcard

#2.vold.fstab

    ## Vold 2.0 Generic fstab
    ## - San Mehat (san@android.com)
    ## 
    
    #######################
    ## Regular device mount
    ##
    ## Format: dev_mount <label> <mount_point> <part> <sysfs_path1...> 
    ## label        - Label for the volume
    ## mount_point  - Where the volume will be mounted
    ## part         - Partition # (1 based), or 'auto' for first usable partition.
    ## <sysfs_path> - List of sysfs paths to source devices, must start with '/' character
    ## flags        - (optional) Comma separated list of flags, must not contain '/' character
    ######################
    
    dev_mount sdcard /mnt/sdcard 4 /devices/platform/s3c-sdhci.0/mmc_host/mmc0/mmc0:0001/block/mmcblk0 nonremovable,encryptable

那个/devices/platform/s3c-sdhci.0/mmc_host/mmc0/mmc0:0001/block/mmcblk0 是以sysfs为根目录的路径，一个sysfs目录，指向mmcblk0所在。

实测发现那个mmc0:0001会变动，在sysfs目录：

    ls /sys/block/mmcblk0/

是存的，可以用这里代替吧。试了下不能用/sys/block/mmcblk0/。

然后发现可以用这个路径：/devices/platform/s3c-sdhci.0/mmc_host/mmc0


