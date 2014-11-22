//
//  BLEUtility.h
//
//  Created by Ole Andreas Torvmark on 9/22/12.
//  Copyright (c) 2012 Texas Instruments. All rights reserved.
//
//  Modified for Mooshimeter, James Whong
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "MooshimeterProfileTypes.h"

@interface BLEUtility : NSObject

// Convenience functions that deal only with the OAD profile
+(void)readOADCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID;
+(void)writeOADCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID data:(NSData *)data;
+(void)setNotificationForOADCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID enable:(BOOL)enable;

+(void)writeNoResponseOADCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID data:(NSData *)data;
+(void)writeNoResponseCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data;

// Convenience functions that deal only with the Mooshimeter profile
+(void)readCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID;
+(void)writeCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID data:(NSData *)data;
+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID enable:(BOOL)enable;

+(void)readCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID;
+(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data;
+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID enable:(BOOL)enable;

+(void)readCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID;
+(void)writeCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data;
+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID enable:(BOOL)enable;

+(bool) isCharacteristicNotifiable:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *) cCBUUID;

/// Function to expand a 16-bit UUID to 128-bit UUID
+(CBUUID *) expandToMooshimUUID:(uint16_t)sourceUUID;
/// Function to expand a 16-bit UUID to 128-bit UUID
+(NSString *) expandToMooshimUUIDString:(uint16_t)sourceUUID;

@end
