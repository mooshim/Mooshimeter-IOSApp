//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "InputDescriptor.h"

@implementation InputDescriptor
-(instancetype)init {
    self = [super init];
    self.name=@"";
    self.units=@"";
    self.ranges = [[Chooser alloc] init];
    return self;
}
-(instancetype)initWithName:(NSString*)name units_arg:(NSString*)units {
    self = [self init];
    self.name=name;
    self.units=units;
    return self;
}
@end