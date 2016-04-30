/*
 BLETIOADProfile.m
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "OADProfile.h"
#import "MooshimeterControlProtocol.h"

@implementation OADProfile

-(id) init:(id<MooshimeterControlProtocol>)new_meter {
    self = [super init];
    if (self) {
        self.meter = new_meter;
        self.canceled = FALSE;
        self.inProgramming = FALSE;
        self.start = YES;
        NSString *stringURL = @"https://moosh.im/s/f/mooshimeter-firmware-latest.bin";
        //NSString *stringURL = @"https://moosh.im/s/f/mooshimeter-firmware-beta.bin";
        NSURL  *url = [NSURL URLWithString:stringURL];
        self->imageHeader.build_time=0;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            self.imageData = [NSData dataWithContentsOfURL:url];
            NSLog(@"Loaded firmware of size : %d",(int)self.imageData.length);
            if(self.imageData.length==0) {
                // We failed to load the firmware.  Should we do something?
            } else {
                [self.imageData getBytes:&self->imageHeader length:sizeof(img_hdr_t)];
            }
        });
    }
    return self;
}

-(void) startUpload {
    NSLog(@"Configuring OAD Profile");
    self.start = YES;
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
    [self.navCtrl popToRootViewControllerAnimated:YES];
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"FW Upgrade Failed !" message:@"Device disconnected during programming, firmware upgrade was not finished !" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alertView.tag = 0;
    [alertView show];
    self.inProgramming = NO;
    self.canceled = YES;
}

-(void) uploadImage {
    self.inProgramming = YES;
    self.canceled = NO;
    
    unsigned char imageFileData[self.imageData.length];
    [self.imageData getBytes:imageFileData length:self.imageData.length];
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
   
    if (self.start) {
        self.start = NO;
        [self.navCtrl pushViewController:self.progressView animated:YES];
    }
  
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgressBars:) userInfo:nil repeats:YES];
    dispatch_queue_t rq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(rq, ^{
        [self sendNextBlock];
    });
}

-(void)sendNextBlock {
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }
    
    unsigned char imageFileData[self.imageData.length];
    [self.imageData getBytes:imageFileData length:self.imageData.length];
    
    NSLog(@"Sending block %d of %d", self.iBlocks, self.nBlocks);
    
    //Prepare Block
    uint8_t requestData[2 + OAD_BLOCK_SIZE];
    
    requestData[0] = LO_UINT16(self.iBlocks);
    requestData[1] = HI_UINT16(self.iBlocks);
    
    memcpy(&requestData[2] , &imageFileData[self.iBytes], OAD_BLOCK_SIZE);
    
    LGCharacteristic* image_block_req = [self.meter getLGChar:OAD_IMAGE_BLOCK_REQ];
    
    dispatch_semaphore_wait(self.pacer_sem, DISPATCH_TIME_FOREVER);
    [image_block_req writeValue:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE] completion:nil];
    
    self.iBlocks++;
    self.iBytes += OAD_BLOCK_SIZE;
    
    if(self.iBlocks == self.nBlocks) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.navCtrl popToRootViewControllerAnimated:YES];
        self.inProgramming = NO;
        dispatch_queue_t mq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(mq, ^{
            [self completionDialog];
        });
        return;
    }
    dispatch_queue_t rq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(rq, ^{
        [self sendNextBlock];
    });
}

-(void) updateProgressBars:(NSTimer *)timer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.canceled || !self.inProgramming) {
            [timer invalidate];
        }
        NSLog(@"Updating progress bars...");
        float secondsPerBlock = 0.03 / 4;
        float secondsLeft = (float)(self.nBlocks - self.iBlocks) * secondsPerBlock;
        
        self.progressView.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        self.progressView.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressView.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    });
}

-(void) completionDialog {
    UIAlertView *complete;
        complete = [[UIAlertView alloc]initWithTitle:@"Firmware upgrade complete" message:@"Firmware upgrade was successfully completed, device needs to be reconnected" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [complete show];
}
@end





