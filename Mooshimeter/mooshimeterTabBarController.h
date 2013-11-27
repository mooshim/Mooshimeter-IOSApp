//
//  mooshimeterTabBarController.h
//  Mooshimeter
//
//  Created by James Whong on 9/18/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "mooshimeter_device.h"

@interface mooshimeterTabBarController : UITabBarController

@property (strong, nonatomic) mooshimeter_device *meter;

-(void)setDevice:(mooshimeter_device*)device;

-(void)onDisconnect;

@end
