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
    
    self.scan_vc    = [[ScanViewController alloc] initWithDelegate:self];
    self.meter_vc = [[MeterViewController alloc] initWithDelegate:self];
    self.oad_vc     = [[BLETIOADProgressViewController alloc] init];
    self.scatter_vc = [[GraphViewController alloc] initWithDelegate:self];
    
    self.nav = [[SmartNavigationController alloc] initWithRootViewController:self.scan_vc];
    self.nav.app = self;
    
    self.oad_profile = [[OADProfile alloc]init];
    self.oad_profile.progressView = [[BLETIOADProgressViewController alloc]init];
    self.oad_profile.navCtrl = self.nav;
    
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

-(UINavigationController*)getNav {
    return self.window.rootViewController.navigationController;
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
    
    //self.scan_vc.title = @"Scan in progress...";
    self.nav.navigationItem.title = @"Scan in progress...";
    
    [c scanForPeripheralsByInterval:5
        services:services
        options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
        completion:^(NSArray *peripherals) {
            NSLog(@"Found: %d", peripherals.count);
            [refresh_timer invalidate];
            [self.scan_vc.refreshControl endRefreshing];
            [self.scan_vc reloadData];
            self.nav.navigationItem.title = @"Pull down to scan";
    }];
}

-(BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
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
            [p disconnectWithCompletion:^(NSError *error) {
                [self.scan_vc reloadData];
            }];
            break;}
        case CBPeripheralStateDisconnected:{
            NSLog(@"Connecting new...");
            g_meter = [[MooshimeterDevice alloc] init:p delegate:self];
            [g_meter connect];
            [self.scan_vc reloadData];
            break;}
    }
}

#pragma mark MeterViewControllerDelegate

-(void)handleMeterViewRotation {
    // We are here because the meter view rotated to horizontal.
    // Load the scatter view and push it.
    // TODO: Need to wait for the present orientation to change somehow...
    self.nav.navigationBar.hidden = YES;
    [self.nav pushViewController:self.scatter_vc animated:YES];
}

#pragma mark ScatterViewControllerDelegate

-(void)handleScatterViewRotation {
    // We are here because the meter view rotated to vertical.
    // Load the meter view and push it.
    self.nav.navigationBar.hidden = NO;
    [self.nav popToViewController:self.meter_vc animated:YES];
}

#pragma mark MooshimeterDeviceDelegate

-(void)finishedMeterSetup {
    NSLog(@"Finished meter setup");
    [self.scan_vc reloadData];
    if( g_meter->oad_mode ) {
        // We connected to a meter in OAD mode as requested previously.  Update firmware.
        NSLog(@"Connected in OAD mode");
#ifdef AUTO_UPDATE_FIRMWARE
        NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
        [path appendString:@"/"] ;
        [path appendString:@"Mooshimeter.bin"];
        
        [self.oad_profile startUpload:path];
#endif
    }
    else if( g_meter->meter_info.build_time < 1416285788 ) {
#ifdef AUTO_UPDATE_FIRMWARE
        // Require a firmware update!
        NSLog(@"FIRMWARE UPDATE REQUIRED.  Rebooting.");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware Update" message:@"This meter requires a firmware update.  This will take about a minute.  Upgrade now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upgrade Now", nil];
        [alert show];
#endif
    } else {
        // We have a connected meter with the correct firmware.
        // Display the meter view.
        NSLog(@"Pushing meter view controller");
        [self.nav pushViewController:self.meter_vc animated:YES];
        NSLog(@"Did push meter view controller");
    }
}

-(void)meterDisconnected {
    [self.nav popToViewController:self.scan_vc animated:YES];
    [self.scan_vc reloadData];
}

#pragma mark UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    DLog(@"in alert view delegate");
    if(buttonIndex == 0) {
        [g_meter.p disconnectWithCompletion:^(NSError *error) {
            [self.scan_vc reloadData];
        }];
    } else {
        self->reboot_into_oad = YES;
        // This will reboot the meter.  We will have 5 seconds to reconnect to it in OAD mode.
        [g_meter setMeterState:METER_SHUTDOWN cb:^(NSError *error) {
            [g_meter.p disconnectWithCompletion:^(NSError *error) {
                DLog(@"Reconnecting...");
                [g_meter connect];
            }];
        }];
    }
}

@end
