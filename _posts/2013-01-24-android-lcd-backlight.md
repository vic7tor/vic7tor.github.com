---
layout: post
title: "android lcd backlight"
description: ""
category: 
tags: []
---
{% include JB/setup %}

管LCD背光的HAL就是lights。有一份Google的通用代码，使用的是内核的backlight class。

lights的HAL也非常简单。所以要实现内核的这驱动了。

linux内核的讲下那个CONFIG_BACKLIGHT_PWM

代码实现在：drivers/video/backlight/pwm_bl.c

包含linux/pwm_backlight.h

    static struct platform_pwm_backlight_data mini210_backlight_data = {
        .pwm_id                 = MINI210_BL_PWM,
        .max_brightness = 255,
        .dft_brightness = 255,
        .pwm_period_ns  = 78770,
        .init           = mini210_backlight_init,
        .exit           = mini210_backlight_exit,
    };

    static struct platform_device mini210_backlight_device = {
        .name           = "pwm-backlight",
        .dev            = {
                .parent         = &s3c_device_timer[MINI210_BL_PWM].dev,
                .platform_data  = &mini210_backlight_data,
        },
    }

platform_device的名字叫pwm-backlight。然后platform_pwm_backlight_data要放在platform_data
