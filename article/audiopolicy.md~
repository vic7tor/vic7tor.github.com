IAudioPolicyService.h

定义了AudioPolicy的接口，先研究研究这里面定义的函数是干嘛的。


#1.AudioPolicyService.cpp
##1.AudioPolicyService
###1.创建两个线程
一个是播放电话铃声的，还有一个是为了在一个线程空间调用AudioSystem的函数吧。

###2.打开policy HAL

1.create_audio_policy 传入了一个参数aps_ops:

    struct audio_policy_service_ops aps_ops = {
        open_output           : aps_open_output,
        open_duplicate_output : aps_open_dup_output,
        close_output          : aps_close_output,
        suspend_output        : aps_suspend_output,
        restore_output        : aps_restore_output,
        open_input            : aps_open_input,
        close_input           : aps_close_input,
        set_stream_volume     : aps_set_stream_volume,
        set_stream_output     : aps_set_stream_output,
        set_parameters        : aps_set_parameters,
        get_parameters        : aps_get_parameters,
        start_tone            : aps_start_tone,
        stop_tone             : aps_stop_tone,
        set_voice_volume      : aps_set_voice_volume,
        move_effects          : aps_move_effects,
        load_hw_module        : aps_load_hw_module,
        open_output_on_module : aps_open_output_on_module,
        open_input_on_module  : aps_open_input_on_module,
    };

load_hw_module让audioflinger加载audio HAL

start_tone也是policy HAL加载的？

2.init_check

###3.loadPreProcessorConfig
/etc/audio_effects.conf

##2.setDeviceConnectionState
调用policy HAL的实现，这个函数实现在AudioPolicyManagerALSA.cpp中。

这个是用来开启这些外部设备的连通性的？

##这些调用全部转发到了HAL

##audio policy HAL



#2.AudioSystem
AudioSystem.h中，AudioPolicyService的函数都封装在这里：

    //
    // IAudioPolicyService interface (see AudioPolicyInterface for method descriptions)
    //

jni:android_media_AudioSystem.cpp

java端的AudioSystem有少部分被java代码使用？难道大部分还是c++代码使用的？

