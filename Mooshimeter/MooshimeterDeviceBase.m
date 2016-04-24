//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MooshimeterDeviceBase.h"
#import "LGCharacteristic.h"


@implementation MooshimeterDeviceBase
#pragma mark MooshimeterControlProtocol_methods
-(void)addDelegate:(id<MooshimeterDelegateProtocol>)d {
    self.delegate = d;
}
-(void)removeDelegate {
    self.delegate = NULL;
}
@end