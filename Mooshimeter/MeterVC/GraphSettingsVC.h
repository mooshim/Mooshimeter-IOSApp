//
// Created by James Whong on 5/14/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseVC.h"
#import "WYPopoverController.h"

// This class is meant to be displayed in a popover controller, so it's got some weirdnesses built in.

@interface GraphSettingsVC : UIViewController

@property (weak) WYPopoverController * popover;

@end