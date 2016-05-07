//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RangeDescriptor.h"
#import "Chooser.h"

@interface InputDescriptor : NSObject
@property NSString* name;
@property NSString* units;
@property Chooser* ranges;

-(instancetype)initWithName:(NSString*)name units_arg:(NSString*)units;

@end