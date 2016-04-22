//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "InputDescriptor.h"

@implementation InputDescriptor
-(InputDescriptor*)init:(NSString*)name_arg units_arg:(NSString*)units_arg {
    name=name_arg;
    units=units_arg;
    ranges = [[Chooser alloc] init];
    return self;
}
@end