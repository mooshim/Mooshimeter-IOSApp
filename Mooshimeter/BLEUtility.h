//
//  BLEUtility.h
//
//  Created by Ole Andreas Torvmark on 9/22/12.
//  Copyright (c) 2012 Texas Instruments. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define TI_BASE_LONG_UUID @"F0000000-0451-4000-B000-000000000000"

@interface BLEUtility : NSObject

+(void)readCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID;

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID enable:(BOOL)enable;
+(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data;

+(void)writeCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data;
+(void)readCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID;
+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID enable:(BOOL)enable;

+(bool) isCharacteristicNotifiable:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *) cCBUUID;

/// Function to expand a TI 16-bit UUID to TI 128-bit UUID
+(CBUUID *) expandToTIUUID:(CBUUID *)sourceUUID;
/// Function to convert an CBUUID to NSString
+(NSString *) CBUUIDToString:(CBUUID *)inUUID;

@end
