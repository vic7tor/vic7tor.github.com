#1.基本原理
Android.mk其实也就是个makefile，include $()

core/shared_library.mk -> core/dynamic_binary.mk -> core/binary.mk -> core/base_rules.mk

每个Android.mk会生成一个rule。

编译ffmpeg时，只要把Android.mk写成一个有rule的Makefile就行了。这个是从昨天看的编译内核那个AndroidKernel.mk，这个被那个device/qcom/xxx/AndroidBoard.mk这个文件包含。其实所有的*.mk文件最后都会被include成一个超大的Makefile，所以。。

核心的就是core/base_rules.mk中的下面的规则。

.PHONY: $(LOCAL_MODULE)
$(LOCAL_MODULE): $(LOCAL_BUILT_MODULE) $(LOCAL_INSTALLED_MODULE)

$(LOCAL_MODULE)的值被加入PRODUCT_PACKAGES，然后导致$(LOCAL_MODULE)定义的规则就会被执行。

编译ffmpeg时，定义一个这样的规则，这个规则再依赖配置，编译，复制编译好的库就行了。

#2.ffmpeg配置

#3.编译

#4.复制输出到系统目录

