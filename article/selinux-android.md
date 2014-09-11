#1.system image
MAKE_EXT4FS_CMD='make_ext4fs -s -S out/target/product/msm8974/root/file_contexts -l 838860800 -a system out/target/product/msm8974/obj/PACKAGING/systemimage_intermediates/system.img out/target/product/msm8974/system'

找这个变量可以找到MAKE_EXT4FS_CMD编译的地方吧。

#2.external/sepolicy/Android.mk
 81 $(LOCAL_BUILT_MODULE) : $(sepolicy_policy.conf) $(HOST_OUT_EXECUTABLES)/chec    kpolicy
 82         mkdir -p $(dir $@)
 83         $(HOST_OUT_EXECUTABLES)/checkpolicy -M -c $(POLICYVERS) -o $@ $<
 84         $(HOST_OUT_EXECUTABLES)/checkpolicy -M -c $(POLICYVERS) -o $(dir $<)    /$(notdir $@).dontaudit $<.dontaudit
 85 


out/host/linux-x86/bin/checkpolicy -M -c 26 -o out/target/product/msm8974/obj/ETC/sepolicy_intermediates/sepolicy out/target/product/msm8974/obj/ETC/sepolicy_intermediates/policy.conf

out/host/linux-x86/bin/checkpolicy -M -c 26 -o out/target/product/msm8974/obj/ETC/sepolicy_intermediates//sepolicy.dontaudit out/target/product/msm8974/obj/ETC/sepolicy_intermediates/policy.conf.dontaudit

policy.conf是由下面的生成的：

 73 sepolicy_policy.conf := $(intermediates)/policy.conf
 74 $(sepolicy_policy.conf): PRIVATE_MLS_SENS := $(MLS_SENS)
 75 $(sepolicy_policy.conf): PRIVATE_MLS_CATS := $(MLS_CATS)
 76 $(sepolicy_policy.conf) : $(call build_policy, security_classes initial_sids     access_vectors global_macros mls_macros mls policy_capabilities te_macros a    ttributes *.te roles users initial_sid_contexts fs_use genfs_contexts port_c    ontexts)

