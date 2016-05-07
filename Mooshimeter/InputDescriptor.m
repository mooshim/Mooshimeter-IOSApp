//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "InputDescriptor.h"

@implementation InputDescriptor
-(instancetype)initWithName:(NSString*)name units_arg:(NSString*)units {
    self = [super init];
    self.name=name;
    self.units=units;
    self.ranges = [[Chooser alloc] init];
    return self;
}
@end