/*
 BLETIOADProfile.m
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "OADProfile.h"
#import "SmartNavigationController.h"
#import "FirmwareImageDownloader.h"
#import "WidgetFactory.h"
#import "GCD.h"

@implementation OADProfile

-(id) init:(id<MooshimeterControlProtocol>)new_meter {
    self = [super init];
    if (self) {
        self.meter = new_meter;
        self.canceled = FALSE;
        self.inProgramming = FALSE;
    }
    return self;
}

-(void) startUpload {
    if(![FirmwareImageDownloader isFirmwareDownloadComplete]) {
        NSLog(@"Can't start firmware upload over BLE because I don't have an image to upload!");
        return;
    }

    NSLog(@"Configuring OAD Profile");
    LGCharacteristic* image_notify = [self.meter getLGChar:OAD_IMAGE_NOTIFY];
    LGCharacteristic* image_block  = [self.meter getLGChar:OAD_IMAGE_BLOCK_REQ];
    self.pacer_sem = dispatch_semaphore_create(8);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDisconnect:)
                                                 name:kLGPeripheralDidDisconnect
                                               object:nil];
    
    [image_block setNotifyValue:YES completion:^(NSError *error) {
        [image_notify setNotifyValue:YES completion:^(NSError *error) {
            [self uploadImage];
        } onUpdate:^(NSData *data, NSError *error) {
            NSLog(@"OAD Notify: %@", data);
        }];
    } onUpdate:^(NSData *data, NSError *error) {
        uint16 bn;
        [data getBytes:&bn length:2];
        NSLog(@"Received block notification %d",bn);
        dispatch_semaphore_signal(self.pacer_sem);
    }];
}

-(void)handleDisconnect:(NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self.iBlocks == self.nBlocks) {
        // We finished before disconnecting, don't display a failure.
    }
    [GCD asyncMain:^{
        [WidgetFactory makeAlert:@"FW Upgrade Failed !" msg:@"Device disconnected during programming, firmware upgrade was not finished !"];
    }];
    self.inProgramming = NO;
    self.canceled = YES;
}

-(void) uploadImage {
    self.inProgramming = YES;
    self.canceled = NO;

    NSData* imageData = [FirmwareImageDownloader getFirmwareImageData];
    unsigned char imageFileData[imageData.length];
    [imageData getBytes:imageFileData length:imageData.length];
    uint8_t requestData[OAD_IMG_HDR_SIZE + 2 + 2]; // 12Bytes
    
    for(int ii = 0; ii < 20; ii++) {
        NSLog(@"%02hhx",imageFileData[ii]);
    }
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    requestData[0] = LO_UINT16(imgHeader.ver);
    requestData[1] = HI_UINT16(imgHeader.ver);
    
    requestData[2] = LO_UINT16(imgHeader.len);
    requestData[3] = HI_UINT16(imgHeader.len);
    
    NSLog(@"Image version = %04hx, len = %04hx",imgHeader.ver,imgHeader.len);
    
    memcpy(requestData + 4, &imgHeader.build_time, sizeof(imgHeader.build_time));
    
    requestData[OAD_IMG_HDR_SIZE + 0] = LO_UINT16(12);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(12);
    
    requestData[OAD_IMG_HDR_SIZE + 2] = LO_UINT16(15);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(15);

    
    LGCharacteristic* image_notify = [self.meter getLGChar:OAD_IMAGE_NOTIFY];
    [image_notify writeValue:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2] completion:nil];
    
    self.nBlocks = imgHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);
    self.iBlocks = 0;
    self.iBytes = 0;

    [GCD asyncMain:^{
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgressBars:) userInfo:nil repeats:YES];
    }];
    [GCD asyncBack:^{[self sendNextBlock];}];
}

-(void)sendNextBlock {
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }

    NSData* imageData = [FirmwareImageDownloader getFirmwareImageData];
    
    NSLog(@"Sending block %d of %d", self.iBlocks, self.nBlocks);
    
    //Prepare Block
    struct {
        uint16 bnum;
        uint8  payload[OAD_BLOCK_SIZE];
    } __attribute__((packed)) requestData;
    
    //requestData[0] = LO_UINT16(self.iBlocks);
    //requestData[1] = HI_UINT16(self.iBlocks);
    requestData.bnum = self.iBlocks;
    [imageData getBytes:requestData.payload range:NSMakeRange(self.iBytes,OAD_BLOCK_SIZE)];
    
    LGCharacteristic* image_block_req = [self.meter getLGChar:OAD_IMAGE_BLOCK_REQ];
    
    dispatch_semaphore_wait(self.pacer_sem, DISPATCH_TIME_FOREVER);
    [image_block_req writeValueNoResponse:[NSData dataWithBytes:&requestData length:sizeof(requestData)]];
    
    self.iBlocks++;
    self.iBytes += OAD_BLOCK_SIZE;
    
    if(self.iBlocks == self.nBlocks) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.inProgramming = NO;
        SmartNavigationController * nav = [SmartNavigationController getSharedInstance];
        [GCD asyncMain:^{
            [WidgetFactory makeAlert:@"Firmware upgrade complete" msg:@"Firmware upgrade was successfully completed, device needs to be reconnected"];
            [nav popToRootViewControllerAnimated:YES];
        }];
        return;
    }
    [GCD asyncBack:^{[self sendNextBlock];}];
}

-(void) updateProgressBars:(NSTimer *)timer {
    [GCD asyncMain:^{
        if(self.canceled || !self.inProgramming) {
            [timer invalidate];
        }
        NSLog(@"Updating progress bars...");
        float secondsPerBlock = 0.03 / 4;
        float secondsLeft = (float)(self.nBlocks - self.iBlocks) * secondsPerBlock;
        
        self.progressView.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        self.progressView.percent_label.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressView.timing_label.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }];
}
@end





