//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "InputDescriptor.h"

@implementation InputDescriptor
-(InputDescriptor*)init:(NSString*)name units_arg:(NSString*)units {
    self.name=name;
    self.units=units;
    self.ranges = [[Chooser alloc] init];
    return self;
}
@end