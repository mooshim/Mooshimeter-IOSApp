//
//  mooshimeterTabBarController.h
//  Mooshimeter
//
//  Created by James Whong on 9/18/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "mooshimeter_device.h"

@interface mooshimeterTabBarController : UITabBarController <UIAlertViewDelegate>

@property (strong, nonatomic) mooshimeter_device *meter;
@property (strong, nonatomic) UIAlertView *megaAlert;

-(void)setDevice:(mooshimeter_device*)device;

-(void)onDisconnect;

@end
