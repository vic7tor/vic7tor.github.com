#1.audio HAL
源文件：

  AudioHardwareALSA.cpp         \
  AudioStreamOutALSA.cpp        \
  AudioStreamInALSA.cpp         \
  ALSAStreamOps.cpp             \
  audio_hw_hal.cpp              \
  AudioUsbALSA.cpp              \
  AudioUtil.cpp                 \
  ALSADevice.cpp                \
  AudioSpeakerProtection.cpp    \


#2.audio policy HAL
源文件：

    audio_policy_hal.cpp \
    AudioPolicyManagerALSA.cpp

##1.getOutput

###1.stream->device

    routing_strategy strategy = getStrategy((AudioSystem::stream_type)stream);
    audio_devices_t device = getDeviceForStrategy(strategy, false /*fromCache*/);

这两个函数获得stream对应的device，这两个类型的定义都是audio.h中定义的。

###2.IOProfile && AudioOutputDescriptor

这两个结构都定义在AudioPolicyManagerBase.h

1.
IOProfile *profile = getProfileForDirectOutput(device,
                                                   samplingRate,
                                                   format,
                                                   channelMask,
                                                   (audio_output_flags_t)flags);

2.
for (size_t i = 0; i < mOutputs.size(); i++) {
                AudioOutputDescriptor *desc = mOutputs.valueAt(i);
                if (!desc->isDuplicated() && (profile == desc->mProfile)) {
                    outputDesc = desc;
                    // reuse direct output if currently open and configured with same parameters
                    if ((samplingRate == outputDesc->mSamplingRate) &&
                            (format == outputDesc->mFormat) &&
                            (channelMask == outputDesc->mChannelMask)) {
                        outputDesc->mDirectOpenCount++;
                        ALOGV("getOutput() reusing direct output %d", output);
                        return mOutputs.keyAt(i);
                    }
                }
}

3.
outputDesc = new AudioOutputDescriptor(profile);

4.
output = mpClientInterface->openOutput(profile->mModule->mHandle,
                                        &outputDesc->mDevice,
                                        &outputDesc->mSamplingRate,
                                        &outputDesc->mFormat,
                                        &outputDesc->mChannelMask,
                                        &outputDesc->mLatency,
                                        outputDesc->mFlags);

5.
addOutput(output, outputDesc);

6.
mpClientInterface是AudioPolicyInterface


5的addOutput与AudioOutputDescriptor是结合2做相同IOProfile的audio_io_handle_t的复用的。

###3.AudioPolicyInterface
见HAL如何与AudioPolicyManagerALSA.cpp关连

##HAL如何与AudioPolicyManagerALSA.cpp关连

主要是定义在AudioPolicyInterface.h中的：

extern "C" AudioPolicyInterface* createAudioPolicyManager(AudioPolicyClientInterface *clientInterface);

    qap->service_client =
        new AudioPolicyCompatClient(aps_ops, service);

    qap->apm = createAudioPolicyManager(qap->service_client);

###AudioPolicyCompatClient
实现在AudioPolicyCompatClient.cpp

然后这个就是调用create_audio_policy传入的aps_ops

##关于getOutput的后面
getOutput->openOutput后会转到audio HAL的open_output_stream，open_output_stream的一个参数也是audio_devices_t。对于这个stream是哪个音频device，是audio policy决定的啦。


