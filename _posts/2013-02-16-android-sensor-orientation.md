---
layout: post
title: "Android Sensor ORIENTATION"
description: ""
category: 
tags: []
---
{% include JB/setup %}
这个就讲讲orientation里那个坐标系。

伸出你的右手，4指朝前(Y轴正方向)，拇指为向右(X轴正方向)，手掌心朝上(Z轴正方向)。同时放一个手机在你手掌上，话筒就在4指方向。

azimuth:YX形成平面绕Z轴旋转，Y轴指向北方时为0度，指向东为90度，其它类推。

pitch:ZY形成平面绕X轴旋转，Z轴朝X轴方向旋转为正值。如果手是一个飞机头为Y轴方向，飞机下俯为正。

roll:XZ形成平面绕Y轴旋转，X朝Z轴方向旋转为正值。

azimuth、pitch、roll这几个值都有范围，需要时见sensors.h了。

