//
//  BLEUtility.m
//
//  Created by Ole Andreas Torvmark on 9/22/12.
//  Copyright (c) 2012 Texas Instruments. All rights reserved.
//

#import "BLEUtility.h"

@implementation BLEUtility

+(void)writeCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID data:(NSData *)data {
    [BLEUtility writeCharacteristic:peripheral sCBUUID:[BLEUtility expandToMooshimUUID:METER_SERVICE_UUID] cCBUUID:[BLEUtility expandToMooshimUUID:cUUID] data:data];
}

+(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data {
    [BLEUtility writeCharacteristic:peripheral sCBUUID:[CBUUID UUIDWithString:sUUID] cCBUUID:[CBUUID UUIDWithString:cUUID] data:data];
}

+(void)writeCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data {
    // Sends data to BLE peripheral to process HID and send EHIF command to PC
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    
                }
            }
        }
    }
}


+(void)readCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID {
    [BLEUtility readCharacteristic:peripheral sCBUUID:[BLEUtility expandToMooshimUUID:METER_SERVICE_UUID] cCBUUID:[BLEUtility expandToMooshimUUID:cUUID]];
}

+(void)readCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID {
    [BLEUtility readCharacteristic:peripheral sCBUUID:[CBUUID UUIDWithString:sUUID] cCBUUID:[CBUUID UUIDWithString:cUUID]];
}

+(void)readCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID {
    for ( CBService *service in peripheral.services ) {
        if([service.UUID isEqual:sCBUUID]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    /* Everything is found, read characteristic ! */
                    [peripheral readValueForCharacteristic:characteristic];
                }
            }
        }
    }
}

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral cUUID:(uint16_t)cUUID enable:(BOOL)enable {
    [BLEUtility setNotificationForCharacteristic:peripheral sCBUUID:[BLEUtility expandToMooshimUUID:METER_SERVICE_UUID] cCBUUID:[BLEUtility expandToMooshimUUID:cUUID] enable:enable];
}

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID enable:(BOOL)enable {
    [BLEUtility setNotificationForCharacteristic:peripheral sCBUUID:[CBUUID UUIDWithString:sUUID] cCBUUID:[CBUUID UUIDWithString:cUUID] enable:enable];
}

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID enable:(BOOL)enable {
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID])
                {
                    /* Everything is found, set notification ! */
                    [peripheral setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}


+(bool) isCharacteristicNotifiable:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *) cCBUUID {
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID])
                {
                    if (characteristic.properties & CBCharacteristicPropertyNotify) return YES;
                    else return NO;
                }
                
            }
        }
    }
    return NO;
}


+(CBUUID *) expandToMooshimUUID:(uint16_t)sourceUUID {
    unsigned char expandedUUIDBytes[16] = {MOOSHIM_BASE_UUID_128(sourceUUID)};
    // FIXME:  For some reason iOS expects reversed UUIDs
    for(int i = 0; i < 8; i++) {
        expandedUUIDBytes[i]    ^= expandedUUIDBytes[15-i];
        expandedUUIDBytes[15-i] ^= expandedUUIDBytes[i];
        expandedUUIDBytes[i]    ^= expandedUUIDBytes[15-i];
    }
    return [CBUUID UUIDWithData:[NSData dataWithBytes:expandedUUIDBytes length:16]];
}


+(NSString *) CBUUIDToString:(CBUUID *)inUUID {
    unsigned char i[16];
    [inUUID.data getBytes:i];
    if (inUUID.data.length == 2) {
        return [NSString stringWithFormat:@"%02hhx%02hhx",i[0],i[1]];
    }
    else {
        uint32_t g1 = ((i[0] << 24) | (i[1] << 16) | (i[2] << 8) | i[3]);
        uint16_t g2 = ((i[4] << 8) | (i[5]));
        uint16_t g3 = ((i[6] << 8) | (i[7]));
        uint16_t g4 = ((i[8] << 8) | (i[9]));
        uint16_t g5 = ((i[10] << 8) | (i[11]));
        uint32_t g6 = ((i[12] << 24) | (i[13] << 16) | (i[14] << 8) | i[15]);
        return [NSString stringWithFormat:@"%08x-%04hx-%04hx-%04hx-%04hx%08x",g1,g2,g3,g4,g5,g6];
    }
    return nil;
}
  
@end
