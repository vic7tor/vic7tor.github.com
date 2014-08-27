2014-05-23 一篇关于audioflinger的文章

好久不用vi写文档了。

#1.AudioTrackShared
这玩意是AudioTrack与AudioFlinger交互音频Buffer用的。

里面的类有：Proxy、ClientProxy、AudioTrackClientProxy


	Proxy(audio_track_cblk_t* cblk, void *buffers, size_t frameCount, size_t frameSize)
        : mCblk(cblk), mBuffers(buffers), mFrameCount(frameCount), mFrameSize(frameSize) { }

audio_track_cblk_t* const   mCblk;

audio_track_cblk_t::stepUser在processAudioBuffer中有调用。
实现在media/libmedia/AudioTrackShared.cpp

还有一个是stepServer，这个被audioflinger中的TrackBase调用。被ServerProxy封装：

	bool        step(size_t stepCount) { return mCblk->stepServer(stepCount, mFrameCount, mIsOut); }

又被TrackBase::step封装，调用用step就是调用这个啦。

#2.AudioTrack
这个是对AudioFlinger中IAudioTrack的封装，但不是直接继承。

可以看看IAudioTrack中定义的接口：getCblk、allocateTimedBuffer、queueTimedBuffer

这几个是与buffer管理相关的。getCblk是在AudioTrack中使用，allocateTimedBuffer是在TimedAudioTrack中使用。

##1.AudioTrack的Buffer交互

	AudioTrack::createTrack_l() {
		处理传入的sharedbuffer
		IAudioFlinger::TRACK_TIMED
		sp<IAudioTrack> track = audioFlinger->createTrack(
		...
		sp<IMemory> iMem = track->getCblk();
		audio_track_cblk_t* cblk = static_cast<audio_track_cblk_t*>(iMem->pointer());
		mCblk = cblk;
		...
		if (sharedBuffer == 0) {
			mBuffers = (char*)cblk + sizeof(audio_track_cblk_t);
		} else {
			mBuffers = sharedBuffer->pointer();
		}
		...
		mProxy = new AudioTrackClientProxy(cblk, mBuffers, frameCount, mFrameSizeAF);
	}

只调了一次getCblk()，不知道这玩意指向的内存有多大,然后mProxy用AudioTrackClientProxy构造。注意参数。

##2.processAudioBuffer

EVENT_MORE_DATA的那个do while

	do {
		obtainBuffer() {
			    uint32_t u = cblk->user; //当前buffer指向这个位置
			    uint32_t bufferEnd = cblk->userBase + mFrameCount;
	
			    if (framesReq > bufferEnd - u) {
			        framesReq = bufferEnd - u;
			    }

			    audioBuffer->frameCount = framesReq;
			    audioBuffer->size = framesReq * mFrameSizeAF;
			    audioBuffer->raw = mProxy->buffer(u);
		}

		。。。

		releaseBuffer() {
			mProxy->stepUser(audioBuffer->frameCount);
		}

stepUser是在Proxy中定义的：

	audio_track_cblk_t* const   mCblk;

使用见第一节。

#3.audioflinger
上面弄清了AudioTrack与AudioFlinger如何交互数据。

audioflinger的组件还是挺多的，services/audioflinger/下面文件：

AudioFlinger AudioMixer AudioPolicyService AudioResampler Effects FastMixer ... Threads Tracks

内容挺多。关于Policy与Effects这两个在media/libmedia下有专门的client实现。

Policy - AudioSystem类

Effects - AudioEffect类

##1.AudioFlinger

###1.createTrack
audio_io_handle_t这个参数是从AudioSystem::getOutput(...sampleRate, audioformat...)

	PlaybackThread *thread = checkPlaybackThread_l(output);

	track = thread->createTrack_l(client, streamType, sampleRate, format,
        	channelMask, frameCount, sharedBuffer, lSessionId, flags, tid, &lStatus);
	处理一个SyncEvent
	trackHandle = new TrackHandle(track);
	return trackHandle;

checkPlaybackThread_l:
mPlaybackThreads的是在AudioFlinger::openOutput中加入的:
	if (flags & AUDIO_OUTPUT_FLAG_LPA || flags & AUDIO_OUTPUT_FLAG_TUNNEL ) 	{
	    
	} else if ((flags & AUDIO_OUTPUT_FLAG_DIRECT) ||
            (config.format != AUDIO_FORMAT_PCM_16_BIT) ||
            (config.channel_mask != AUDIO_CHANNEL_OUT_STEREO)) {
            thread = new DirectOutputThread(this, output, id, *pDevices);
            ALOGV("openOutput() created direct output: ID %d thread %p", id, thread);
        } else {
            thread = new MixerThread(this, output, id, *pDevices);
            ALOGV("openOutput() created mixer output: ID %d thread %p", id, thread);
        }

在DirectOutputThread与MixerThread传入一个id的参数，output是HAL中stream的封装？

####openOutput
AudioFlinger::openOutput在AudioPolicyServer中一个调用，这个结构体最终传入到HAL中，在HAL中被调用hardware/libhardware_legacy/audio/AudioPolicyCompatClient.cpp AudioPolicyCompatClient::openOutput -> open_output_on_module

openOutput由hardware/libhardware_legacy/include/hardware_legacy/AudioPolicyInterface.h导出

audio policy HAL的get_output调用。再由：AudioPolicyService::getOutput调用.然后就是binder服务，最终是AudioSystem::getOutput。

好大一个圈。

openOutput创一个线程并且audio_io_handle_t与之关连：

        if (thread != NULL) {
            mPlaybackThreads.add(id, thread);
            thread->mOutputFlags = flags;
        }

openOutput调用的时机，openOutput会调用audio HAL open_output_stream，这个也是与一个mPlaybackThread关连。

`一个thread与固定音频参数的音频流关连，然后，这个音频参数的AudioTrack都会交给这个PlaybackThread，然后被这玩意混音。`

openOutput是由AudioPolicyService调用的，所以APS对系统中的AudioTrack有管制，它决定了哪些AudioTrack可以放在一起。与AudioTrack相关的，还有一个音频类型，铃声、音乐相关的，不同参数的音频流，放在不同的playback线程，这些线程如何被调度。

另起一篇关于Audio Policy的文章来搞定这个问题。

Audio.h定义音频的类型:VOICE_CALL、SYSTEM、RING。

AudioSystem::getOutput:
如上。

createTrack_l:
AudioFlinger::PlaybackThread::createTrack_l(
在这里出现了一个sessionid,

	track = new Track(this, client, streamType, sampleRate, format,
                    channelMask, frameCount, sharedBuffer, sessionId, *flags);
	...
	mTracks.add(track);
	...
	sp<EffectChain> chain = getEffectChain_l(sessionId);
        if (chain != 0) {
		track->setMainBuffer(chain->inBuffer());
	}
	...
	return track;

class Track:
定义在PlaybackTracks.h:
是AudioBufferProvider的字类。

####1.PlaybackThread
PlaybackThread::threadLoop

####2.MixerThread继承了PlaybackThread
AudioFlinger::MixerThread::prepareTracks_l中调用：

	AudioMixer::setBufferProvider()

这样AudioMixer处理Track中传入的数据。

###2.createDirectTrack
在AudioFlinger::openOutput中有LPA或TUNEL相关的。


###2.openRecord

###3.createEffect

###4.xxxEvent

#4.AudioMixer


#5.AudioTrack与AwesomePlayer的关连

TunnelPlayer::start() {
...
audio_output_flags_t flags = (audio_output_flags_t) (AUDIO_OUTPUT_FLAG_TUNNEL |
                                                         AUDIO_OUTPUT_FLAG_DIRECT);
    ALOGV("mAudiosink->open() mSampleRate %d, numChannels %d, mChannelMask %d, flags %d",mSampleRate, numChannels, mChannelMask, flags);
    err = mAudioSink->open(
        mSampleRate, numChannels, mChannelMask, mFormat,
        DEFAULT_AUDIOSINK_BUFFERCOUNT,
        &TunnelPlayer::AudioSinkCallback,
        this,
        flags);
}

mAudioSink是由AudioOutput这个类来实现的，是对AudioTrack的封装。

	AwesomePlayer::initAudioDecoder() {
		对tunnel.audiovideo.decode这个属性进行检测
	}

还有一个USE_TUNNEL_MODE的宏来控制代码的编译：
./frameworks/av/media/libstagefright/Android.mk:24:    ifeq ($(USE_TUNNEL_MOtrue)
./frameworks/av/media/libstagefright/Android.mk:25:        LOCAL_CFLAGS += -_TUNNEL_MODE
./vendor/qcom/proprietary/common/msm8974/BoardConfigVendor.mk:48:USE_TUNNEL_ :=true
./vendor/qcom/proprietary/common/msm8226/BoardConfigVendor.mk:32:USE_TUNNEL_ := true
./vendor/qcom/proprietary/common/msm8610/BoardConfigVendor.mk:28:USE_TUNNEL_ := true
./vendor/qcom/proprietary/common/msm8960/BoardConfigVendor.mk:39:USE_TUNNEL_ := true

##1.数据流
这个玩意是没有经过AudioFlinger的Mixer的，直接走HAL。
待研究。

#AudioTrack与createTrack、createDirectTrack
AudioTrack::set() {
	audio_io_handle_t output = AudioSystem::getOutput(
                                    streamType,
                                    sampleRate, format, channelMask,
                                    flags);

	if (flags & AUDIO_OUTPUT_FLAG_LPA || flags & AUDIO_OUTPUT_FLAG_TUNNEL) {
		mAudioDirectOutput = output;
        	mDirectTrack = audioFlinger->createDirectTrack( getpid(),
                                                        sampleRate,
		...
	} else {
	mAudioTrackThread = new AudioTrackThread(*this, threadCanCallJava);
        mAudioTrackThread->run("AudioTrack", ANDROID_PRIORITY_AUDIO, 0 /*stack*/);
	}
	后面仍然会调用createTrack_l();
	createTrack_l();会调用AudioFlinger的createTrack();
}

1.AudioTrack::start、AudioTrack::stop、flush、pause、setVolume、write检测到mDirect
Track不会空的话调用其相应的函数。

2.AudioTrackThread的实现，就是这货调用processAudioBuffer的啦
bool AudioTrack::AudioTrackThread::threadLoop()
{
    {
        AutoMutex _l(mMyLock);
        if (mPaused) {
            mMyCond.wait(mMyLock);
            // caller will check for exitPending()
            return true;
        }
    }
    if (!mReceiver.processAudioBuffer(this)) {
        pause();
    }
    return true;
}

##createDirectTrack
AudioTrack实现了BnDirectTrackClient，就是AudioTrack::notify这个函数，对于DirectTrack回调函数也是有用的，只是不像一般Track那样可以接受数据。

在这个函数中，还是创建了一个track，directtrack与thread有没有关系。

#AudioFlinger::openOutput

        AudioStreamOut *output = new AudioStreamOut(outHwDev, outStream);
        if (flags & AUDIO_OUTPUT_FLAG_LPA || flags & AUDIO_OUTPUT_FLAG_TUNNEL ) {
            AudioSessionDescriptor *desc = new AudioSessionDescriptor(hwDevHal, outStream, flags);
            desc->mActive = true;
            //TODO: no stream type
            //desc->mStreamType = streamType;
            desc->mVolumeLeft = 1.0;
            desc->mVolumeRight = 1.0;
            desc->device = *pDevices;
            desc->trackRefPtr = NULL;
            mDirectAudioTracks.add(id, desc);
            mDirectDevice = desc->device;
        } else if ((flags & AUDIO_OUTPUT_FLAG_DIRECT) ||
            (config.format != AUDIO_FORMAT_PCM_16_BIT) ||
            (config.channel_mask != AUDIO_CHANNEL_OUT_STEREO)) {
             thread = new DirectOutputThread(this, output, id, *pDevices);
            ALOGV("openOutput() created direct output: ID %d thread %p", id, thread);
        } else {
            thread = new MixerThread(this, output, id, *pDevices);
            ALOGV("openOutput() created mixer output: ID %d thread %p", id, thread);
        }

AUDIO_OUTPUT_FLAG_LPA和AUDIO_OUTPUT_FLAG_TUNNEL是与AudioFlinger::CreateDirectTrack相关的

AUDIO_OUTPUT_FLAG_DIRECT这个仍然会进入CreateTrack，只是不经过MixerThread的混音与resample?

#audio_output_flags_t
typedef enum {
    AUDIO_OUTPUT_FLAG_NONE = 0x0,       // no attributes
    AUDIO_OUTPUT_FLAG_DIRECT = 0x1,     // this output directly connects a track
                                        // to one output stream: no software mixer
    AUDIO_OUTPUT_FLAG_PRIMARY = 0x2,    // this output is the primary output of
                                        // the device. It is unique and must be
                                        // present. It is opened by default and
                                        // receives routing, audio mode and volume
                                        // controls related to voice calls.
    AUDIO_OUTPUT_FLAG_FAST = 0x4,       // output supports "fast tracks",
                                        // defined elsewhere
    AUDIO_OUTPUT_FLAG_DEEP_BUFFER = 0x8,// use deep audio buffers
//Qualcomm Flags
    AUDIO_OUTPUT_FLAG_LPA = 0x1000,      // use LPA
    AUDIO_OUTPUT_FLAG_TUNNEL = 0x2000,   // use Tunnel
    AUDIO_OUTPUT_FLAG_VOIP_RX = 0x4000,  // use this flag in combination with DIRECT to
                                         // indicate HAL to activate EC & NS
                                         // path for VOIP calls
    AUDIO_OUTPUT_FLAG_INCALL_MUSIC = 0x8000 //use this flag for incall music delivery
} audio_output_flags_t;


#MixerThread与DirectOutputThread
在AudioFlinger::CreateTrack中创建Track的createTrack_l，这个实现在PlaybackThread之中。

这两个类都继承自PlaybackThread。

DirectOutputThread::threadLoop_mix() {
	int8_t *curBuf = (int8_t *)mMixBuffer;

	memcpy(curBuf, buffer.raw, buffer.frameCount * mFrameSize);
};



PlaybackThread::threadLoop_write() {
	...
	ssize_t framesWritten = mNormalSink->write(mMixBuffer, count);
	...
	bytesWritten = (int)mOutput->stream->write(mOutput->stream, mMixBuffer, mixBufferSize);
}

MixerThread相关的处理还是挺复杂的。

#MixerThread Effect AudioMixer等等
##1.Effect
AudioFlinger::createEffect

##2.PlayBackThread::createTrack_l

        if (!isTimed) {
            track = new Track(this, client, streamType, sampleRate, format,
                    channelMask, frameCount, sharedBuffer, sessionId, *flags);
        } else {
            track = TimedTrack::create(this, client, streamType, sampleRate, format,
                    channelMask, frameCount, sharedBuffer, sessionId);
        }
        if (track == 0 || track->getCblk() == NULL || track->name() < 0) {
            lStatus = NO_MEMORY;
            goto Exit;
        }

        sp<EffectChain> chain = getEffectChain_l(sessionId);
        if (chain != 0) {
            ALOGV("createTrack_l() setting main buffer %p", chain->inBuffer());
            track->setMainBuffer(chain->inBuffer());
            chain->setStrategy(AudioSystem::getStrategyForStream(track->streamType()));
            chain->incTrackCnt();
        }

看这个这代码chain一定是有的？

AudioFlinger::prepareTracks_l:

	mAudioMixer->setBufferProvider(name, track);
	...
        mAudioMixer->setParameter(
                name,
                AudioMixer::RESAMPLE,
                AudioMixer::SAMPLE_RATE,
                (void *)reqSampleRate);
        mAudioMixer->setParameter(
                name,
                AudioMixer::TRACK,
                AudioMixer::MAIN_BUFFER, (void *)track->mainBuffer());
        mAudioMixer->setParameter(
                name,
                AudioMixer::TRACK,
                AudioMixer::AUX_BUFFER, (void *)track->auxBuffer());


AudioMixer::process具体对应函数的设置：

state_t::hook对应的函数，是在AudioMixer::process__validate中设置的。

AudioMixer::invalidateState设置hook为process__validate

然后在process__validate根据情况来设置各种process__函数。

AudioMixer::enable和AudioMixer::setParameter都有调用AudioMixer::invalidateState

track_t:

name:
MixerThread::checkForNewParameters_l() {
	  if (status == NO_ERROR && reconfig) {
                delete mAudioMixer;
                // for safety in case readOutputParameters() accesses mAudioMixer (it doesn't)
                mAudioMixer = NULL;
                readOutputParameters();
                mAudioMixer = new AudioMixer(mNormalFrameCount, mSampleRate);
                for (size_t i = 0; i < mTracks.size() ; i++) {
                    int name = getTrackName_l(mTracks[i]->mChannelMask, mTracks[i]->mSessionId);
                    if (name < 0) {
                        break;
                    }
                    mTracks[i]->mName = name;
                }
                sendIoConfigEvent_l(AudioSystem::OUTPUT_CONFIG_CHANGED);
            }
}

MixerThread中的track与AudioMixer中的通过这个name联系。

MixerThread::prepareTracks_l() {
	int name = track->name();
	...
	mAudioMixer->setBufferProvider(name, track);
	mAudioMixer->enable(name);
	...
	mAudioMixer->setParameter(
                name,
                AudioMixer::TRACK,
                AudioMixer::MAIN_BUFFER, (void *)track->mainBuffer());
}

这个mainBuffer是用来输出的。见process__genericNoResampling，这个函数还有一个神奇的算法，没有去分析了，猜测是，如果两个track的输出buffer一样，就不去处理？

反正能确定的就是AudioMixer处理的结果是输出到track->mainBuffer中去。

对于这个神奇的算法，对于两个都播放的音乐进行混音，是不是在这里面做的？

effect:
PlaybackThread::addEffectChain_l() {
	if (mType != DIRECT) {
              size_t numSamples = mNormalFrameCount * mChannelCount;
              buffer = new int16_t[numSamples];
              memset(buffer, 0, numSamples * sizeof(int16_t));
              ALOGV("addEffectChain_l() creating new input buffer %p session %d", buffer, session);
              ownsBuffer = true;
        }	

	chain->setInBuffer(buffer, ownsBuffer);
	chain->setOutBuffer(mMixBuffer);
}

`当不是DIRECT时chain的InBuffer会分配内存，同时ownsBuffer为true，chain的InBuffer在AudioMixer中使用，前面已有，chain的outBuffer是mMixBuffer,这个是写入到HAL中的。
`
effectchain从前面的代码逻辑来看，一定是存在的。在哪里创建的？

effectchain不一定需要存在，且看Track::Track构造函数，定义在Tracks.cpp。

Track::Track() : ...,mMainBuffer(thread->mixBuffer()),

Track构造时,mMainBuffer就设置了。

`当调用addEffectChain_l加入了effect后，effect接管Track的输出。`


总结：
AudioTrack与AudioFlinger数据交互。

AduioTrack中的Track与DirectTrack(LPA、TUNNEL)。

DirectTrack没有Thread。Track还可以设置Direct，MixerThread与DirectOutputThread。

MixerThread复杂很多。MixerThread与AudioMixer的关连，通过name。

MixerThread存在时的数据流动：AudioTrack->AudioMixer->EffectChain->HAL。

这篇文章太长了，另起一篇写AudioMixer的具体算法。还有一篇关于Effect的。


