/*
 BLETIOADProfile.m
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "BLETIOADProfile.h"
#import "BLETIOADProgressDialog.h"
#import "BLEUtility.h"


@implementation BLETIOADProfile


-(id) init {
    self = [super init];
    if (self) {
        self.canceled = FALSE;
        self.inProgramming = FALSE;
        self.start = YES;
        // Become the peripheral delegate
        g_meter.p.cbPeripheral.delegate = self;
    }
    return self;
}

#if 0
-(void) makeConfigurationForProfile {
}

-(void) configureProfile {
    NSLog(@"Configurating OAD Profile");
    [BLEUtility setNotificationForOADCharacteristic:self.d.p cUUID:OAD_IMAGE_NOTIFY enable:YES];
    unsigned char data = 0x00;
    [BLEUtility writeOADCharacteristic:self.d.p cUUID:OAD_IMAGE_NOTIFY data:[NSData dataWithBytes:&data length:1]];
    self.imageDetectTimer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(imageDetectTimerTick:) userInfo:nil repeats:NO];
    self.imgVersion = 0xFFFF;
    self.start = YES;
}

-(void) deconfigureProfile {
    NSLog(@"Deconfiguring OAD Profile");
    [BLEUtility setNotificationForOADCharacteristic:self.d.p.cbPeripheral cUUID:OAD_IMAGE_NOTIFY enable:YES];
}

-(IBAction)selectImagePressed:(id)sender {
    if (![self.d.p.cbPeripheral isConnected]) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Device disconnected !" message:@"Unable to start programming when device is not connected ..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Reconnect",nil];
        [alertView show];
        alertView.tag = 1;
        return;
    }
    UIActionSheet *selectImageActionSheet = [[UIActionSheet alloc]initWithTitle:@"Select image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Internal Image ...",@"Shared files ...",nil];
    selectImageActionSheet.tag = 0;
    [selectImageActionSheet showInView:self.view];

    
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"Button clicked : %d",buttonIndex);
    switch (actionSheet.tag) {
        case 0: {
            switch(buttonIndex) {
                case 0: {
                    UIActionSheet *selectInternalFirmwareSheet = [[UIActionSheet alloc]initWithTitle:@"Select Firmware image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Mooshimeter.bin", nil];
                    selectInternalFirmwareSheet.tag = 1;
                    [selectInternalFirmwareSheet showInView:self.view];
                    break;
                }
                case 1: {
                    NSMutableArray *files = [self findFWFiles];
                    UIActionSheet *selectSharedFileFirmware = [[UIActionSheet alloc]init];
                    selectSharedFileFirmware.title = @"Select Firmware image";
                    selectSharedFileFirmware.tag = 2;
                    selectSharedFileFirmware.delegate = self;
                    
                    for (NSString *fileName in files) {
                        [selectSharedFileFirmware addButtonWithTitle:[fileName lastPathComponent]];
                    }
                    [selectSharedFileFirmware addButtonWithTitle:@"Cancel"];
                    selectSharedFileFirmware.cancelButtonIndex = selectSharedFileFirmware.numberOfButtons - 1;
                    [selectSharedFileFirmware showInView:self.view];
                    break;
                }
            }
            break;
        }
        case 1: {
            switch (buttonIndex) {
                case 0: {
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"Mooshimeter.bin"];
                    [self validateImage:path];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 2: {
            if (buttonIndex == actionSheet.numberOfButtons - 1) break;
            NSMutableArray *files = [self findFWFiles];
            NSString *fileName = [files objectAtIndex:buttonIndex];
            [self validateImage:fileName];
            break;
        }
        default:
        break;
    }
}


-(void) uploadImage:(NSString *)filename {
    self.inProgramming = YES;
    self.canceled = NO;
    


    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
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

    [BLEUtility writeOADCharacteristic:self.d.p cUUID:OAD_IMAGE_NOTIFY data:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2]];
    
    self.nBlocks = imgHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);
    self.nBytes = imgHeader.len * HAL_FLASH_WORD_SIZE;
    self.iBlocks = 0;
    self.iBytes = 0;
   
  
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
    
}

-(void) programmingTimerTick:(NSTimer *)timer {
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }
    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    //Prepare Block
    uint8_t requestData[2 + OAD_BLOCK_SIZE];
    
    // This block is run 4 times, this is needed to get CoreBluetooth to send consequetive packets in the same connection interval.
    for (int ii = 0; ii < 4; ii++) {
        
        requestData[0] = LO_UINT16(self.iBlocks);
        requestData[1] = HI_UINT16(self.iBlocks);
        
        memcpy(&requestData[2] , &imageFileData[self.iBytes], OAD_BLOCK_SIZE);
        
        [BLEUtility writeNoResponseOADCharacteristic:self.d.p cUUID:OAD_IMAGE_BLOCK_REQ data:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE]];
        
        self.iBlocks++;
        self.iBytes += OAD_BLOCK_SIZE;
        
        if(self.iBlocks == self.nBlocks) {
            if ([BLEUtility runningiOSSeven]) {
                [self.navCtrl popToRootViewControllerAnimated:YES];
            }
            else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
            self.inProgramming = NO;
            self.d.p.cbPeripheral.delegate = self.d;
            [self completionDialog];
            return;
        }
        else {
            if (ii == 3)[NSTimer scheduledTimerWithTimeInterval:0.09 target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
        }
    }
    self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
    self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
    float secondsPerBlock = 0.09 / 4;
    float secondsLeft = (float)(self.nBlocks - self.iBlocks) * secondsPerBlock;
    
    if ([BLEUtility runningiOSSeven]) {
        self.progressView.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        self.progressView.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressView.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    else {
        self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressDialog.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    
    NSLog(@".");
    if (self.start) {
        self.start = NO;
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl pushViewController:self.progressView animated:YES];
        
        }
        else {
            self.progressDialog = [[BLETIOADProgressDialog alloc]initWithFrame:CGRectMake((self.view.bounds.size.width / 2) - 150, (self.view.bounds.size.height /2) - 80, self.view.bounds.size.width, 160)];
            self.progressDialog.delegate = self;
            [self.progressDialog show];
        }
    }
}


-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([characteristic.UUID isEqual:[BLEUtility expandToMooshimUUID:OAD_IMAGE_NOTIFY]]) {
        if (self.imgVersion == 0xFFFF) {
            unsigned char data[characteristic.value.length];
            [characteristic.value getBytes:&data];
            self.imgVersion = ((uint16_t)data[1] << 8 & 0xff00) | ((uint16_t)data[0] & 0xff);
            NSLog(@"self.imgVersion : %04hx",self.imgVersion);
         }
        NSLog(@"OAD Image notify : %@",characteristic.value);
        
    }
}

-(void) didWriteValueForProfile:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForProfile : %@",characteristic);
}

-(NSMutableArray *) findFWFiles {
    NSMutableArray *FWFiles = [[NSMutableArray alloc]init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *publicDocumentsDir = [paths objectAtIndex:0];
    
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:publicDocumentsDir error:&error];
    
    
    if (files == nil) {
        NSLog(@"Could not find any firmware files ...");
        return FWFiles;
    }
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"bin" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSString *fullPath = [publicDocumentsDir stringByAppendingPathComponent:file];
            [FWFiles addObject:fullPath];
        }
    }

    return FWFiles;
}


-(void)deviceDisconnected:(CBPeripheral *)peripheral {
    if ([peripheral isEqual:self.d.p] && self.inProgramming) {
        [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"FW Upgrade Failed !" message:@"Device disconnected during programming, firmware upgrade was not finished !" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = 0;
        [alertView show];
        self.inProgramming = NO;
        
    }
}


-(BOOL)validateImage:(NSString *)filename {
    self.imageFile = [NSData dataWithContentsOfFile:filename];
    NSLog(@"Loaded firmware \"%@\"of size : %d",filename,self.imageFile.length);
    if ([self isCorrectImage]) [self uploadImage:filename];
    else {
        UIAlertView *wrongImage = [[UIAlertView alloc]initWithTitle:@"Wrong image type !" message:[NSString stringWithFormat:@"Image that was selected was of type : %c, which is the same as on the peripheral, please select another image",(self.imgVersion & 0x01) ? 'B' : 'A'] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [wrongImage show];
    }
    return NO;
}
-(BOOL) isCorrectImage {
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    if ((imgHeader.ver & 0x01) != (self.imgVersion & 0x01)) return YES;
    return NO;
}

-(void) imageDetectTimerTick:(NSTimer *)timer {
    //IF we have come here, the image userID is B.
    NSLog(@"imageDetectTimerTick:");
    unsigned char data = 0x01;
    [BLEUtility writeOADCharacteristic:self.d.p cUUID:OAD_IMAGE_NOTIFY data:[NSData dataWithBytes:&data length:1]];
}

-(void) completionDialog {
    UIAlertView *complete;
        complete = [[UIAlertView alloc]initWithTitle:@"Firmware upgrade complete" message:@"Firmware upgrade was successfully completed, device needs to be reconnected" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [complete show];
}
#endif
@end





