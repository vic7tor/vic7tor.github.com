源代码来自stagefright-plugins。

#1.FFmpegExtractor
1.复制头文件和cpp FFmpegExtractor.cpp 到libstagefright的根目录来。

2.然后把sniff加入:DataSource.cpp的Sniffer::RegisterDefaultSniffers函数加入：

	RegisterSniffer(SniffFFMPEG);

SniffFFMPEG中有几句：

	1894         (*meta)->setString("extended-extractor", "extended-extractor");
	1895         (*meta)->setString("extended-extractor-subtype", "ffmpegextractor")     ;
	1896         (*meta)->setString("extended-extractor-mime", container);

extended-extractor这个在CreateFFmpegExtractor这个函数中是使用到的。

	if (meta.get() && meta->findString("extended-extractor", &notuse) && (

#2.MediaDefs

1.MediaDefs.cpp
加入MIME的定义。

2.MediaDefs.h
都extern MediaDefs.cpp中定义的。

#3.MediaExtractor
MediaExtractor::Create这个函数通过检测(*meta)->setString("extended-extractor-subtype", "ffmpegextractor")设置的meta信息。

 96     AString extractorName;
 97     if (meta.get() != NULL && meta->findString("extended-extractor-use", &ex    tractorName)) {
 98         if (!strcasecmp("ffmpegextractor", extractorName.c_str())) {
 99                 ALOGV("Use ffmpeg extended extractor for the special mime(%s    ) or codec", mime);
100                 return new FFmpegExtractor(source, meta);
101         }
102     }
103 
104     MediaExtractor *ret = NULL;

#4.SoftOMXPlugin.cpp
kCompenents的修改，把那个media_codecs.xml中定义的OMX.ffmpeg.*定向到哪个codecs

#5.media_codecs.xml

照抄config/media_codecs.xml了。

#6.ffmpeg参数传递
FFmpegExtractor会在MetaData加入一些信息，而这些信息要传递到codec中去。

一个略为浩大的工程。

##1.OMX_Component.h
frameworks/native/include/media/openmax/OMX_Component.h

OMX_PARAM_PORTDEFINITIONTYPE

这个结构是OMX中抽象出来的Port，SoftFFmpegAudio::initPorts中初始化了两个Port一个OMX_DirInput，其格式为需要解码的格式。

还定义了一个OMX_DirOutput，其实格式为format.audio.eEncoding = OMX_AUDIO_CodingPCM;

看OMXNodeInstance这个类中的函数，allocateBuffer、freeBuffer都是需要一个Port作为参数的。

##2.OMXCodec::read

	1.drainInputBuffers
	2.fillOutputBuffers
	3.waitForBufferFilled_l

###OMX的解码流程
OMX_AllocateBuffer
在一个Port上分配一个buffer?

OMX_UseBuffer
为这个Buffer填充数据？


OMX_EmptyThisBuffer
把一个Filled的Buffer发送到input port

OMX_FillThisBuffer
把一个empty buffer发送到output port，这个函数不是阻塞的，buffer会在将来的某个时候填充。

###Android中的实现
OMX_AllocateBuffer不会每次都调用，这个都是预先分配一定数量的buffer，函数是OMXCodec::allocateBuffersOnPort。然后这个Buffer用别的数据结构维护起来，保存在mPortBuffers这个数组中。

SimpleSoftOMXComponent::allocBuffer中已经调用了useBuffer。


#6.1 OMX_Audio.h OMX_Video.h

#7.utils

#8.SoftOMXPlugin.cpp
这个是建media_codecs.xml中的与哪个动态库相连的。

#9.
1016478 +status_t OMXCodec::setAPEFormat(const sp<MetaData> &meta)
1016479 +{
1016480 +    int32_t numChannels = 0;
1016481 +    int32_t sampleRate = 0;
1016482 +    int32_t bitsPerSample = 0;
1016483 +    OMX_AUDIO_PARAM_APETYPE param;
1016484 +
1016485 +    if (mIsEncoder) {
1016486 +        CODEC_LOGE("APE encoding not supported");
1016487 +        return OK;
1016488 +    }
1016489 +
1016490 +    CHECK(meta->findInt32(kKeyChannelCount, &numChannels));
1016491 +    CHECK(meta->findInt32(kKeySampleRate, &sampleRate));
1016492 +    CHECK(meta->findInt32(kKeyBitspersample, &bitsPerSample));
1016493 +
1016494 +    CODEC_LOGV("Channels:%d, SampleRate:%d, bitsPerSample:%d",
1016495 +            numChannels, sampleRate, bitsPerSample);
1016496 +
1016497 +    InitOMXParams(&param);
1016498 +    param.nPortIndex = kPortIndexInput;
1016499 +
1016500 +    status_t err = mOMX->getParameter(
1016501 +                       mNode, OMX_IndexParamAudioApe, &param, sizeof(pa        ram));
1016502 +    if (err != OK)
1016503 +        return err;
1016504 +
1016505 +    param.nChannels = numChannels;
1016506 +    param.nSamplingRate = sampleRate;
1016507 +    param.nBitsPerSample = bitsPerSample;
1016508 +
1016509 +    err = mOMX->setParameter(
1016510 +                    mNode, OMX_IndexParamAudioApe, &param, sizeof(param        ));
1016511 +    return err;
1016512 +}

setAPEFormat由OMXCodec::configureCodec调用，由于FFMpeg的几个库也是拆分的，解开文件和解码是分开的。有的参数需要从解开文件的库传到解码库去。

OMXCodec::Create调用OMXCodec::configureCodec。

