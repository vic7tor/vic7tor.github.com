---
layout: post
title: "initramfs"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#initrd与initramfs的区别
老外的文章有讲了。initrd是老式的，ext2格式的一种东东。initramfs就是一个cpio档。initrd是内核挂载的一个临时文件系统。内核后面会挂载真正的根文件系统。而initramfs被内核挂载后，控制权就交给了initramfs里的程序。最后由initramfs里的init最后调用switch_root切换到内核root参数指向的根文件系统。switch_root是一个程序，会挂载真正的根文件系统。并exec里面的init程序。

#initramfs的解压与制作
制作：

    cd RAMFSDIR && find . | cpio -H newc -o | gzip > ../ramfs.gz

解压：

    先gunzip -S img ./initramfs-linux-lts.img
    建一个文件夹
    cpio -i -d < ../initramfs-linux-lts

#initramfs中的init
见后面老外文件中那个脚本吧

#内核配置与参数
配置：

    General setup->Initial Ram filesystem and RAM disk要支持initrd的话还要开个驱动在Block device里，不用这个，所以就不写了。

参数：

    initrd=ramoffset,size size也需要是正确的


#内核中的文档
Documentation/filesystems/ramfs-rootfs-initramfs.txt

#附抄老外一篇文章了
来自

#What is an initramfs?

An initramfs is an early userspace. The kernel will load this into a tmpfs space before it boots your real system. This allows for more difficult and complex boot options such as LVM-on-root, booting from an NFS mount, etc. You could even run an entire full linux system from within an initramfs if you so chose. (see http://www.tinycorelinux.com for an example of this)

#What is the real difference between an initramfs and an initrd (initramdisk)?

While both an initramfs and an initrd serve the same purpose, there are 2 differences. The most obvious difference is that an initrd is loaded into a ramdisk. It consists of an actual filesystem (typically ext2) which is mounted in a ramdisk. An initramfs, on the other hand, is not a filesystem. It is simply a (compressed) cpio archive (of type newc) which is unpacked into a tmpfs. This has a side-effect of making the initramfs a bit more optimized and capable of loading a little earlier in the kernel boot process than an initrd. Also, the size of the initramfs in memory is smaller, since the kernel can adapt the size of the tmpfs to what is actually loaded, rather than relying on predefined ramdisk sizes, and it can also clean up the ram that was used whereas ramdisks tend to remain in use (due to details of the pivot_root implementation).

There is also another side-effect difference: how the root device (and switching to it) is handled. Since an initrd is an actual filesystem unpacked into ram, the root device must actually be the ramdisk. For an initramfs, there is a kernel "rootfs" which becomes the tmpfs that the initramfs is unpacked into (if the kernel loads an initramfs; if not, then the rootfs is simply the filesystem specified via the root= kernel boot parameter), but this interim rootfs should not be specified as the root= boot parameter (and there wouldn't be a way to do so, since there's no device attached to it). This means that you can still pass your real root device to the kernel when using an initramfs. With an initrd, you have to process what the real root device is yourself. Also, since the "real" root device with an initrd is the ramdisk, the kernel has to really swith root devices from one real device (the ramdisk) to the other (your real root). In the case of an initramfs, the initramfs space (the tmpfs) is not a real device, so the kernel doesn't switch real devices. Thus, while the command pivot_root is used with an initrd, a different command has to be used for an initramfs. Busybox provides switch_root to accomplish this, while klibc offers new_root. This article will focus on busybox (and ignore klibc), and this will be covered in more detail later.

#What does an initramfs need?

The initramfs will load before the root filesystem (whatever this happens to be). Therefore, it will need whatever binaries are necessary for booting into the real root filesystem, as well as any extra features that are required/wanted. For example, if the real root filesystem is an LVM device, then the lvm binary will be needed. If any of the binaries needed to boot the real system rely on any dynamic libraries, then those libraries will also be needed. For a very simple initramfs using busybox (where only busybox plus static-only binaries, if any, are present), the only requirements are some default directories, busybox itself, the /init script (required to be /init and not a symlink, unless you hack switch_root or use a development version of busybox), and the static binaries you would like to include. This results in a very small initramfs.

#Structure of an initramfs

A basic initramfs can get by with the following directories:

/bin
/dev
/etc
/lib
/proc
/sbin (can be symlinked to /bin for simplicity)
/sys
/tmp
/usr
/usr/bin (can be symlinked to /bin for simplicity)
/usr/sbin (can be symlinked to /bin for simplicity)
/var
Since the initramfs we will be discussing here will be used in a purely pragmatic way to boot the real system, we don't particularly care if all of our directories match the FHS, and thus we can use symlinks to make it simpler (just put everything in /bin). Also, we technically don't need /dev, /tmp, /sys, or /proc, since these could all be created at run-time. I include them here (and in my own initramfs, though I also ensure that the directories exist in my /init script) for completeness.

As for the binaries that are absolutely required, the list below provides everything needed for an absolute minimum initramfs (note: this only covers busybox; for klibc you are on your own):

/bin/busybox
/init
That's it! It's really that simple. Busybox is capable of generating symlinks to all its applet functions at runtime (busybox --install -s), but you can also run all its applets via 'busybox applet_name', e.g. 'busybox ls /bin'. As long as you configure busybox properly, you probably won't need much else. Which brings us to our next section...

#Configuring busybox

I like to keep things minimal, so I spend a fair amount of time going through my busybox config and turning off whatever I don't need. You are free to do the same (in which case you will need to heed the information below), or you can just include the whole kitchen sink with it, in which case you can skip to the next section.

If you are going to tweak your busybox config, then the things you will minimally need are (anything marked as REQUIRED can be provided by an out-of-busybox real binary, but you must make sure that you include not only that binary in your initramfs, but also all dynamic libraries it depends on):

shell support - REQUIRED - you must have at least one shell
dmesg - recommended - useful for debugging kernel boot problems and finding devices
lsmod - recommend - useful to debug which modules are actually loaded
mdev - highly recommended - unless you want a static /dev tree
mkdir - recommended for emergencies
modprobe - highly recommended - unless you are sure you have everything builtin
mount - REQUIRED
switch_root - REQUIRED - you will not be able to boot into your real root filesystem without this (though you can load your system without this)
umount - REQUIRED
vi - recommended - a text editor is always helpful. Feel free to use whatever text editor you prefer, but a version of vi is included in busybox.
Of course there are other applets that you should probably have, but I will leave the remainder as an exercise to the reader.

#The /init script for the initramfs

The /init script must perform several functions. First, in order for basic functionality, at least /proc must be mounted. You should also mount /sys, but it's not always required. Then, if you have chosen to have a dynamic /dev tree (which is quite simple to do when using mdev), in which case /sys must be mounted. This concludes what the /init script must do for startup. After this, you can do whatever extra processing you need.

In order to switch over to the new system, the /init script must mount the real root filesystem to some directory (the example here will use /newroot as the mount point), unmount /dev, /sys, and /proc (or mount --move them to /newroot, if your real init system does not error out if they are already mounted), and then exec switch_root.

I will here include my own initramfs /init script, which is both fairly generalized and quite minimal, so it should be easy to adapt to other needs.


    ################################################################################
    # This script is meant to be run as the "init" script of an initramfs, which
    # should be a writable filesystem (tmpfs or ramfs, tmpfs preferred).
    #
    # DO NOT ATTEMT TO RUN THIS IN AN INITRD (ramdisk) without modification
    #
    ################################################################################
    
    PATH="/bin:/sbin:/usr/bin:/usr/sbin"
    
    # Path to directory to mount $ROOTDEV under in initrd
    NEWROOT="/newroot"
    
    # Commands used in this initrd script
    # Hardcode busybox to ensure availability of commands when /proc isn't
    # mounted or symlinks aren't made yet
    BBINSTALL="/bin/busybox --install -s"
    CAT="/bin/busybox cat"
    CHMOD="/bin/busybox chmod"
    MOUNT="/bin/busybox mount"
    UMOUNT="/bin/busybox umount"
    SHELL="/bin/busybox sh"
    MKDIR="/bin/busybox mkdir"
    GREP="/bin/busybox grep"
    AWK="/bin/busybox awk"
    SWITCH="/bin/busybox switch_root"
    
    # mdev (busybox symlinks should be usable when using this)
    MDEV="/bin/mdev"
    
    # Kernel command-line (convenience variable)
    KCMD="/proc/cmdline"
    
    # Function for dropping to a shell
    shell () {
     echo ''
     echo ' Entering rescue shell.'
     echo ' Type rootdev root_device to set device to boot.'
     echo ' ex: rootdev /dev/sda1'
     echo ' Exit shell to continue booting.'
     $SHELL
    }
    
    
    # Create rootdev function
    echo '#!/bin/sh' > /bin/rootdev
    echo 'echo "$1" > /rootdev' >> /bin/rootdev
    echo 'exit $?' >> /bin/rootdev
    $CHMOD 0755 /bin/rootdev
    RDEV="/bin/rootdev"
    
    
    # EXECUTION BEGINS HERE
    echo "Entering initramfs"
    
    # install all busybox symlinks before doing anything else
    # /proc still needs to be mounted before the symlinks will work
    echo "Creating busybox symlinks"
    $BBINSTALL
    
    # Ensure that basic directories exist
    for dir in /proc /sys /dev
    do
     [ -d $dir ] || $MKDIR $dir
    done
    
    # Mount /proc, necessary for other mounts
    echo "Mounting procfs"
    $MOUNT -t proc proc /proc
    
    # Mount /sys, necessary to create the device mapper control device
    echo "Mounting sysfs"
    $MOUNT -t sysfs sys /sys
    
    # Mount tmpfs on /dev and set up /dev/pts
    echo "Mounting tmpfs on /dev and running mdev ..."
    $MOUNT -t tmpfs dev /dev
    $MKDIR -p /dev/pts
    $MOUNT -t devpts devpts /dev/pts
    # Run mdev and populate /dev with device nodes
    echo "$MDEV" > /proc/sys/kernel/hotplug
    $MDEV -s
    
    # Drop to shell if "shell" was passed as kernel param
    $GREP -q 'shell' /proc/cmdline && shell
    
    # Get the args to pass to init, minus key=val pairs
    INIT_ARGS="$($AWK '{gsub(/[[:graph:]]+=[[:graph:]]+/,""); print}' $KCMD)"
    # remove any initramfs commands from INIT_ARGS
    INIT_ARGS="$(echo $INIT_ARGS | $AWK '{gsub(/noresume/,""); print}')"
    INIT_ARGS="$(echo $INIT_ARGS | $AWK '{gsub(/shell/,""); print}')"
    
    # Init to run after switch_root to real system
    INIT="$($AWK '/.*init=/ {sub(/.*init=/,""); sub(/[ ].*/,""); print}' $KCMD)"
    INIT="${INIT:-/sbin/init}"
    
    # Get the default root device if it exists on the kernel command-line
    RTDEV="$($AWK '/root=/ {sub(/.*root=/,""); sub(/[ ].*/,""); print}' $KCMD)"
    
    # check if /rootdev is empty or missing
    if [ ! -s /rootdev ]
    then
     # Get root dev from kernel boot command-line
     # uses some awk magic to extract first "root=.*",
     # then extracts the ".*" from within that
     $RDEV "$RTDEV" || echo "Failed to make /rootdev"
    fi
    
    # Check if ROOTDEV is a number (major and minor)
    if [ ! $($GREP -q '^/dev/.*' /rootdev) ]
    then
     # get the major number (first digit only)
     MAJOR="$($AWK '{ print substr($0,1,1) }' /rootdev)"
    
     # get the minor number (everything after the first digit)
     MINOR="$($AWK '{ print substr($0,2) }' /rootdev)"
     # make sure the minor number doesn't have leading 0's
     MINOR="$(echo $MINOR | $AWK '{ sub(/^0+/,"",$0); print $0 }')"
    
     # get the /dev node name using the major and minor numbers by
     # looking it up in /proc/diskstats
     DISKS="/proc/diskstats"
     BOOT="$($AWK '$1 ~'$MAJOR' && $2 ~'$MINOR' { print $3 }' $DISKS)"
     $RDEV "/dev/$BOOT"
    fi
    
    # Mount the root partition
    # ensure that the directory we mount to exists
    SUCCESS=0
    [ -d "$NEWROOT" ] || $MKDIR "$NEWROOT"
    while [ $SUCCESS -ne 1 ]
    do
     ROOTDEV="$($CAT /rootdev)"
     if ! $MOUNT -o ro "$ROOTDEV" "$NEWROOT"
     then
     echo ""
     echo "Couldn't mount root FS read-only!"
     echo "Tell me your root device by doing:"
     echo "rootdev YOUR_ROOT_DEVICE"
     shell
     else
     SUCCESS=1
     fi
    done
    
    if [ ! -e "$NEWROOT/$INIT" ]
    then
     echo ""
     echo "$ROOTDEV successfully mounted but no $INIT found!"
     shell
    fi
    
    # Reset kernel hotplugging
    echo "Resetting kernel hotplugging"
    echo "" > /proc/sys/kernel/hotplug
    
    # Umount /sys
    echo "Unmounting /sys"
    $UMOUNT /sys
    
    # Umount /dev tree
    echo "Unmounting /dev"
    $UMOUNT /dev/pts &&
    $UMOUNT /dev
    
    # Umount /proc
    echo "Unmounting /proc"
    $UMOUNT /proc
    
    # Change to the new root partition and execute /sbin/init
    echo "Executing switch_root and spawning init"
    if ! exec $SWITCH "$NEWROOT" "$INIT" $INIT_ARGS
    #if ! exec $SWITCH "$NEWROOT" "$INIT" "$@"
    then
     echo ""
     echo "Couldn't switch_root"
     $MOUNT -t proc proc /proc
     exec $SHELL
    fi
The script will read the root device to boot into from the kernel boot command-line (the value of the boot parameter root=). However, should it fail for whatever reason, the script will drop to a shell where the user can execute rootdev (as shown below) to manually specify which device to mount and boot into. Note that rootdev is a very simple shell script which is created at run-time as a convenience. You could just as well create the /rootdev file manually, and do without the rootdev script if you were so inclined.


rootdev /dev/YOUR_ROOT_DEVICE
Additionally, if you pass "shell" on the boot commandline, the script will drop to a rescue shell right after it has finished initializing mdev (the busybox equivalent of udev), populating the /dev tree with device nodes. This is handy for debugging not only the initramfs itself, but also the system to be booted. It could also be used for more complicated setups, such as early initialization of a wireless NIC and running wpa_supplicant, and passing user and password information on the commandline in order to negotiate with a wireless access point to boot from the network (NFS, etc.).

#Building the Initramfs

There are different methods for building an initramfs once you have the structure set up.

manually by hand
using scripts/packages
automatically in the kernel
##Building by hand

To create an initramfs by hand, you need a listing of the files to bundle passed into cpio (along with an option specifying the cpio archive format), and then you need to compress this (with gzip).

A simple one-liner can accomplish this for you (change RAMFSDIR to match your initramfs source directory):


    cd RAMFSDIR && find . | cpio -H newc -o | gzip > ../ramfs.gz
*NOTE: modern kernels allow for different compression algorithms, which are configured during the kernel compilation. To my knowledge, zip (i.e., gzip), bzip2, and lzma are all supported by the kernel, but each can be enabled/disabled individually. You can use whatever you wish, just make sure your kernel supports it. For the purpose of this document, gzip will be assumed.

The cd is needed because the cpio command (to my knowledge) cannot remap file paths (if you pass in /home/foo/bar, it gets stored as /home/foo/bar; passing everything in as ./foo/bar ensures that it will be unpacked correctly later). Once we have the ramfs source directory as our working directory, we run find to get a recursive listing of all the files, and pipe the output to the cpio program. The kernel requires the cpio newc format, so we pass -H newc. Finally, the output of cpio is piped to gzip (with flags for highest compression and write to stdout), which redirects the compressed output to the file ramfs.gz in the parent directory of RAMFSDIR.

Store the final product somewhere (typically /boot/). You will probably want to add the final initramfs to your bootloader's config (e.g., initrd=/boot/ramfs.gz).

##Building via scripts/packages

There is of course the linux-initramfs spell. However, that uses klibc rather than busybox, so I'm not going to mention anything more about it here, since this article focuses on busybox.

Alternatively, you can use the gen_initramfs_list.sh script from your kernel source directory:


sh scripts/gen_initramfs_list.sh -o <initramfs output file> <your initramfs source dir or file>
Then include the initramfs output file (typically you would use /boot/ramfs.gz or similar) in your bootloader config (e.g., initrd=/boot/ramfs.gz).

Building directly into your kernel

Creating the initramfs can be easily done by setting


CONFIG_INITRAMFS_SOURCE="/path/to/initramfs"
in your kernel config. /path/to/initramfs can be either a directory containing all the needed files and dirs to be included in the initramfs, or be a file which contains a list of files and dirs to include. If you are using the list file, it must be in a special format. (see the linux-initramfs spell for examples). This will incorporate the initramfs directly into your kernel during build, so you shouldn't include an "initrd=" command in your bootloader config to load it.

Suspend to Disk and Resume

If you are planning on suspending your system to disk using s2disk from suspend, then you will need to resume your system using the resume command (also from suspend). This must be done before the system boots, otherwise you would be plain booting your system rather than resuming it, which would defeat the point of suspending it (this would also result in any partitions mounted before the suspend in needing to be fscked or restored from journals, if using a journalling filesystem, since they would have been "dirty" before the suspend).

To be able to run resume before the system boots, you need to have it in an initramfs/initrd (note: this is an equivocation for "you MUST have an initramfs/initrd with the resume utility"). Since this document details an initramfs, I'll describe how to set up your initramfs with resume. If you've followed the process for making an initramfs described in this document (or are already familiar with making them), then it's actually quite easy to add support for resume.

Add the resume binary to the initrafms

You cannot run programs which are not available. Therefore, we need to make sure that resume is present in the initramfs. Following the layout I gave in "Structure of an Initramfs", copy the resume binary in the initramfs bin/ directory, as below.


/bin/resume
Call resume from the Initramfs /init script

Now we need to set up the /init script in to make use of the resume binary. For this, we will use a single function (makes the init script cleaner and more fault tolerant) and a single call to this function.

Add the following function near the top, after the shell function:


tryresume () {
 echo ''
 echo ' Attempting to resume from suspend-to-disk.'
 /bin/resume ||
 echo ' resume: error: could not resume'
 echo ''
}
Right after the call to the shell function, add the following to call the resume function. I've included the preceding and following context to make it clear; just add the lines with # Try to resume... and $GREP -q 'noresume'....


# Drop to shell if "shell" was passed as kernel param
$GREP -q 'shell' /proc/cmdline && shell

# Try to resume a suspend-to-disk if "noresume" not passed as kernel param
$GREP -q 'noresume' /proc/cmdline || tryresume

# Get the args to pass to init, minus key=val pairs
INIT_ARGS="$($AWK '{gsub(/[[:graph:]]+=[[:graph:]]+/,""); print}' $KCMD)"
LVM Root Partition

I am including this note only because I myself use LVM for my root partition, so I am familiar enough with it to discuss its setup. Once you have partitioned your disk for LVM and created your LVM volumes, using them with an initramfs is simply easy. There are only 2 factors you need to be careful of:

lvm and dm (device-mapper) kernel modules (if built as modules)
the lvm binary
In the case that you have lvm and dm support built as modules in your kernel, you will need to include those modules in your initramfs or you won't be able to boot your root partition. Additionally, if you change the version of your kernel (upgrade or downgrade), you will need to replace the modules in the initramfs with the newly built ones. In other words, the modules in the initramfs must match the running kernel. If, on the other hand, you build these into the kernel instead of as modules, you avoid this problem entirely. Building them into the kernel is therefore highly recommended.

The lvm binary is less problematic. This is really only an issue if you update the binary in your running system and there was a significant change in how lvm formats your lvm volumes (and you additionally update your volumes in accordance with the new format). Under this scenario, if the binary in the initramfs is outdated, you will not be able to boot your root device. However, there is the additional requirement with the lvm binary of including all dynamic libraries it depends on. Typically, at least in Source Mage, when you install lvm you will also get a statically built lvm binary (/usr/sbin/lvm.static in Source Mage). I recommend installing the statically built version unless you have a good reason to use the dynamically built one (and you realize the consequences of doing so).

