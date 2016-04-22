/*
 BLETIOADProfile.h
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import <CoreBluetooth/CoreBluetooth.h>
#import "BLETIOADProgressDialog.h"
#import "BLETIOADProgressViewController.h"
#import "LegacyMooshimeterDevice.h"
#import "oad.h"

@class BLETIOADProgressViewController;

@interface BLETIOADProfile : NSObject <UIActionSheetDelegate,UIAlertViewDelegate,CBPeripheralDelegate>

@property (strong,nonatomic) NSData *imageFile;
@property (strong,nonatomic) BLETIOADProgressDialog *progressDialog;
@property (strong,nonatomic) UIView *view;

@property int nBlocks;
@property int nBytes;
@property int iBlocks;
@property int iBytes;
@property BOOL canceled;
@property BOOL inProgramming;
@property BOOL start;
@property (nonatomic,retain) NSTimer *imageDetectTimer;
@property uint16_t imgVersion;
@property UINavigationController *navCtrl;

//In case of iOS 7.0
@property (strong,nonatomic) BLETIOADProgressViewController *progressView;

-(instancetype) init;
-(void) makeConfigurationForProfile;
-(void) configureProfile;
-(void) deconfigureProfile;
-(void) didUpdateValueForProfile:(CBCharacteristic *)characteristic;
-(void)deviceDisconnected:(CBPeripheral *)peripheral;

-(void) uploadImage:(NSString *)filename;

-(IBAction)selectImagePressed:(id)sender;

-(void) programmingTimerTick:(NSTimer *)timer;
-(void) imageDetectTimerTick:(NSTimer *)timer;

-(NSMutableArray *) findFWFiles;

-(BOOL) validateImage:(NSString *)filename;
-(BOOL) isCorrectImage;
-(void) completionDialog;

@end
