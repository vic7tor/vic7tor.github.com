---
layout: post
title: "android sensors hal"
description: ""
category: 
tags: []
---
{% include JB/setup %}

#sensors_module_t

    struct sensors_module_t {
        struct hw_module_t common;

        int (*get_sensors_list)(struct sensors_module_t* module,
            struct sensor_t const** list);
    };

get_sensors_list返回值为sensor_t的个数。list返回sensor_t数组。

#sensor_t

    struct sensor_t {
        const char*     name;
        const char*     vendor; name和vendor随便起吧
        int             version; 似乎不是很重要。
        int             handle;　见SENSORS_HANDLE_XXX这些宏，SENSORS_HANDLE_BASE值为0,handle要比SENSORS_HANDLE_BASE大，handle值弄成sensor_t数组下标加1吧。
        int             type;　SENSOR_TYPE_XXX那些值
        float           maxRange;　最大值
        float           resolution;　精度
        float           power;　mA表示的烧电量
        int32_t         minDelay;　两次数据以mS为间隔，为0的话表示设备不以固定速率上报值，仅当有新值时才上报。为一个值时，在Android上层不是等这么久才调用poll函数的，SensorService里可以看到，所以在poll函数中可能需要休眠。
        void*           reserved[8];
    };

根据有get_sensors_list这个函数，把所有sensor_t定义成一个数组吧，这样也方便handle值的设定。

#sensors_poll_device_t

    struct hw_device_t common;
        struct hw_device_t common;
        int (*activate)(struct sensors_poll_device_t *dev,
            int handle, int enabled);
        int (*setDelay)(struct sensors_poll_device_t *dev,
            int handle, int64_t ns);
        int (*poll)(struct sensors_poll_device_t *dev,
            sensors_event_t* data, int count);
    }

这些函数返回0成功，返回负值出错。

activate enabled为1使能设备，为0禁止设备。

setDelay 设置两次上报事件的间隔。

poll 返回数据。返回值为数据的个数，这么说就可以少于count个了。

#sensors_event_t

    typedef struct sensors_event_t {
        /* must be sizeof(struct sensors_event_t) */
        int32_t version;
    
        /* sensor identifier */
        int32_t sensor;
    
        /* sensor type */
        int32_t type;
    
        /* reserved */
        int32_t reserved0;
    
        /* time is in nanosecond */
        int64_t timestamp;
    
        union {
            float           data[16];
    
            /* acceleration values are in meter per second per second (m/s^2) */
            sensors_vec_t   acceleration;
    
            /* magnetic vector values are in micro-Tesla (uT) */
            sensors_vec_t   magnetic;
    
            /* orientation values are in degrees */
            sensors_vec_t   orientation;
    
            /* gyroscope values are in rad/s */
            sensors_vec_t   gyro;
            /* temperature is in degrees centigrade (Celsius) */
            float           temperature;
    
            /* distance in centimeters */
            float           distance;
    
            /* light in SI lux units */
            float           light;
    
            /* pressure in hectopascal (hPa) */
            float           pressure;
    
            /* relative humidity in percent */
            float           relative_humidity;
        };
        uint32_t        reserved1[4];
    } sensors_event_t;

根据传感器类型填充union中的值。

timestamp用gettimeofday再把那个结构转为ns就行了。

#sensors_vec_t

    typedef struct {
        union {
            float v[3];
            struct {
                float x;
                float y;
                float z;
            };
            struct {
                float azimuth;
                float pitch;
                float roll;
            };
        };
        int8_t status;
        uint8_t reserved[3];
    } sensors_vec_t;

union根据传感器类型来填充，这个sensors.h中有讲。

status应该就是SENSOR_STATUS_XXX这些宏了。

    SENSOR_STATUS_UNRELIABLE		不可靠
    SENSOR_STATUS_ACCURACY_LOW		精度低
    SENSOR_STATUS_ACCURACY_MEDIUM	精度中
    SENSOR_STATUS_ACCURACY_HIGH		精度高
