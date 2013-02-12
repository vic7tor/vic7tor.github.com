---
layout: post
title: "Android Build System"
description: ""
category: 
tags: []
---
{% include JB/setup %}
研究这个的动机是搞清楚CM编译时为什么少/etc/下那些字体配置文件，还有像init.usb.rc这样的文件。

在此之前又去研究了一下make，这篇文章也作为make的实战了。

#make -p
强大的功能。

1.可以显示Makefile变量在哪个文件中哪行赋值。这个赋值也是记录的最后一次赋值的结果，使用+=赋值的，前面的就不会记下来了。

2.可以显示Makefile中所有的规则。规则的target、prerequisite、recipe的具体形式，那些变量表示的都换成了具体值。对于recipe还会显示在Makefile中哪行定义，这个可以用来方便的定位规则在哪定义。对于没有recipe的规则，只能用`target:`这样的格式来grep了。

#ABS
默认目标为droid，这点看来，Makefile也有声明与实现这样的概念，声明就是`target:`这样的格式。

#droid
droidcore的先决条件是droidcore和dist_files(看了下这个没有作用），所以droid就相当于droidcore。

    .PHONY: droidcore
    droidcore: files \
        systemimage \
        $(INSTALLED_BOOTIMAGE_TARGET) \
        $(INSTALLED_RECOVERYIMAGE_TARGET) \
        $(INSTALLED_USERDATAIMAGE_TARGET) \
        $(INSTALLED_CACHEIMAGE_TARGET) \
        $(INSTALLED_FILES_FILE) installed-files.txt这个文件

##systemimage的生成
刚开始纠结了很久这个东东，因为刚始只看到了`system.img:`后面那一大堆依赖列表，还从编译输出上研究这个system.img是怎么生成的。直到后来无意间看到`system.img:`后面那一大堆依赖之后，居然还有重复的这些内容，后面仔细一看原来是那些自动变量的值，继续翻，我居然发现了recipe这个东东，生成system.img的命令就摆在这了。

所以一切都简单了。

    systemimage_intermediates := \
        $(call intermediates-dir-for,PACKAGING,systemimage)
    BUILT_SYSTEMIMAGE := $(systemimage_intermediates)/system.img
    
    # $(1): output file
    define build-systemimage-target
      @echo "Target system fs image: $(1)"
      @mkdir -p $(dir $(1)) $(systemimage_intermediates) && rm -rf $(systemimage_intermediates)/system_image_info.txt
      $(call generate-userimage-prop-dictionary, $(systemimage_intermediates)/system_image_info.txt)
      $(hide) PATH=$(foreach p,$(INTERNAL_USERIMAGES_BINARY_PATHS),$(p):)$$PATH \
          ./build/tools/releasetools/build_image.py \
          $(TARGET_OUT) $(systemimage_intermediates)/system_image_info.txt $(1)
    endef
    
    $(BUILT_SYSTEMIMAGE): $(FULL_SYSTEMIMAGE_DEPS) $(INSTALLED_FILES_FILE)
        $(call build-systemimage-target,$@)

###img类型生成
generate-userimage-prop-dictionary生成的东东传给build_image.py

    define generate-userimage-prop-dictionary
    $(if $(INTERNAL_USERIMAGES_EXT_VARIANT),$(hide) echo "fs_type=$(INTERNAL_USERIMAGES_EXT_VARIANT)" >> $(1))
    $(if $(BOARD_SYSTEMIMAGE_PARTITION_SIZE),$(hide) echo "system_size=$(BOARD_SYSTEMIMAGE_PARTITION_SIZE)" >> $(1))
    $(if $(BOARD_USERDATAIMAGE_PARTITION_SIZE),$(hide) echo "userdata_size=$(BOARD_USERDATAIMAGE_PARTITION_SIZE)" >> $(1))
    $(if $(BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE),$(hide) echo "cache_fs_type=$(BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE)" >> $(1))
    $(if $(BOARD_CACHEIMAGE_PARTITION_SIZE),$(hide) echo "cache_size=$(BOARD_CACHEIMAGE_PARTITION_SIZE)" >> $(1))
    $(if $(INTERNAL_USERIMAGES_SPARSE_EXT_FLAG),$(hide) echo "extfs_sparse_flag=$(INTERNAL_USERIMAGES_SPARSE_EXT_FLAG)" >> $(1))
    $(if $(mkyaffs2_extra_flags),$(hide) echo "mkyaffs2_extra_flags=$(mkyaffs2_extra_flags)" >> $(1))
    $(if $(filter true, $(strip $(HAVE_SELINUX))), echo "selinux_fc=$(TARGET_ROOT_OUT)/file_contexts" >> $(1))
    endef
    
    INTERNAL_USERIMAGES_EXT_VARIANT :=
    ifeq ($(TARGET_USERIMAGES_USE_EXT2),true)
    INTERNAL_USERIMAGES_USE_EXT := true
    INTERNAL_USERIMAGES_EXT_VARIANT := ext2
    else
    ifeq ($(TARGET_USERIMAGES_USE_EXT3),true)
    INTERNAL_USERIMAGES_USE_EXT := true
    INTERNAL_USERIMAGES_EXT_VARIANT := ext3


##files

    .PHONY: files
    files: prebuilt \ 
        $(modules_to_install) \
        $(INSTALLED_ANDROID_INFO_TXT_TARGET) android-info.txt这个文件

###prebuilt

    .PHONY: prebuilt
    prebuilt: $(ALL_PREBUILT)

ALL_PREBUILT这个变量的值。

ALL_PREBUILT的依赖列表出现的东东变成的target的recipe为，transform-prebuilt-to-target是一个加了echo的中间步骤：

    define copy-file-to-target
    @mkdir -p $(dir $@)
    $(hide) $(ACP) -fp $< $@
    endef

看一个实例：

    file := $(TARGET_ROOT_OUT)/init.rc
    $(file) : $(LOCAL_PATH)/init.rc | $(ACP)
        $(transform-prebuilt-to-target)
    ALL_PREBUILT += $(file)

file是一个规则，同时也被加到ALL_PREBUILT里面去了。

`$(transform-prebuilt-to-target)这种形式与$(call ...)这种形式不同的地方应该在，第一种可以访问自动变量，第二种可以访问$(1)这样的变量。`

###$(modules_to_install)

modules_to_install这个变量的赋值就是build/core/main.mk中了。

最主要的应该是这个：

    modules_to_install := $(sort $(Default_MODULES) \
          $(foreach tag,$(tags_to_install),$($(tag)_MODULES)))

####Default_MODULES:

    Default_MODULES := $(sort $(ALL_DEFAULT_INSTALLED_MODULES) \
                          $(CUSTOM_MODULES))

ALL_DEFAULT_INSTALLED_MODULES为PRODUCT_COPY_FILES变量的值再加上default.prop、build.prop再加上点不怎么重要的东西。

CUSTOM_MODULES在其引用之前值已为空，从make -p结果来看，排除了make -p显示最后一次赋值的影响。

####$($(tag)_MODULES))
tags_to_install := user debug eng

    user_MODULES := $(sort $(call get-tagged-modules,user shell_$(TARGET_SHELL)))
    user_MODULES := $(user_MODULES) $(user_PACKAGES)

$(user_PACKAGES)见后面PRODUCT_PACKAGES

`shell_$(TARGET_SHELL)`在这次编译过程中值为shell_mksh，和user一样也是一个TAG。

framework.jar也就在user_MODULES的第一个赋值中。

    # makefile (从“build/core/definitions.mk”，行 650)
    get-tagged-modules = $(filter-out $(call modules-for-tag-list,$(2)), $(call modules-for-tag-list,$(1)))

    modules-for-tag-list = $(sort $(foreach tag,$(1),$(ALL_MODULE_TAGS.$(tag))))

ALL_MODULE_TAGS.user，走到这个变量暂时断线了。这个变量的赋值形式是：

    $(foreach tag,$(LOCAL_MODULE_TAGS),\
    $(eval ALL_MODULE_TAGS.$(tag) := \
            $(ALL_MODULE_TAGS.$(tag)) \
            $(LOCAL_INSTALLED_MODULE)))

LOCAL_MODULE_TAGS的赋值居然是tests，那ALL_MODULE_TAGS.user怎么赋值啊。

所以，现在是时候去探索下Android中各种Android.mk是如何工作的了。

#Android.mk
来一个创建可执行文件的列子吧。

    LOCAL_PATH:= $(call my-dir)
    include $(CLEAR_VARS)

    LOCAL_SRC_FILES:= \
    ...
    init.c \
    ...

    LOCAL_MODULE:= init

    LOCAL_STATIC_LIBRARIES := libfs_mgr libcutils libc

    include $(BUILD_EXECUTABLE)

CLEAR_VARS := build/core/clear_vars.mk

BUILD_EXECUTABLE := build/core/executable.mk

这两个都是在build/core/config.mk中赋值的。

`include $(CLEAR_VARS)`把一些变量赋值为空。

重头戏就是`include $(BUILD_EXECUTABLE)`了。

##Android.mk的include
下面的语句就把所有的Android.mk include进来。

    subdir_makefiles := \
        $(shell build/tools/findleaves.py --prune=out --prune=.repo --prune=.git $(subdirs) Android.mk)

    include $(subdir_makefiles)

##include $(BUILD_EXECUTABLE)
现在就要看看Android编译系统的神奇之处了。

###build/core/executable.mk

    ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
    LOCAL_MODULE_CLASS := EXECUTABLES
    endif
    ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
    LOCAL_MODULE_SUFFIX := $(TARGET_EXECUTABLE_SUFFIX)
    endif
    
    include $(BUILD_SYSTEM)/dynamic_binary.mk
    
    ifeq ($(LOCAL_FORCE_STATIC_EXECUTABLE),true)
    $(linked_module): $(TARGET_CRTBEGIN_STATIC_O) $(all_objects) $(all_libraries) $(TARGET_CRTEND_O)
            $(transform-o-to-static-executable)
    else
    $(linked_module): $(TARGET_CRTBEGIN_DYNAMIC_O) $(all_objects) $(all_libraries) $(TARGET_CRTEND_O)
            $(transform-o-to-executable)
    endif

linked_module那就是定义Makefile的规则了。


###build/core/dynamic_binary.mk
这里面定义了$(linked_module)变量的值。

还有一些规则，压缩、符号什么的，看起来没有什么用。

还有一个用来clean的规则。这个规则没有给出recipe，只是定义的一个变量，像规则的声明一样，是一个target在多个地方定义所允许的。真正的规则在base_rules.mk中定义。

###build/core/binary.mk

$(all_objects)的定义

$(c_objects)规则的定义，用来把C源文件变成object文件。

    $(c_objects): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.c $(yacc_cpps) $(proto_generated_headers) \
        $(my_compiler_dependencies) $(LOCAL_ADDITIONAL_DEPENDENCIES)
            $(transform-$(PRIVATE_HOST)c-to-o)
    -include $(c_objects:%.o=%.P) 这一句是依赖的处理吧

###build/core/base_rules.mk
####`cleantarget := clean-$(LOCAL_MODULE)`这个可以用来清理模块。

####$(LOCAL_MODULE): $(LOCAL_BUILT_MODULE) $(LOCAL_INSTALLED_MODULE)
像init会生成：

    init: /home/victor/embed/android/cm/out/target/product/tiny210/obj/EXECUTABLES/init_intermediates/init /home/victor/embed/android/cm/out/target/product/tiny210/root/init

LOCAL_BUILT_MODULE、LOCAL_INSTALLED_MODULE也是在这个文件中定义的。

`Makefile中的规则定义了，但是如果没有别的目标依赖它，这个规则也不会起作用`

所以在Android.mk之前分析断点那：

    $(foreach tag,$(LOCAL_MODULE_TAGS),\
        $(eval ALL_MODULE_TAGS.$(tag) := \
            $(ALL_MODULE_TAGS.$(tag)) \
            $(LOCAL_INSTALLED_MODULE)))

这个就是相当于ALL_MODULE_TAGS.$(tag) += $(LOCAL_INSTALLED_MODULE)的赋值。

在这里就解决了为什么这些文件为什么会被编译安装。

在base_rules.mk这个文件中，如果TAG没有定义，在这个文件中也会设定值。

#PRODUCT_PACKAGES

    user_PACKAGES := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES)
    $(call expand-required-modules,user_PACKAGES,$(user_PACKAGES))
    user_PACKAGES := $(call module-installed-files, $(user_PACKAGES))

user_PACKAGES在哪里引用见上面。

##build/core/product_config.mk

    ifneq ($(strip $(TARGET_BUILD_APPS)),)
      # An unbundled app build needs only the core product makefiles.
      $(call import-products,$(call get-product-makefiles,\
          $(SRC_TARGET_DIR)/product/AndroidProducts.mk))
    else
      ifneq ($(CM_BUILD),)
        $(call import-products, device/*/$(CM_BUILD)/cm.mk)
      else
      # Read in all of the product definitions specified by the AndroidProducts.mk
        # files in the tree.
        #
        #TODO: when we start allowing direct pointers to product files,
        #    guarantee that they're in this list.
        $(call import-products, $(get-all-product-makefiles))
      endif
    endif # TARGET_BUILD_APPS

看到这段代码，我原来总以为会像Android.mk里一样把所有AndroidProducts.mk里定义的PRODUCT_PACKAGES这样的变量+=起来。因为import-products这个函数很难看懂。import-products应该只是定义_nic.PRODUCT这样的变量。

import-products生成了$(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES)这样的变量，所有的PRODUCT_MAKEFILES指向的文件都会生这样格式的变量。

但是这个文件后面引用的都是$(INTERNAL_PRODUCT)的。

    TARGET_PRODUCT = cm_tiny210
    INTERNAL_PRODUCT := $(call resolve-short-product-name, $(TARGET_PRODUCT))
    
    PRODUCT_BRAND := $(strip $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_BRAND))
    
import-products并不会对PRODUCT_PACKAGES这样的变量造成影响。真正对import-products造成影响的是inherit-product

上面这句话似乎不是十分正确。inherit-product似乎是在import-products执行的，只有研究下import-nodes才能下定论了。见后面的分析。

##core/main.mk
user_PACKAGES := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES)

##inherit-product

    define inherit-product
      $(foreach v,$(_product_var_list), \
          $(eval $(v) := $($(v)) $(INHERIT_TAG)$(strip $(1)))) \
      $(eval inherit_var := \
          PRODUCTS.$(strip $(word 1,$(_include_stack))).INHERITS_FROM) \
      $(eval $(inherit_var) := $(sort $($(inherit_var)) $(strip $(1)))) \
      $(eval inherit_var:=) \
      $(eval ALL_PRODUCTS := $(sort $(ALL_PRODUCTS) $(word 1,$(_include_stack))))
    endef

ALL_PRODUCTS就存着所有inherit-product的文件。

##import-products

非常复杂的一个函数，画了个图来分析。分析过太花脑力了。是在这个函数中include inherit-product那些文件的。

这个函数的实现机制就不详细讲了，太长了。

##关于cm编译少文件的原因
import-products分析到其中一个函数时，想看变量内容。最后找到了warning这个函数用来显示变量的值。

显示变量的值时就看那个PRODUCT_COYP_FILES，inherit-product(会在变量中加INHERIT_TAG)完全没有启作用，最后才让我看到了PRODUCT_COPY_FILES是用`:=`赋值的。

所以，`在inherit-product之后使用PRODUCT_COPY_FILES这些变量时就不能用:=了`不然就覆盖了inherit-product的值。

#PRODUCT_COPY_FILES

##build/core/Makefile:

    unique_product_copy_files_pairs :=
    $(foreach cf,$(PRODUCT_COPY_FILES), \
        $(if $(filter $(unique_product_copy_files_pairs),$(cf)),,\
            $(eval unique_product_copy_files_pairs += $(cf))))
    unique_product_copy_files_destinations :=
    $(foreach cf,$(unique_product_copy_files_pairs), \
        $(eval _src := $(call word-colon,1,$(cf))) \
        $(eval _dest := $(call word-colon,2,$(cf))) \
        $(if $(filter $(unique_product_copy_files_destinations),$(_dest)), \
            $(info PRODUCT_COPY_FILES $(cf) ignored.), \
            $(eval _fulldest := $(call append-path,$(PRODUCT_OUT),$(_dest))) \
            $(if $(filter %.xml,$(_dest)),\
                $(eval $(call copy-xml-file-checked,$(_src),$(_fulldest))),\
                $(eval $(call copy-one-file,$(_src),$(_fulldest)))) \
            $(eval ALL_DEFAULT_INSTALLED_MODULES += $(_fulldest)) \
            $(eval unique_product_copy_files_destinations += $(_dest))))
    unique_product_copy_files_pairs :=
    unique_product_copy_files_destinations :=

ALL_DEFAULT_INSTALLED_MODULES、copy-xml-file-checked、copy-one-file

    define copy-one-file
    $(2): $(1) | $(ACP)
            @echo -e ${CL_YLW}"Copy:"${CL_RST}" $$@"
            $$(copy-file-to-target)
    endef

    Default_MODULES := $(sort $(ALL_DEFAULT_INSTALLED_MODULES) \
                          $(CUSTOM_MODULES))

Default_MODULES见上面
