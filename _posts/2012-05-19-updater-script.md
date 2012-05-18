---
layout: post
title: "updater-script"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#源代码
关于updater-script相关的源代码，见bootable/recovery/{edify,edifyscripting,updater}
一些东西见[这篇文章](http://tjworld.net/wiki/Android/UpdaterScriptEdifyFunctions)
Android Updater Script Edify Functions
Work In Progress
When Android devices install updates via 'update.zip' files using recovery mode they have to perform a wide range of functions on files and permissions. Instead of using a minimal shell such as {b,d,c}sh the Android designers decided to create a small functional language that can be extended by device manufacturers if necessary. Since the Android "Donut" release (v1.6) the scripting language is called Edify and is defined primarily in the bootable/recovery/{edify,edifyscripting,updater} directories of the Android source-code tree.

There is little to no documentation from Google or the Open Handset Alliance about updater or edify so I am collecting my discoveries and notes about edify here.

Edify Functions and Expressions

Discovering the function names is relatively easy. In the root of the Android platform source-code tree do:

grep -rn  RegisterFunction\(\"  bootable/recovery/* device/* 2>/dev/null | sed -n 's/^.\*RegisterFunction("\(.\*\)",.\*$/\1/p' | sort
Which results in:

abort
apply_patch
apply_patch_check
apply_patch_space
assert
backup_rom
concat
delete
delete_recursive
file_getprop
format
format
getprop
greater_than_int
htc.install_hboot
htc.install_radio
ifelse
install_zip
is_mounted
is_substring
less_than_int
mount
package_extract_dir
package_extract_file
read_file
restore_rom
run_program
run_program
set_perm
set_perm_recursive
set_progress
sha1_check
show_progress
sleep
stdout
symlink
ui_print
ui_print
unmount
write_raw_image

Discovering their arguments and what they do (function names are hopefully descriptive) is slightly more involved since the source code needs to be manually scanned and interpreted.

Updater Function Descriptions

function	 arguments	 implemented by	 source-file
abort	 (\[msg])	 AbortFn	 bootable/recovery/edify/expr.c
apply_patch	 (source_filename, target_filename, target_sha1, target_size, sha1, patch, [[sha1, patch], ...])	 ApplyPatchFn	 bootable/recovery/updater/install.c
apply_patch_check	 (file [[, sha1], ...] )	 ApplyPatchCheckFn	 bootable/recovery/updater/install.c
apply_patch_space		 ApplyPatchSpaceFn	 bootable/recovery/updater/install.c
assert		 AssertFn	 bootable/recovery/edify/expr.c
backup_rom		 BackupFn	 bootable/recovery/edifyscripting.c
concat		 ConcatFn	 bootable/recovery/edify/expr.c
delete		 DeleteFn	 bootable/recovery/updater/install.c
delete_recursive		 DeleteFn	 bootable/recovery/updater/install.c
file_getprop		 FileGetPropFn	 bootable/recovery/updater/install.c
format		 FormatFn	 bootable/recovery/edifyscripting.c
format		 FormatFn	 bootable/recovery/updater/install.c
getprop		 GetPropFn	 bootable/recovery/updater/install.c
greater_than_int		 GreaterThanIntFn	 bootable/recovery/edify/expr.c
htc.install_hboot		 UpdateFn	 device/htc/common/updater/recovery_updater.c
htc.install_radio		 UpdateFn	 device/htc/common/updater/recovery_updater.c
ifelse		 IfElseFn	 bootable/recovery/edify/expr.c
install_zip		 InstallZipFn	 bootable/recovery/edifyscripting.c
is_mounted		 IsMountedFn	 bootable/recovery/updater/install.c
is_substring		 SubstringFn	 bootable/recovery/edify/expr.c
less_than_int		 LessThanIntFn	 bootable/recovery/edify/expr.c
mount		 MountFn	 bootable/recovery/updater/install.c
package_extract_dir		 PackageExtractDirFn	 bootable/recovery/updater/install.c
package_extract_file		 PackageExtractFileFn	 bootable/recovery/updater/install.c
read_file		 ReadFileFn	 bootable/recovery/updater/install.c
restore_rom		 RestoreFn	 bootable/recovery/edifyscripting.c
run_program		 RunProgramFn	 bootable/recovery/edifyscripting.c
run_program		 RunProgramFn	 bootable/recovery/updater/install.c
set_perm_recursive		 SetPermFn	 bootable/recovery/updater/install.c
set_perm		 SetPermFn	 bootable/recovery/updater/install.c
set_progress		 SetProgressFn	 bootable/recovery/updater/install.c
sha1_check		 Sha1CheckFn	 bootable/recovery/updater/install.c
show_progress		 ShowProgressFn	 bootable/recovery/updater/install.c
sleep		 SleepFn	 bootable/recovery/edify/expr.c
stdout		 StdoutFn	 bootable/recovery/edify/expr.c
symlink		 SymlinkFn	 bootable/recovery/updater/install.c
ui_print		 UIPrintFn	 bootable/recovery/edifyscripting.c
ui_print		 UIPrintFn	 bootable/recovery/updater/install.c
unmount		 UnmountFn	 bootable/recovery/updater/install.c
write_raw_image		 WriteRawImageFn	 bootable/recovery/updater/install.c
Function Groups

Patching

The apply_patch* functions apply binary difference patches to existing files on the device. The patches are created using bsdiff, a derivative of which is in the Android source tree at external/bsdiff/. They are applied using bspatch. These tools are available under a BSD License and can be found in most Linux distributions. On Debian/Ubuntu they're in the bsdiff package.


