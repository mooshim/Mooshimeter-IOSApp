//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "Chooser.h"


@implementation Chooser
-(instancetype)init {
    self.choices = [[NSMutableArray alloc]init];
    self.chosen_i = 0;
    return self;
}
-(void)add:(id)new_value {
    [self.choices addObject:new_value];
}
-(id)get:(int)i {
    if([self getNChoices]<=i) {
        return nil;
    }
    return self.choices[i];
}
-(void)clear{
    [self.choices removeAllObjects];
}
-(id)chooseByIndex:(unsigned int) i {
    self.chosen_i=i;
    return [self getChosen];
}
-(id)chooseObject:(id) obj {
    self.chosen_i = [self.choices indexOfObject:obj];
    return [self getChosen];
}
-(id)getChosen {
    return self.choices[self.chosen_i];
}

- (int)getNChoices {
    return [self.choices count];
}

@end