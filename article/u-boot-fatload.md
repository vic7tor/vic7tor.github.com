#1.
fatload -> do_load -> fs_set_blk_dev
                      fs_read

fs_read原型为fs_read(filename, addr, pos, bytes);没有指定一个描述哪个设备的东西，是在fs_set_blk_dev中设置当前的设备是哪个了。

fs_set_blk_dev(argv[1], (argc >= 3) ? argv[2] : NULL, fstype)

fatload的参数描述：

<interface> [<dev[:part]>]  <addr> <filename> [bytes [pos]]

那个":"号不会切吧两个arg吧。

fatload mmc 0:1 0x00008000 zImage

get_device_and_partition -> get_device -> get_dev_hwpart

get_dev_hwpart:
