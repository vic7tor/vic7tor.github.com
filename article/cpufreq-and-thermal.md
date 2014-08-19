#1.thermal

Documentation/thermal/sysfs-api.txt

The generic thermal sysfs provides a set of interfaces for thermal zone
devices (sensors) and thermal cooling devices (fan, processor...) to register
with the thermal management solution and to be a part of it.


文档中提到了在thermal中的两种角色，thermal zone devices (sensors)和thermal cooling devices (fan, processor...) (sensors)和thermal cooling devices (fan, processor...)。


##thermal_init

	result = class_register(&thermal_class);
	result = genetlink_init();


thermal_zone_device_register

##qc user layer
内核中根本没有cooling device啊，还有别的原因不能在内核实现这个thermal么？

devices/devices_actions.c 中接收netlink消息，CPU offline online。还有在这个文件有设置GPU的频率。

GPU sysfs path /sys/class/kgsl

cpufreq_request、cpufreq_set这两个函数设置CPU频率。检查它们的引用。



