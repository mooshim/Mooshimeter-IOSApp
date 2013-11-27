//
//  mooshimeterTabBarController.m
//  Mooshimeter
//
//  Created by James Whong on 9/18/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "mooshimeterTabBarController.h"

@interface mooshimeterTabBarController ()

@end

@implementation mooshimeterTabBarController

- (void)setDevice:(mooshimeter_device*)device
{
    self.meter = device;
    [device registerDisconnectCB:self cb:@selector(onDisconnect) arg:nil];
    NSLog(@"I am in tab controller setDevice");
    for( UIViewController* c in self.viewControllers ) {
        if( [c respondsToSelector:@selector(setDevice:)] ) {
            [c performSelector:@selector(setDevice:) withObject:device];
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    int i = 0;
    NSString* tab_names[] = {@"Scan", @"Meter", @"Settings", @"Capture", @"Trend"};
    for( UIViewController* c in self.viewControllers ) {
        c.title = tab_names[i++];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onDisconnect
{
    NSLog(@"onDisconnect called in tab controller");
    [self setSelectedIndex:0];
}

@end
