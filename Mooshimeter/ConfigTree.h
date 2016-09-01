//
// Created by James Whong on 5/26/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGBluetooth.h"
#import "ConfigNode.h"
#import "MooshimeterDevice.h"

@class ConfigNode;
@class MooshimeterDevice;

@interface ConfigTree : NSObject

@property ConfigNode* root;
@property MooshimeterDevice *meter;
@property uint8_t send_seq_n;
@property uint8_t recv_seq_n;
@property NSMutableData* recv_buf;
@property NSMutableDictionary<NSNumber*,ConfigNode*>* code_list;

-(void)attach:(MooshimeterDevice*)meter;
-(void)sendBytes:(NSData*)payload;
-(ConfigNode*) getNode:(NSString*)name;
-(NSObject*)getValueAt:(NSString*)name;
-(void)refreshAll;
-(void)command:(NSString*)cmd;
-(NSString*)getChosenName:(NSString*)name;
-(NSString*)enumerate;

@end