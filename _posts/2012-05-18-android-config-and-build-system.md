---
layout: post
title: "Android Config And Build System"
description: ""
category: android
tags: [android]
---
{% include JB/setup %}

# config -- build/envsetup.sh
## lunch command can choose
build/envsetup.sh:breakfast()->vendor/cyanogen/vendorsetup.sh->build/envsetup.sh:add_lunch_combo()
## how device/motorola/jordan/vendorsetup.sh be included
in build/envsetup.sh
        1599 # Execute the contents of any vendorsetup.sh files we can find.
        1600 for f in \`{ setopt nullglob; /bin/ls vendor/\*/vendorsetup.sh vendor/\*/build     /vendorsetup.sh device/\*/\*/vendorsetup.sh; } 2> /dev/null\`
## envsetup.sh function
To setup env var like:
    PLATFORM_VERSION_CODENAME=REL
    PLATFORM_VERSION=2.3.7
    TARGET_PRODUCT=cyanogen_jordan
    TARGET_BUILD_VARIANT=eng
    TARGET_SIMULATOR=false
    TARGET_BUILD_TYPE=release
    TARGET_BUILD_APPS=
    TARGET_ARCH=arm
    TARGET_ARCH_VARIANT=armv7-a-neon
    HOST_ARCH=x86
    HOST_OS=linux
    HOST_BUILD_TYPE=release
    BUILD_ID=GINGERBREAD

# build 
command mka invoke *make* infact
Makefile at top dir of source code only has one line: include build/core/main.mk
## how Android.mk work
    else # ONE_SHOT_MAKEFILE
    \#
    \# Include all of the makefiles in the system
    \#

    \# Can't use first-makefiles-under here because
    \# --mindepth=2 makes the prunes not work.
    subdir_makefiles := \
    $(shell build/tools/findleaves.py --prune=out --prune=.repo --prune=.git $(subdirs) Android.mk)
    include $(subdir_makefiles)
    endif # ONE_SHOT_MAKEFILE
## include $(BUILD_STATIC_LIBRARY)
    config.mk:57:BUILD_STATIC_LIBRARY:= $(BUILD_SYSTEM)/static_library.mk
    raw_static_library.mk:4:include $(BUILD_STATIC_LIBRARY)
## main.mk include some *.mk files
AndroidBoard.mk Boardconfig.mk use grep in build/core

