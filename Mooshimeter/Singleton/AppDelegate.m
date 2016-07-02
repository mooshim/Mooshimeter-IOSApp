/**************************
Mooshimeter iOS App - interface to Mooshimeter wireless multimeter
Copyright (C) 2015  James Whong

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************/

#import "AppDelegate.h"
#import "FirmwareImageDownloader.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Fabric with:@[[Crashlytics class]]];
    
    // Init singletons
    // FIXME all 3 have different initialization patterns?  Seriously?
    [LGCentralManager sharedInstance];
    [FirmwareImageDownloader initSingleton];
    (void)[[SmartNavigationController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];

    [self.window setRootViewController:[SmartNavigationController getSharedInstance]];
    [self.window makeKeyAndVisible];

    self.scan_vc    = [[ScanVC alloc] init];
    [[SmartNavigationController getSharedInstance] setViewControllers:@[self.scan_vc] animated:NO];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
#pragma mark MeterViewControllerDelegate

-(void)switchToGraphView:(UIDeviceOrientation)new_o {
    // We are here because the meter view rotated to horizontal.
    // Load the scatter view and push it.
    if( [self.nav topViewController] != self.graph_vc ) {
        self.nav.navigationBar.hidden = YES;
        NSNumber *value = [NSNumber numberWithInt:new_o];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        [self.nav pushViewController:self.graph_vc animated:YES];
    }
}

#pragma mark ScatterViewControllerDelegate

-(void)switchToMeterView {
    // We are here because the meter view rotated to vertical.
    // Load the meter view and push it.
    if( [self.nav topViewController] != self.meter_vc ) {
        self.nav.navigationBar.hidden = NO;
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        [self.nav popToViewController:self.meter_vc animated:YES];
    }
}

-(void)transitionToMeterView {
    // We have a connected meter with the correct firmware.
    // Display the meter view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(meterDisconnected)
                                                 name:kLGPeripheralDidDisconnect
                                               object:nil];
    const double bat_pcnt = 100*[AppDelegate alkSocEstimate:(g_meter->bat_voltage/2)];
    NSString* bat_str = [NSString stringWithFormat:@"Bat:%d%%", (int)bat_pcnt];
    [self.bat_label setText:bat_str];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateRSSI) userInfo:nil repeats:NO];
    NSLog(@"Pushing meter view controller");
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self.nav pushViewController:self.meter_vc animated:YES];
    NSLog(@"Did push meter view controller");
}

-(void)updateRSSI {
    if(!g_meter) return;
    [g_meter.p readRSSIValueCompletion:^(NSNumber *RSSI, NSError *error) {
        if(RSSI) {
            NSString* rssi_str = [NSString stringWithFormat:@"Sig:%@dB", RSSI];
            [self.rssi_label setText:rssi_str];
        } else {
            [self.rssi_label setText:@""];
        }
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateRSSI) userInfo:nil repeats:NO];
    }];
}

#pragma mark UIAlertViewDelegate

// This delegate responds to the firmware update dialog
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    DLog(@"in alert view delegate");
    if(buttonIndex == 0) {
        // Cancel was pressed, just try to read the meter and hope for the best
        [self transitionToMeterView];
    } else {
        self->reboot_into_oad = YES;
        // Cancel any disconnect handling
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        // This will reboot the meter.  We will have 5 seconds to reconnect to it in OAD mode.
        [g_meter setMeterState:METER_SHUTDOWN cb:^(NSError *error) {
            [g_meter.p disconnectWithCompletion:^(NSError *error) {
                DLog(@"Reconnecting...");
                [g_meter connect];
            }];
        }];
    }
}*/

@end
