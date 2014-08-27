jni.h : libnativehelper/include/nativehelper/jni.h

#1.调用java方法

JNIEnv->CallVoidMethod(jobject, jmethodID, ...);

调用Java方法，还有一系列的void static virtual相关的方法。

还有一系列用CALL_TYPE定义的反回值为各种类型的函数。

    jint        (*CallIntMethod)(JNIEnv*, jobject, jmethodID, ...);
    jint        (*CallIntMethodV)(JNIEnv*, jobject, jmethodID, va_list);
    jint        (*CallIntMethodA)(JNIEnv*, jobject, jmethodID, jvalue*);

jint java函数的返回值。有三种方法，第一种像printf一样的，第二次直接用va_list,第三种可以看下jvalue的定义，难道是一个NULL结尾的数组？

jmethodID是用GetMethodID获得的。

jclass是用FindClass获得的。

#2.jstring

	class _jobject {};
	class _jstring : public _jobject {};
	typedef _jstring*       jstring;

定义的别名，没有实现任何东西。

还是要用JNIEnv中的函数。

    jstring     (*NewString)(JNIEnv*, const jchar*, jsize);
    jsize       (*GetStringLength)(JNIEnv*, jstring);
    const jchar* (*GetStringChars)(JNIEnv*, jstring, jboolean*);
    void        (*ReleaseStringChars)(JNIEnv*, jstring, const jchar*);
    jstring     (*NewStringUTF)(JNIEnv*, const char*);
    jsize       (*GetStringUTFLength)(JNIEnv*, jstring);
    /* JNI spec says this returns const jbyte*, but that's inconsistent */
    const char* (*GetStringUTFChars)(JNIEnv*, jstring, jboolean*);
    void        (*ReleaseStringUTFChars)(JNIEnv*, jstring, const char*);

前面几个函数与jchar相关， 在java中char是unicode的？

而后面几个函数与char相关，直接是c里面的字符串？

上面的函数是c中使用的，下面是c++里的NewString。

    jstring NewString(const jchar* unicodeChars, jsize len)
    { return functions->NewString(this, unicodeChars, len); }

    jstring NewStringUTF(const char* bytes)
    { return functions->NewStringUTF(this, bytes); }


对于一个返回值为String的java native函数，在JNI端，都是调用NewString系统函数，不用DeleteLocalRef。grep -nr ")Ljava/lang/String" *可以找到大量例子。

DeleteLocalRef是用于，这个jstring在JNI调用java函数时作为参数，调用完java函数后，要释放。

#3.关于JNI层回调JAVA的问题
运行时说JNI WARNING: threadid=14 using env from threadid=1

用workqueue运行时报了这样的错。

JNIEnv是与线程相关的，可以用下面的代码来解决：

	JNIEnv *env;
	int status;

	if ((status = (*gJavaVM)->GetEnv(gJavaVM, (void**)&env, JNI_VERSION_1_6)) < 0)
	 {
		if ((status = (*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL)) < 0) {
            return;
        }
    } 

gJavaVM是保存来自JNI_OnLoad时传入的JavaVM。

还有那个对象需要调用NewGlobalRef来增加引用。

##1.续
上面解决了JNIEnv的问题，对于获得的那个method id也是不能在不同线程共享的。

实测发现在WorkQueue的线程中，调用FindClass失败。同时在Parcel的JNI中发现了其对jclass调用了NewGlobalRef:

后面这个class是这样来的，在主线程的一个调用中：

254         notifyData.thiz = env->NewGlobalRef(thiz);
255         notifyData.clazz = (jclass)env->NewGlobalRef(clazz);

然后在WorkQueue调用的代码中：

static void eventNotify(int type, int cmd)
{
        JavaVM *jvm = notifyData.jvm;
        JNIEnv *env;
        int rc; 

        ALOGV("eventNotify:type=%d, cmd=%d", type, cmd);

        if (jvm->GetEnv((void **)&env, JNI_VERSION_1_6)) {
                ALOGV("%s:JNI version mismatch error", __func__);
        }   

        if (jvm->AttachCurrentThread(&env, NULL)) {
                ALOGV("%s:JNI attach thread error", __func__);
        }   

        jmethodID notify = env->GetMethodID(notifyData.clazz, "notify", "(II)V");
        if (!notify) {
                ALOGV("%s:GetMethodID fail", __func__);
        }   

        env->CallVoidMethod(notifyData.thiz, notify,
                type, cmd);
}

这样就OK了。

