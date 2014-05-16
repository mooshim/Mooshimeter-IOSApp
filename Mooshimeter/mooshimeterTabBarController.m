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
    [device registerDisconnectCB:self cb:@selector(onAccidentalDisconnect) arg:nil];
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

-(void)onDeliberateDisconnect
{
    NSLog(@"onDeliberateDisconnect called in tab controller");
    [self setSelectedIndex:0];
    // Hide the tab bar to stop navigation
    [self.tabBar setHidden:YES];
}

-(void)onAccidentalDisconnect
{
    NSLog(@"onAccidentalDisconnect called in tab controller");
    // Was the disconnect deliberate?
    [self invokeMegaAnnoyingPopup];
    
    [self.meter reconnect:self cb:@selector(settingsRestored:) arg:[NSNumber numberWithInteger:self.selectedIndex]];
    [self setSelectedIndex:0];
    // Hide the tab bar to stop navigation
    [self.tabBar setHidden:YES];
}

-(void)settingsRestored:(NSNumber*)i
{
    NSLog(@"Settings Restored, resuming");
    [self.meter registerDisconnectCB:self cb:@selector(onAccidentalDisconnect) arg:nil];
    [self dismissMegaAnnoyingPopup];
    [self setSelectedIndex:[i integerValue]];
    [self.tabBar setHidden:NO];
}

#pragma mark - AlertView delegate

-(void)invokeMegaAnnoyingPopup
{
    NSLog(@"Bring out the popup");
    self.megaAlert = [[[UIAlertView alloc] initWithTitle:nil
                                                 message:@"Connecting..." delegate:self cancelButtonTitle:@"Cancel"
                                       otherButtonTitles: nil] init];
    
    [self.megaAlert show];
}

-(void)dismissMegaAnnoyingPopup
{
    [self.megaAlert dismissWithClickedButtonIndex:0 animated:YES];
    self.megaAlert = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.meter disconnect];
    [self dismissMegaAnnoyingPopup];
}

@end
