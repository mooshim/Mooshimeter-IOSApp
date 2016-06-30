/*
 BLETIOADProfile.h
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "OADProgressViewController.h"
#import "LegacyMooshimeterDevice.h"
#import "oad.h"

@class OADViewController;

@interface OADProfile : NSObject <UIActionSheetDelegate,UIAlertViewDelegate,CBPeripheralDelegate>

@property int nBlocks;
@property int iBlocks;
@property int iBytes;
@property BOOL canceled;
@property BOOL inProgramming;

@property id<MooshimeterControlProtocol> meter;

@property (strong,nonatomic) OADViewController *progressView;
@property (strong,nonatomic) dispatch_semaphore_t pacer_sem;

-(instancetype) init:(id<MooshimeterControlProtocol>)new_meter;
-(void) startUpload;

@end
