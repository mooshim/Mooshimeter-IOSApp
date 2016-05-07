//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Chooser : NSObject
@property (strong,atomic) NSMutableArray * choices;
@property unsigned int chosen_i;

-(void)add:(id) new_value;
-(id)get:(int) i;
-(void)clear;
-(id)chooseByIndex:(unsigned int) i;
-(id)chooseObject:(id) obj;
-(id)getChosen;
-(int)getNChoices;
@end