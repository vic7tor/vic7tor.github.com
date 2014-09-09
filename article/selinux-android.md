#1.system image
MAKE_EXT4FS_CMD='make_ext4fs -s -S out/target/product/msm8974/root/file_contexts -l 838860800 -a system out/target/product/msm8974/obj/PACKAGING/systemimage_intermediates/system.img out/target/product/msm8974/system'

找这个变量可以找到MAKE_EXT4FS_CMD编译的地方吧。

#2.external/sepolicy/Android.mk

