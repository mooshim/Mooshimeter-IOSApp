//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "Chooser.h"


@implementation Chooser
-(void)add:(id)new_value {
    [self.choices addObject:new_value];
}
-(id)get:(int)i {
    return [self.choices objectAtIndex:i];
}
-(void)clear{
    [self.choices removeAllObjects];
}
-(id)chooseByIndex:(int) i {
    self.chosen_i=i;
    return [self getChosen];
}
-(id)chooseObject:(id) obj {
    self.chosen_i = [self.choices indexOfObject:obj];
    return [self getChosen];
}
-(id)getChosen {
    return [self.choices objectAtIndex:self.chosen_i];
}
@end