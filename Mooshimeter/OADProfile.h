/*
 BLETIOADProfile.h
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "OADProgressViewController.h"
#import "MooshimeterDevice.h"
#import "oad.h"

@class BLETIOADProgressViewController;

@interface OADProfile : NSObject <UIActionSheetDelegate,UIAlertViewDelegate,CBPeripheralDelegate>

@property (strong,nonatomic) NSData *imageFile;

@property int nBlocks;
@property int nBytes;
@property int iBlocks;
@property int iBytes;
@property BOOL canceled;
@property BOOL inProgramming;
@property BOOL start;
@property (nonatomic,retain) NSTimer *imageDetectTimer;
@property UINavigationController *navCtrl;

@property (strong,nonatomic) BLETIOADProgressViewController *progressView;

@property (strong,nonatomic) dispatch_semaphore_t pacer_sem;

-(instancetype) init;

-(void) startUpload:(NSString*) filename;

-(void) programmingTimerTick:(NSTimer *)timer;

-(void) completionDialog;

@end
