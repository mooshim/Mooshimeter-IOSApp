//
//  MooshimeterDeviceSimulator.m
//  Mooshimeter
//
//  Created by James Whong on 3/16/15.
//  Copyright (c) 2015 mooshim. All rights reserved.
//

#import "MooshimeterDeviceSimulator.h"

@implementation MooshimeterDeviceSimulator

@synthesize mSampleCB;
@synthesize ch1CB;
@synthesize ch2CB;

dispatch_time_t msInFuture(int dt) {
    return dispatch_time(DISPATCH_TIME_NOW,dt*1000000);
}

-(void)connect {
    // Simulate connection by settings everything to default and calling the delegates
    self->oad_mode = NO;
    
    self->meter_settings.ro.present_meter_state = METER_PAUSED;
    self->meter_settings.rw.target_meter_state = METER_PAUSED;
    self->meter_settings.rw.measure_settings = 0x00;
    self->meter_settings.rw.calc_settings = 0x06;
    self->meter_settings.rw.ch1set = 0x10;
    self->meter_settings.rw.ch2set = 0x10;
    self->meter_settings.rw.adc_settings = 0x00;

    dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate finishedMeterSetup];
    });
}

-(void)disconnect:(LGPeripheralConnectionCallback)aCallback {
    mSampleCB = nil;
    if(aCallback){aCallback(0);}
}

-(void)idleReadCall:(LGCharacteristicReadCallback)cb {
    // FIXME: Pack with something more elegant
    static uint8 tmp[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    // Dispatch the callback 30 ms after the call
    dispatch_time_t etime = msInFuture(30);
    dispatch_after(etime, dispatch_get_main_queue(), ^{
        NSData* payload = [NSData dataWithBytes:tmp length:sizeof(tmp)];
        cb(payload,0); // FIXME: find success macro
    });
}

-(void)reqMeterInfo:(LGCharacteristicReadCallback)cb {
    [self idleReadCall:cb];
}
-(void)reqMeterSettings:(LGCharacteristicReadCallback)cb {
    [self idleReadCall:cb];
}
-(void)reqMeterSample:(LGCharacteristicReadCallback)cb {
    [self idleReadCall:cb];
}
-(void)reqMeterLogSettings:(LGCharacteristicReadCallback)cb {
    [self idleReadCall:cb];
}
-(void)reqMeterBatteryLevel:(LGCharacteristicReadCallback)cb {
    [self idleReadCall:cb];
}

-(void)idleWriteCall:(LGCharacteristicWriteCallback)cb {
    // Dispatch the callback 60 ms after the call
    dispatch_time_t etime = msInFuture(30);
    dispatch_after(etime, dispatch_get_main_queue(), ^{
        cb(0);
    });
}

-(void)setMeterTime:(uint32)utc_time cb:(LGCharacteristicWriteCallback)cb {
    meter_utc_time = utc_time;
    [self idleWriteCall:cb];
}
-(void)sendMeterName:(NSString*)name cb:(LGCharacteristicWriteCallback)cb {
    [self idleWriteCall:cb];
}
-(void)sendMeterSettings:(LGCharacteristicWriteCallback)cb {
    [self idleWriteCall:cb];
}
-(void)sendMeterLogSettings:(LGCharacteristicWriteCallback)cb {
    [self idleWriteCall:cb];
}

/**
 Simulate the reception of a sample from the Mooshimeter
 */

-(void)onMeterSampleNotify {
    if(mSampleCB) {
        int delay_ms = 1000*[self getBufLen]/[self getSampleRate];
        dispatch_time_t etime = msInFuture(delay_ms);
        dispatch_after(etime, dispatch_get_main_queue(), ^{
            [self onMeterSampleNotify];
        });
        mSampleCB();
    }
}

-(void)enableStreamMeterSample:(BOOL)on cb:(LGCharacteristicNotifyCallback)cb update:(BufferDownloadCompleteCB)update {
    if(on) {
        mSampleCB = update;
        [self idleWriteCall:cb];
        dispatch_time_t etime = msInFuture(30);
        dispatch_after(etime, dispatch_get_main_queue(), ^{
            [self onMeterSampleNotify];
        });
    } else {
        mSampleCB = nil;
    }
}

/**
 Simulate the streaming of a buffer from the Mooshimeter
 */
-(void)onMeterStreamNotify {
    static int selected_ch = 0;
    static int24_test ch_buf[2][256];
    // Byte addresses
    static int buf_i = 0;
    static int buf_end = 0;
    
    uint8 ** byte_buf[2][256*sizeof(int24_test)];
    
    if(selected_ch == 0 && buf_i == 0) {
        // Initialize the simulated sample buffers
        for(int i = 0; i < [self getBufLen]; i++) {
            int val = (1<<21)*sin(60*2*3.14159*i/[self getSampleRate]);
            ch_buf[0][i] = [MooshimeterDevice to_int24_test:val];
            ch_buf[1][i] = [MooshimeterDevice to_int24_test:-1*val];
        }
        buf_end = sizeof(int24_test)*[self getBufLen];
    }
    int to_send = MIN(buf_end-buf_i, 20);
    NSData* payload = [NSData dataWithBytes:&(byte_buf[selected_ch][buf_i]) length:to_send];
    [self handleBufStreamUpdate:payload channel:selected_ch];
    buf_i += to_send;
    if(buf_i >= buf_end) {
        buf_i = 0;
        selected_ch = selected_ch?0:1;
    }
    if(selected_ch == 0 && buf_i == 0) {
        // We've finished streaming out our pretend buffer
        
    } else {
        // Schedule the next call
        dispatch_time_t etime = msInFuture(30);
        dispatch_after(etime, dispatch_get_main_queue(), ^{
            [self onMeterStreamNotify];
        });
    }
}

-(void)enableStreamMeterBuf:(BOOL)on cb:(LGCharacteristicNotifyCallback)cb complete_buffer_cb:(BufferDownloadCompleteCB)complete_buffer_cb {
    if(on) {
        self->buffer_cb = complete_buffer_cb;
        [self idleWriteCall:cb];
        dispatch_time_t etime = msInFuture(30);
        dispatch_after(etime, dispatch_get_main_queue(), ^{
            [self onMeterStreamNotify];
        });
    } else {
        [self idleWriteCall:cb];
    }
}

/*
 Return the highest possible build time, because we don't
 ever want to trigger a firmware update to the simulated meter
 */

-(uint32) getAdvertisedBuildTime {
    return 0xFFFFFFFF;
}

@end