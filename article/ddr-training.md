#1.boot_images 流程

sbl1_wait_for_ddr_training：
	...
	boot_log_message("sbl1_wait_for_ddr_training, Start");
	...
	sbl1_save_ddr_training_data();

sbl1_save_ddr_training_data：
	

ddr_post_init:

	    while( ((*ddr_training_cookie) != DDR_TRAINING_DATA_UPDATED) &&
           ((*ddr_training_cookie) != DDR_TRAINING_DATA_NOT_UPDATED));

无限循环等待。。。

##boot_images中trianing的启动

sbl1_ddr_init -> boot_ddr_initialize_device -> ddr_initialize_device -> ddr_init() -> ddr_target_init()

core/boot/secboot3/hw/msm8974/sbl1/sbl1_config.c

在sbl1_config_table tz在IMEM中设置了training信号，然后，在rpm载入时检测到这个信号，再然后在sbl1中检测信号是否更新。。。


##BUILD_BOOT_CHAIN
core/bsp/bootloaders/sbl1/build/msm8974.scons中定义了

#rpm_proc
ddr_target_init进行CA Training

ddr_initialize_device->ddr_init->ddr_target_init

##rpm.scl
把DDR Training相关的弄成一个DDR_TRAINING节的原因是为了节省内存。。

void rpm_ddr_training_complete(void)
{
  rpm_heap_add_section(Image$$DDR_TRAINING$$Base, (char*)RPM_STACK_START, RPM_HEAP_SECTION_PRIORITY_HIGH);
}

在training结束后。。

##rpm boot流程
core/bsp/rpm/src/main.c

main():

	  for(i = 0; i < ARRAY_SIZE(init_fcns); ++i)
	{
    	dog_kick();
  	  init_fcns[i]();
	  }

##rpm与boot_images交互
sbl1_wait_for_ddr_training在load_rpm_post_procs中调用，前一个就是sbl1_notify_rpm_to_jump。

这样的话，sbl1_wait_for_ddr_training在rpm软件运行之前就应该已经运行了。


