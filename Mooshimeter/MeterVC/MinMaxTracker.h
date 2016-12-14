//
// Created by James Whong on 12/13/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MinMaxTracker : NSObject
@property float min;
@property float max;
@property float avg;
@property int n_samples;

// Clear the min, max and average
-(void)clear;
// Update the min, max and average with the provided sample
// Returns true if min or max updated
-(BOOL)process:(float)arg;
@end