//
//  mooshimeterAppDelegate.m
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self->reboot_into_oad = NO;
    
    [LGCentralManager sharedInstance];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    self.scan_vc = [[ScanViewController alloc] initWithDelegate:self];
    self.oad_vc  = [[BLETIOADProgressViewController alloc] init];
    
    self.nav = [[SmartNavigationController alloc] initWithRootViewController:self.scan_vc];
    self.nav.app = self;
    
    self.meter_vc = [[MeterViewController alloc] init];
    
    [self.window setRootViewController:self.nav];
    
    // Start scanning for meters
    [self scanForMeters];
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

#pragma mark - Random utility functions

-(AppDelegate*)getApp {
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

-(UINavigationController*)getNav {
    AppDelegate* t = [self getApp];
    return t.window.rootViewController.navigationController;
}

- (void)scanForMeters
{
    uint16 tmp = CFSwapInt16(OAD_SERVICE_UUID);
    LGCentralManager* c = [LGCentralManager sharedInstance];
    
    if(c.isScanning) {
        // Wait for the previous scan to finish.
        NSLog(@"Already scanning. Swipe ignored.");
        return;
    }
    
    NSArray* services = [NSArray arrayWithObjects:[BLEUtility expandToMooshimUUID:METER_SERVICE_UUID], [BLEUtility expandToMooshimUUID:OAD_SERVICE_UUID], [CBUUID UUIDWithData:[NSData dataWithBytes:&tmp length:2]], nil];
    NSLog(@"Refresh requested");
    
    [self.scan_vc.refreshControl beginRefreshing];
    
    NSTimer* refresh_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self.scan_vc selector:@selector(reloadData) userInfo:nil repeats:YES];
    
    [c scanForPeripheralsByInterval:5
        services:services
        options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
        completion:^(NSArray *peripherals) {
            NSLog(@"Found: %d", peripherals.count);
            [refresh_timer invalidate];
            [self.scan_vc.refreshControl endRefreshing];
            [self.scan_vc reloadData];
    }];
}

-(BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"Signal change to graph here");
}

#pragma mark ScanViewDelegate

-(void)handleScanViewRefreshRequest {
    [self scanForMeters];
}

-(void)handleScanViewSelect:(LGPeripheral*)p {
    switch( p.cbPeripheral.state ) {
        case CBPeripheralStateConnected:{
            // We selected one that's already connected, disconnect
            [p disconnectWithCompletion:^(NSError *error) {
                [self.scan_vc reloadData];
            }];
            break;}
        case CBPeripheralStateConnecting:{
            //What should we do if you click a connecting meter?
            NSLog(@"Already connecting...");
            break;}
        case CBPeripheralStateDisconnected:{
            NSLog(@"Connecting new...");
            g_meter = [[MooshimeterDevice alloc] init:p delegate:self];
            [g_meter connect];
            [self.scan_vc reloadData];
            break;}
    }
}

#pragma mark MooshimeterDeviceDelegate

-(void)finishedMeterSetup {
    NSLog(@"Finished meter setup");
    [self.scan_vc reloadData];
    if( g_meter->oad_mode ) {
        // We connected to a meter in OAD mode as requested previously.  Update firmware.
        NSLog(@"Connected in OAD mode");
#ifdef AUTO_UPDATE_FIRMWARE
        if(self.nav.topViewController != self.oad_vc) {
            self.oad_profile = [[BLETIOADProfile alloc]init];
            self.oad_profile.progressView = [[BLETIOADProgressViewController alloc]init];
            [self.oad_profile makeConfigurationForProfile];
            self.oad_profile.navCtrl = self.nav;
            [self.oad_profile configureProfile];
            self.oad_profile.view = self.nav.topViewController.view;
            [self.oad_profile selectImagePressed:self];
        }
#endif
    }
    else if( g_meter->meter_info.build_time < 1415389647 ) {
#ifdef AUTO_UPDATE_FIRMWARE
        // Require a firmware update!
        NSLog(@"FIRMWARE UPDATE REQUIRED.  Rebooting.");
        self->reboot_into_oad = YES;
        // This will reboot the meter.  We will have 5 seconds to reconnect to it in OAD mode.
        [g_meter setMeterState:METER_SHUTDOWN cb:^(NSError *error) {
            [g_meter.p disconnectWithCompletion:^(NSError *error) {
                [g_meter connect];
            }];
        }];
#endif
    } else {
        // We have a connected meter with the correct firmware.
        // Display the meter view.
        NSLog(@"Pushing meter view controller");
        [self.nav pushViewController:self.meter_vc animated:YES];
        NSLog(@"Did push meter view controller");
    }
}


-(void)meterSetupComplete:(MooshimeterDevice*)d {
    NSLog(@"Setup complete");
    }



@end
