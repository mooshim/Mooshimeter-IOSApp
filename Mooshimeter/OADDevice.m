/**************************
Mooshimeter iOS App - interface to Mooshimeter wireless multimeter
Copyright (C) 2015  James Whong

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************/

#import "OADDevice.h"
#import "oad.h"

@implementation OADDevice

-(instancetype) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate {
    self = [super init];

    self.periph = periph;
    self.chars = [[NSMutableDictionary alloc]init];

    [self addDelegate:delegate];

    // Populate our characteristic array
    for(LGService * service in periph.services) {
        if (        [service.UUIDString isEqualToString:[BLEUtility expandToMooshimUUIDString:OAD_SERVICE_UUID]]
                ||  [service.UUIDString isEqualToString:[BLEUtility expandToMooshimUUIDString:METER_SERVICE_UUID]]) {
            [self populateLGDict:service.characteristics];
            break;
        }
    }

    [self.delegate onInit];
    
    return self;
}

/*
 For convenience, builds a dictionary of the LGCharacteristics based on the relevant
 2 bytes of their UUID
 @param characteristics An array of LGCharacteristics
 @return void
 */

-(void)populateLGDict:(NSArray*)characteristics {
    for (LGCharacteristic* c in characteristics) {
        NSLog(@"    Char: %@", c.UUIDString);
        uint16 lookup;
        [c.cbCharacteristic.UUID.data getBytes:&lookup range:NSMakeRange(2, 2)];
        lookup = NSSwapShort(lookup);
        NSNumber* key = [NSNumber numberWithInt:lookup];
        self.chars[key] = c;
    }
}

-(void)disconnect:(LGPeripheralConnectionCallback)aCallback {
    [self.periph disconnectWithCompletion:aCallback];
}

-(void)accidentalDisconnect:(NSError*)error {
    DLog(@"Accidental disconnect!");
    [self.delegate onDisconnect];
}

-(LGCharacteristic*)getLGChar:(uint16)UUID {
    return self.chars[[NSNumber numberWithInt:UUID]];
}

#pragma mark MooshimeterControlProtocol_methods

@end
