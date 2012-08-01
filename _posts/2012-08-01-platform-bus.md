---
layout: post
title: "platform bus"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.初始化
`kernel_init->do_basic_setup->do_basic_setup->driver_init->platform_bus_init`

    void __init driver_init(void)
    {       
            /* These are the core pieces */
            devtmpfs_init();
            devices_init();
            buses_init();
            classes_init();
            firmware_init();
            hypervisor_init();
            
            /* These are also core pieces, but must come after the
             * core core pieces.
             */
            platform_bus_init();
            system_bus_init();
            cpu_dev_init();
            memory_dev_init();
    }

driver_init还做了很多事啊。
#2.使用platform的理由
1.可以和usb和pci一样吧，有一个bus..
2.用来传递数据

#3.platform_device
1.结构定义

    struct platform_device {
    	const char	* name;
    	int		id; /*两个用途：1.early_platform系列函数有使用到
    				2.platform_device_add时用来设置device的
    				kobject的名字*/
    	struct device	dev;
    	u32		num_resources;
    	struct resource	* resource;
    
    	const struct platform_device_id	*id_entry;
    
    	/* MFD cell pointer */
    	struct mfd_cell *mfd_cell;
    
    	/* arch specific additions */
    	struct pdev_archdata	archdata;
    };

2.结构初始化

    static struct resource xxx_resources[] = {
        [0] = {
                .start = ,
    		.end = ,
    		.flags = ,
    	},
    };

    struct platform_device xxx = {
        .name           = "xxx",
        .id             = -1,
        .num_resources  = ARRAY_SIZE(xxx_resources),
        .resource       = xxxx_resources,
        .dev            = {
                .platform_data  = &xxxx_platdata,
        },
    };

    struct platform_device *machine_devices[] = {
    &xxx,
    };   

    platform_add_devices(machine_devices, ARRAY_SIZE(machine_devices);


platform_device有两个可以存数据的地方。但都是在device这个结构中。

    dev_set_platdata - 这个是device中的一个可员，可以在定义platform_device时设置
    dev_set_drvdata - 这指向另一个结构，不用在定义时设置
3.相关函数
platform_device_register
platform_add_devices 调用platform_device_register
platform_get_irq

#2.platform_driver
结构定义

    struct platform_driver {
	int (*probe)(struct platform_device *);
	int (*remove)(struct platform_device *);
	void (*shutdown)(struct platform_device *);
	int (*suspend)(struct platform_device *, pm_message_t state);
	int (*resume)(struct platform_device *);
	struct device_driver driver;
	const struct platform_device_id *id_table;
    };

2.定义实例

    static struct platform_driver s3c2440_serial_driver = {
        .probe          = s3c2440_serial_probe,
        .remove         = __devexit_p(s3c24xx_serial_remove),
        .driver         = {
                .name   = "s3c2440-uart",
                .owner  = THIS_MODULE,
        },
    };

    platform_driver_register(&s3c2440_serial_driver);
3.相关函数

#platform_device与platform_driver的配对
在platform_bus_type的match，存在platform_device_id的id_table的话，就使用这个，要不就使用`platform_device->name`与`platform_driver->driver->name`匹配。
