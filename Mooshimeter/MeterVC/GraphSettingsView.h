//
// Created by James Whong on 5/14/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseVC.h"
#import "GraphVC.h"

// This class is meant to be displayed in a popover controller, so it's got some weirdnesses built in.

@interface TitledSwitch:UIView
@property UILabel* title;
@property UISwitch* sw;
@property void (^callback)(BOOL);
@end
@interface GraphSettingsView : UIView
@property GraphVC* graph;

@property TitledSwitch *xy_sw, *buffer_sw, *lock_sw, *ch1_auto, *ch2_auto;
@property UIButton *n_samples_button;
@end