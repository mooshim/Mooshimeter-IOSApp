//
//  SmartNavigationController.h
//  Mooshimeter
//
//  Created by James Whong on 11/6/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class AppDelegate;

@interface SmartNavigationController : UINavigationController

@property (strong,nonatomic) AppDelegate* app;

@end
