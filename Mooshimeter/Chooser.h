//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Chooser : NSObject
@property (strong,atomic) NSMutableArray * choices;
@property int chosen_i;

-(void)add:(id) new_value;
-(id)get:(int) i;
-(void)clear;
-(id)choose:(int) i;
-(id)getChosen;
@end