---
layout: post
title: "android java binder"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#0.实例

    cd framework
    find . -name *.aidl | xargs grep interface

#1.AIDL文件编写
./base/core/java/android/accounts/IAccountAuthenticator.aidl：

    package android.accounts;

    import android.accounts.IAccountAuthenticatorResponse;
    import android.accounts.Account;
    import android.os.Bundle;

    oneway interface IAccountAuthenticator {
    ...
    void getAuthTokenLabel(in IAccountAuthenticatorResponse response, String authTokenType);
    void confirmCredentials(in IAccountAuthenticatorResponse response, in Account account, in Bundle options);

要是用ADT的话，你保存了这个文件在gen目录下马上会生成对应的Java文件。ctrl+shift+F格式化代码。

package 会在java文件中生成这一句。

对于那个函数声明，引用了自定义的类:IAccountAuthenticatorResponse。引用了自定义类的话，要建一个文件为：类名.aidl。同时import这个类。

比如Account,Account.aidl:

    package android.accounts;

    parcelable Account;
    
然后，这个Account类要：

    public class Account implements Parcelable {
    ...
    public void writeToParcel(Parcel dest, int flags) {
    dest.writeString(name);
        dest.writeString(type);
    }
    ...
    public static final Creator<Account> CREATOR = new Creator<Account>() {
        public Account createFromParcel(Parcel source) {
            return new Account(source);
        }

        public Account[] newArray(int size) {
            return new Account[size];
        }
    };
    ...
    public Account(Parcel in) {
        this.name = in.readString();
        this.type = in.readString();
    }

#2.Binder的服务端

    public MYBinder extends Stub {
    ...
    实现aidl文件中定义的接口
    ...
    }

Stub是aidl文件生成的Java文件中的，在Stub的onTransact中，调用子类中的函数。

#3.Binder的客户端

    客户端使用是这样的。

    IGateway client = aidl定义的接名.Stub.asInterface(IBinder binder);

    通过上面的来获取客户端，在aidl对应的Java文件中，Proxy类也实现了aidl定义的Interface。

这个是在服务中使用binder通信的，还会是跨进程的。asInterface那个IBinder是系统中函数弄来的。

这个IBinder到底是native中的Bn还是Bp,应该是Bp吧。

