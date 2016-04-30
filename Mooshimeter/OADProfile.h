/*
 BLETIOADProfile.h
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "OADProgressViewController.h"
#import "LegacyMooshimeterDevice.h"
#import "oad.h"

@class BLETIOADProgressViewController;

@interface OADProfile : NSObject <UIActionSheetDelegate,UIAlertViewDelegate,CBPeripheralDelegate> {
    @public
    img_hdr_t imageHeader;
}

@property (strong,nonatomic) NSData *imageData;

@property int nBlocks;
@property int iBlocks;
@property int iBytes;
@property BOOL canceled;
@property BOOL inProgramming;
@property BOOL start;
@property UINavigationController *navCtrl;

@property id<MooshimeterControlProtocol> meter;

@property (strong,nonatomic) BLETIOADProgressViewController *progressView;
@property (strong,nonatomic) dispatch_semaphore_t pacer_sem;

-(instancetype) init:(id<MooshimeterControlProtocol>)new_meter;
-(void) startUpload;
-(void) completionDialog;

@end
