android stagefright使用的是openmax il这一层，没有使用openmax al这一层。

#1.OMXCodec::Create

        status_t err = omx->allocateNode(componentName, observer, &node);
        if (err == OK) {
            ALOGV("Successfully allocated OMX node '%s'", componentName);

            sp<OMXCodec> codec = new OMXCodec(
                    omx, node, quirks, flags,
                    createEncoder, mime, componentName,
                    source, nativeWindow);

            observer->setCodec(codec);

            err = codec->configureCodec(meta);

            if (err == OK) {
                if (!strcmp("OMX.Nvidia.mpeg2v.decode", componentName)) {
                    codec->mFlags |= kOnlySubmitOneInputBufferAtOneTime;
                }

                return codec;
            }

            ALOGV("Failed to configure codec '%s'", componentName);
        }

代码中omx -> IOMX，OMX : public BnOMX


##1.OMX::allocateNode
    OMXNodeInstance *instance = new OMXNodeInstance(this, observer);

    OMX_COMPONENTTYPE *handle;
    OMX_ERRORTYPE err = mMaster->makeComponentInstance(
            name, &OMXNodeInstance::kCallbacks,
            instance, &handle);

###makeComponentInstance
1.SoftOMXPlugin::makeComponentInstance软件解码的实现：

	SoftOMXPlugin::makeComponentInstance（） {
		        AString libName = "libstagefright_soft_";
        libName.append(kComponents[i].mLibNameSuffix);
        libName.append(".so");

        void *libHandle = dlopen(libName.c_str(), RTLD_NOW);

        if (libHandle == NULL) {
            ALOGE("unable to dlopen %s", libName.c_str());

            return OMX_ErrorComponentNotFound;
        }

        typedef SoftOMXComponent *(*CreateSoftOMXComponentFunc)(
                const char *, const OMX_CALLBACKTYPE *,
                OMX_PTR, OMX_COMPONENTTYPE **);

        CreateSoftOMXComponentFunc createSoftOMXComponent =
            (CreateSoftOMXComponentFunc)dlsym(
                    libHandle,
                    "_Z22createSoftOMXComponentPKcPK16OMX_CALLBACKTYPE"
                    "PvPP17OMX_COMPONENTTYPE");

        if (createSoftOMXComponent == NULL) {
            dlclose(libHandle);
            libHandle = NULL;

            return OMX_ErrorComponentNotFound;
        }
        sp<SoftOMXComponent> codec =
            (*createSoftOMXComponent)(name, callbacks, appData, component);
	}

SoftAAC2.cpp:

	android::SoftOMXComponent *createSoftOMXComponent(
        	const char *name, const OMX_CALLBACKTYPE *callbacks,
        	OMX_PTR appData, OMX_COMPONENTTYPE **component) {
    		return new android::SoftAAC2(name, callbacks, appData, component);
	}

##2.SoftOMXComponent
SoftAAC2.h中，SoftAAC2这个类是继承SimpleSoftOMXComponent这个类的，像useBuffer、allocateBuffer、fillThisBuffer这些类已经在SimpleSoftOMXComponent中实现，像SoftAAC2.h中只需要实现更少的类就行了。

##3.硬件实现
QComOMXPlugin.h (hardware\qcom\media\libstagefrighthw)

QComOMXPlugin::QComOMXPlugin()
    : mLibHandle(dlopen("libOmxCore.so", RTLD_NOW)),
      mInit(NULL),
      mDeinit(NULL),
      mComponentNameEnum(NULL),
      mGetHandle(NULL),
      mFreeHandle(NULL),
      mGetRolesOfComponentHandle(NULL) {
    if (mLibHandle != NULL) {
        mInit = (InitFunc)dlsym(mLibHandle, "OMX_Init");
        mDeinit = (DeinitFunc)dlsym(mLibHandle, "OMX_Deinit");

        mComponentNameEnum =
            (ComponentNameEnumFunc)dlsym(mLibHandle, "OMX_ComponentNameEnum");

        mGetHandle = (GetHandleFunc)dlsym(mLibHandle, "OMX_GetHandle");
        mFreeHandle = (FreeHandleFunc)dlsym(mLibHandle, "OMX_FreeHandle");

        mGetRolesOfComponentHandle =
            (GetRolesOfComponentFunc)dlsym(
                    mLibHandle, "OMX_GetRolesOfComponent");

        (*mInit)();
    }
}

OMX_ERRORTYPE QComOMXPlugin::makeComponentInstance(
        const char *name,
        const OMX_CALLBACKTYPE *callbacks,
        OMX_PTR appData,
        OMX_COMPONENTTYPE **component) {
    if (mLibHandle == NULL) {
        return OMX_ErrorUndefined;
    }

    return (*mGetHandle)(
            reinterpret_cast<OMX_HANDLETYPE *>(component),
            const_cast<char *>(name),
            appData, const_cast<OMX_CALLBACKTYPE *>(callbacks));
}

#2.后续流程
makeComponentInstance的返回值被用作，OMXNodeInstance::setHandle的参数。

status_t OMXNodeInstance::sendCommand(
        OMX_COMMANDTYPE cmd, OMX_S32 param) {
    Mutex::Autolock autoLock(mLock);

    OMX_ERRORTYPE err = OMX_SendCommand(mHandle, cmd, param, NULL);
    return StatusFromOMXError(err);
}

OMX_SendCommand的实现：
OMX_Core.h (hardware\qcom\media\mm-core\inc)

#define OMX_SendCommand(                                    \
         hComponent,                                        \
         Cmd,                                               \
         nParam,                                            \
         pCmdData)                                          \
     ((OMX_COMPONENTTYPE*)hComponent)->SendCommand(         \
         hComponent,                                        \
         Cmd,                                               \
         nParam,                                            \
         pCmdData)                          /* Macro End */

唯一实现的是OMX_GetHandle，

##3.OMX_COMPONENTTYPE
在软件的实现中也会返回一个这个东西，这个是openmax il中定义的，像OMX_SendCommand最终使用的是这个结构体的的函数。

对于软件的实现，是在SoftOMXComponent::SoftOMXComponent中初始化的：

	mComponent->SendCommand = SendCommandWrapper;

OMX_ERRORTYPE SoftOMXComponent::SendCommandWrapper(
        OMX_HANDLETYPE component,
        OMX_COMMANDTYPE cmd,
        OMX_U32 param,
        OMX_PTR data) {
    SoftOMXComponent *me =
        (SoftOMXComponent *)
            ((OMX_COMPONENTTYPE *)component)->pComponentPrivate;

    return me->sendCommand(cmd, param, data);
}

#小小的总结
OMX::allocateNode():

1.得到OMX_COMPONENTTYPE

mMaster->makeComponentInstance 

2.用一个ID来记录binder时使用的id索引的OMX_COMPONENTTYPE实例

    *node = makeNodeID(instance);
    mDispatchers.add(*node, new CallbackDispatcher(instance));

3.调用

status_t OMX::sendCommand(
        node_id node, OMX_COMMANDTYPE cmd, OMX_S32 param) {
    return findInstance(node)->sendCommand(cmd, param);
}

    instance->setHandle(*node, handle);

    mLiveNodes.add(observer->asBinder(), instance);

# OMXMaster::makeComponentInstance

mPluginByComponentName是在OMXMaster::addPlugin添加的

addPlugin的调用：
OMXMaster::OMXMaster():

    addVendorPlugin();
    addPlugin(new SoftOMXPlugin);

#应用相关
AwesomePlayer::initAudioDecoder中OMXCodec::Create中的matchComponetName为NULL，只有在isLPAPlayback时用一下。

##OMXCodec::findMatchingCodecs
这个列表由MediaCodecList这个类来实现，这个类解析device/qcom/common/media/media_codecs.xml这个文件中列出来的codec

SoftOMXPlugin与MediaCodecList的联系：
static const struct {
    const char *mName;
    const char *mLibNameSuffix;
    const char *mRole;

} kComponents[] = {
    { "OMX.google.aac.decoder", "aacdec", "audio_decoder.aac" },
    { "OMX.google.aac.encoder", "aacenc", "audio_encoder.aac" },
    { "OMX.google.amrnb.decoder", "amrdec", "audio_decoder.amrnb" },
    { "OMX.google.amrnb.encoder", "amrnbenc", "audio_encoder.amrnb" },
    { "OMX.google.amrwb.decoder", "amrdec", "audio_decoder.amrwb" },
    { "OMX.google.amrwb.encoder", "amrwbenc", "audio_encoder.amrwb" },
    { "OMX.google.h264.decoder", "h264dec", "video_decoder.avc" },
    { "OMX.google.h264.encoder", "h264enc", "video_encoder.avc" },
    ...
};

第二个成员就是libstagefright_soft_aacdec.so文件名中的那什么了。

##mime:
1.media_codecs.xml:

	<MediaCodec name="OMX.qcom.audio.decoder.wmaLossLess" type="audio/x-ms-wma" >

2.OMXCodec::findMatchingCodecs:

	list->findCodecByType(mime, createEncoder, index);

3.DataSource::Sniff

	DataSource::RegisterDefaultSniffers() {
		RegisterSniffer(SniffMPEG4);
		...
	}

SniffMPEG4实现在MPEG4Extractor.cpp中

void DataSource::RegisterSniffer(SnifferFunc func) {
    Mutex::Autolock autoLock(gSnifferMutex);

    for (List<SnifferFunc>::iterator it = gSniffers.begin();
         it != gSniffers.end(); ++it) {
        if (*it == func) {
            return;
        }
    }

    gSniffers.push_back(func);
}

	MediaExtractor::Create() {
		...
		source->sniff(&tmp, &confidence, &meta)
		...
		new MPEG4Extractor(source);
	}

MIME类定在MediaDefs.cpp:

	const char *MEDIA_MIMETYPE_CONTAINER_MPEG4 = "video/mp4";

##解码的数据来源
Awesomeplay::setDataSource()
从MediaExtractor::getTrack获得DataSource，然后就给OMX这些来解码啦。

