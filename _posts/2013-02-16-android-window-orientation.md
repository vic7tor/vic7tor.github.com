---
layout: post
title: "Android Window Orientation"
description: ""
category: 
tags: []
---
{% include JB/setup %}
不知道用这个标题合不合适，我的意思就是Android随着那些感应器旋转屏幕是怎么实现的。

以前就跟到了SensorService，SensorService那个SendEvent的一个目的地就是：WindowOrientationListener。

它在：frameworks/base/core/java/android/view/WindowOrientationListener.java

然后就是PhoneWindowManager使用了这个类。

WindowOrientationListener应该就是随感应器旋转屏幕的一个中间过程了，它把三轴加速器的数据计算有没有转屏幕。有一个叫orientationplot.py的工具来研究这个类的行为的。

它在frameworks/base/tools/orientationplot/下，下面还有一份文档教你怎么用。

用它来看看，有往上报加速度的数据，为嘛没有旋转屏幕。

adb shell setprop debug.orientation.log true后，就会往log里写下面的数据：

    02-17 00:40:23.334 V/WindowOrientationListener( 2312): Raw acceleration vector: x=7.0, y=0.0, z=0.0, magnitude=7.0
    02-17 00:40:23.334 V/WindowOrientationListener( 2312): Filtered acceleration vector: x=5.666724, y=0.0, z=0.0, magnitude=5.666724
    02-17 00:40:23.334 V/WindowOrientationListener( 2312): Predicted: tiltAngle=0, orientationAngle=90, predictedRotation=1, predictedRotationAgeMS=0.0
    02-17 00:40:23.334 V/WindowOrientationListener( 2312): Result: currentRotation=0, proposedRotation=-1, predictedRotation=1, timeDeltaMS=100.013, isAccelerating=true, isFlat=false, isSwinging=false, timeUntilSettledMS=40.0, timeUntilAccelerationDelayExpiredMS=500.0, timeUntilFlatDelayExpiredMS=0.0, timeUntilSwingDelayExpiredMS=0.0

有proposedRotation和predictedRotation这两个值。当满足一些条件，proposedRotation会从predictedRotation赋值，当proposedRotation大于0时，屏幕就旋转了。

下面就讲讲要满足什么条件。

    final int oldProposedRotation = mProposedRotation;
    if (mPredictedRotation < 0 || isPredictedRotationAcceptable(now)) {
        mProposedRotation = mPredictedRotation;
    }

关键的就是那个isPredictedRotationAcceptable，这个函数的实现就是，

    mPredictedRotationTimestampNanos + PROPOSAL_SETTLE_TIME_NANOS
    mFlatTimestampNanos + PROPOSAL_MIN_TIME_SINCE_FLAT_ENDED_NANOS
    mSwingTimestampNanos + PROPOSAL_MIN_TIME_SINCE_SWING_ENDED_NANOS
    mAccelerationTimestampNanos + PROPOSAL_MIN_TIME_SINCE_ACCELERATION_ENDED_NANOS

mPredictedRotationTimestampNanos就是预计为这个旋转方向的时刻，些时之后都预计为这个旋转方向

mFlatTimestampNanos就是设备是平放的时刻，此时之后设备都不是平放的

mSwingTimestampNanos设备最后抖动的时刻

mAccelerationTimestampNanos设备最后加速的时刻

这些时刻都过了相当的延迟之后(PROPOSAL_XX)之后，isPredictedRotationAcceptable就return true。

在log中显示的数据，timeUntilSettledMS、timeUntilAccelerationDelayExpiredMS、timeUntilFlatDelayExpiredMS、timeUntilSwingDelayExpiredMS为还需要稳定多少时间，都变为0后，isPredictedRotationAcceptable就为true了。

在orientationplot.py图形界面显示的数据，Proposal Stability数据全部为0后，orientationplot.py就为true了。

现在明白了为什么不能转屏幕了，/dev/input/eventX那个接口是加速发生变化才上报数据的。所以我就要不停那个板才有数据上报，但是一动那个板，板就不停处于加速状态，也不能让设备转屏。

所以，现在应该用sysfs的接口，然后，使用msleep来以一定速率上报数据。100ms(orientationplot.py里Accelerometer Sampling Latency就是100ms一格的)应该是一个可以接受的值，想精度高点，50MS应该足够了。

用了sysfs的接口，发现还是不行。主要还是那个isAccelerating的问题，见那函数，合加速度值要在一个范围内才不是处于加速状态。

把板平放时报的Z的值是20左右，把结果除以2再报上去就正常了。。

