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

# envsetup.sh配置系统导出的环境变量的作用
在envsetup.sh的lunch()中，导出了
	614         export TARGET_PRODUCT=$product
	615         export TARGET_BUILD_VARIANT=$variant
	616         export TARGET_SIMULATOR=false
	617         export TARGET_BUILD_TYPE=release
## TARGET_ARCH_VARIANT是怎么来的
在envsetup.sh中lunch()最后的函数会调用build/core/config.mk
在config.mk中
	129 board_config_mk := \
	130         $(strip $(wildcard \
	131                 $(SRC_TARGET_DIR)/board/$(TARGET_DEVICE)/BoardConfig.mk \
	132                 device/*/$(TARGET_DEVICE)/BoardConfig.mk \
	133                 vendor/*/$(TARGET_DEVICE)/BoardConfig.mk \
	134         ))
在BoardConfig.mk中有啥货呢？你懂的

##上节上TARGET_DEVICE是怎么来的
config.mk包含了envsetup.mk, envsetup.mk包含了product_config.mk。
product_config.mk中:
INTERNAL_PRODUCT := $(call resolve-short-product-name, $(TARGET_PRODUCT))
TARGET_DEVICE := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_DEVICE)
神奇的PRODUCTS.xx.PRODUCT_DEVICE是什么东东？make的结构体有没有听过？
见product.mk
    86 define dump-product
    87 $(info ==== $(1) ====)\
    88 $(foreach v,$(\_product_var_list),\
    89 $(info PRODUCTS.$(1).$(v) := $(PRODUCTS.$(1).$(v))))\
    90 $(info --------)
    91 endef
$(1)就是$1

product_config.mk
$(call import-products, vendor/cyanogen/products/cyanogen_$(CM_BUILD).mk)

product.mk
127 define import-products
128 $(call import-nodes,PRODUCTS,$(1),$(\_product_var_list))
129 endef


## TARGET_ARCH_VARIANT
    combo/TARGET_linux-arm.mk:37:TARGET_ARCH_SPECIFIC_MAKEFILE := $(BUILD_COMBOS)/arch/$(TARGET_ARCH)/$(TARGET_ARCH_VARIANT).mk
arm-v5te.mk
    ARCH_ARM_HAVE_THUMB_SUPPORT     := true
    ARCH_ARM_HAVE_FAST_INTERWORKING := true
    ...
    arch_variant_cflags := \
    -march=armv5te \
    -mtune=xscale  \
    -D__ARM_ARCH_5__ \
    -D__ARM_ARCH_5T__ \
    -D__ARM_ARCH_5E__ \
    -D__ARM_ARCH_5TE__
