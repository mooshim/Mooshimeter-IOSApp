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
    self.graph_vc = [[GraphViewController alloc] initWithDelegate:self];
    
    self.nav = [[SmartNavigationController alloc] initWithRootViewController:self.scan_vc];
    self.nav.app = self;
    CGRect nav_size = self.nav.navigationBar.bounds;
    int w = nav_size.size.width/4;
    
    nav_size.origin.x   = 2*w;
    nav_size.size.width = w;
    self.bat_label = [[UILabel alloc]initWithFrame:nav_size];
    [self.nav.navigationBar addSubview:self.bat_label];
    [self.bat_label setText:@""];
    
    nav_size.origin.x   = 1*w;
    nav_size.size.width = w;
    self.rssi_label = [[UILabel alloc]initWithFrame:nav_size];
    [self.nav.navigationBar addSubview:self.rssi_label];
    [self.rssi_label setText:@""];
    
    nav_size.origin.x   = 3*w;
    nav_size.size.width = w;
    // Fake some padding
    nav_size.origin.x    += 5;
    nav_size.origin.y    += 5;
    nav_size.size.width  -= 10;
    nav_size.size.height -= 10;
    
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.userInteractionEnabled = YES;
    [b addTarget:self action:@selector(settings_button_press) forControlEvents:UIControlEventTouchUpInside];
    [b.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [b setTitle:@"\u2699" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[b layer] setBorderWidth:2];
    [[b layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    b.frame = nav_size;
    self.settings_button = b;
    [self.nav.navigationBar addSubview:self.settings_button];
    
    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
    [path appendString:@"/Mooshimeter.bin"];
    self.oad_profile = [[OADProfile alloc]init:path];
    self.oad_profile.progressView = [[BLETIOADProgressViewController alloc]init];
    self.oad_profile.navCtrl = self.nav;
    
    [self.window setRootViewController:self.nav];
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

-(void)settings_button_press {
    NSLog(@"Main app settings button press");
    [self.nav.topViewController performSelector:@selector(settings_button_press)];
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
            NSLog(@"Found: %d", (int)peripherals.count);
            [refresh_timer invalidate];
            [self.scan_vc.refreshControl endRefreshing];
            [self.scan_vc reloadData];
            self.nav.navigationItem.title = @"Pull down to scan";
    }];
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
                [self meterDisconnected];
            }];
            break;}
        case CBPeripheralStateConnecting:{
            //What should we do if you click a connecting meter?
            NSLog(@"Already connecting...");
            [p disconnectWithCompletion:^(NSError *error) {
                [self meterDisconnected];
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

-(void)switchToGraphView {
    // We are here because the meter view rotated to horizontal.
    // Load the scatter view and push it.
    if( [self.nav topViewController] != self.graph_vc ) {
        self.nav.navigationBar.hidden = YES;
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
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

#pragma mark MooshimeterDeviceDelegate

-(void)finishedMeterSetup {
    NSLog(@"Finished meter setup");
    [self.scan_vc reloadData];
    if( g_meter->oad_mode ) {
        // We connected to a meter in OAD mode as requested previously.  Update firmware.
        NSLog(@"Connected in OAD mode");
        if( YES || [g_meter getAdvertisedBuildTime] != self.oad_profile->imageHeader.build_time ) {
            NSLog(@"Starting upload");
            [self.oad_profile startUpload];
        } else {
            NSLog(@"We connected to an up-to-date meter in OAD mode.  Disconnecting.");
            [g_meter.p disconnectWithCompletion:nil];
        }
    }
    else if( [g_meter getAdvertisedBuildTime] < self.oad_profile->imageHeader.build_time ) {
        // Require a firmware update!
        NSLog(@"FIRMWARE UPDATE REQUIRED.");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware Update" message:@"This meter requires a firmware update.  This will take about a minute.  Upgrade now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upgrade Now", nil];
        [alert show];
    } else {
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
}

-(void)meterDisconnected {
    // Allow screen dimming again
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.bat_label setText:@""];
    [self.rssi_label setText:@""];
    [NSTimer cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateRSSI) object:nil];
    [self.nav popToViewController:self.scan_vc animated:YES];
    [self.scan_vc reloadData];
    g_meter = nil;
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

// Estimate the state of charge of an alkaline battery
+(double)alkSocEstimate:(double)cell_voltage {
    // CC2540 browns out at 2V, so let's just call 1V cell voltage 0% charge.
    // 1.5V will be 100%.  Just make it linear.
    double t = cell_voltage-1.0;
    t*=2;
    t = MIN(1.0,t);
    t = MAX(0.0,t);
    return t;
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
