---
layout: post
title: "Android NDK"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#1.环境安装
先装NDK和SDK，然后装eclipse和ADT。新版的ADT能识别出NDK了。在eclispe里直接就可以用了，不用装什么CYGWIN。

#2.一个实列
##1.Android中的声明
在要调用Native程序的类中要有下面的声明：

    package com.example.ndk;

    public class MainActivity extends Activity {

        public native String getData(); 仅为声明
    
        static {
    	    System.loadLibrary("ndk");
        }
    }
##2.Native Code的实现
右击项目/Android Tools/Add Native Support，然后输入名字，名字就是System.loadLibrary("ndk")中的ndk这样的。

然后，当前目录就会多一个jni文件夹。同时会有一个cpp源程序和Android.mk。如果弄成C源文件，那个NewStringUTF使用会有别外的方法，暂时不知道怎么解决。

cpp源程序为：

    #include <jni.h>

    extern "C" {
	jstring Java_com_example_ndk_MainActivity_getData(JNIEnv *env, jobject thisz);
    };

    jstring Java_com_example_ndk_MainActivity_getData(JNIEnv *env, jobject thisz)
    {
    	return env->NewStringUTF("Hello c, JNI");
    }
    
因为是cpp文件，把声明用extern包含起来，在链接成功的.so文件中，导出表中的Java_com_example_ndk_MainActivity_getData名字才会是这样，而不是使用c++那样的特殊化的名字。

关于函数名字Java_com_example_ndk_MainActivity_getData。Java是必须的。com_example_ndk是包名，package com.example.ndk。MainActivity是类。getData是函数名。注意大小写。

函数的参数，前两个都是固定的，后面的，根据Java中的类的声明是否有参数来决定。

参考ndk根目录的sample而来。

关于JAVA类型与C等类型映射见下面。

Java type	JNI type	C type		Stdint C type
boolean		Jboolean	unsigned char	uint8_t
byte		Jbyte 		signed char 	int8_t
char		Jchar		unsigned short	uint16_t
double		Jdouble		double		double
float		jfloat		float		float
int		jint		Int		int32_t
long		jlong		long long	int64_t
short		jshort		Short		int16_t

String不是标准类型，所以用函数NewStringUTF创建。

##native中引用java的类
像String也是一个类，jstring是jobject的typedef。所有Java的类到了native code都会成为jobject的类型。所以在native code实现中，把Java类的参数都改成jobject.

如果，这个java类，要在native code的别的地方使用，就要调用NewGlobalRef：

    JNIEXPORT void JNICALL Java_com_packtpub_Store_setColor
        (JNIEnv* pEnv, jobject pThis, jstring pKey, jobject pColor) {
        jobject lColor = (*pEnv)->NewGlobalRef(pEnv, pColor);
        if (lColor == NULL) {
            return;
        }
        StoreEntry* lEntry = allocateEntry(pEnv, &gStore, pKey);
        if (lEntry != NULL) {
            lEntry->mType = StoreType_Color;
            lEntry->mValue.mColor = lColor;
        } else {
            (*pEnv)->DeleteGlobalRef(pEnv, lColor);
        }
    }

NewGlobalRef与DeleteGlobalRef是成对出现的。调用NewGlobalRef的原因是防止Java的垃圾收集器干掉了这个对象。如果，不在别的地方使用这个对象，那么你不需要调用NewGlobalRef。

##在native code中抛出异常
首先声明：

    public native String getString(String pKey)
        throws NotExistingKeyException, InvalidTypeException;

在native中抛出异常：

	void throwNotExistingKeyException(JNIEnv* pEnv) {
		jclass lClass = (*pEnv)->FindClass(pEnv,
			“com/packtpub/exception/NotExistingKeyException”);
		if (lClass != NULL) {
			(*pEnv)->ThrowNew(pEnv, lClass, “Key does not exist.”);
		}
		(*pEnv)->DeleteLocalRef(pEnv, lClass);
	}

##数组
用到时再查

#在native code中调用Java代码
##1.Java与native code的同步
一个native实现的java函数要想创建线程，在其native code的实现中，使用pthread接口创建线程就行了，在pthread运行的函数中，要取得JavaVm并调用JavaVm::AttachCurrentThread。

在这个线程中，调用MonitorEnter一个jobject后，synchronized修饰的native就阻塞在对这个对象的访问上。

##2.在native code中调用java代码

