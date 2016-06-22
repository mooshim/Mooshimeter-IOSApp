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

#import "ScanVC.h"
#import "MeterVC.h"
#import "OADDevice.h"
#import "SmartNavigationController.h"
#import "GlobalPreferenceVC.h"
#import "WidgetFactory.h"
#import "FirmwareImageDownloader.h"

@implementation ScanVC

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)scan
{
    uint16 tmp = CFSwapInt16(OAD_SERVICE_UUID);
    LGCentralManager* c = [LGCentralManager sharedInstance];

    if(c.isScanning) {
        // Wait for the previous scan to finish.
        NSLog(@"Already scanning. Swipe ignored.");
        return;
    }

    NSArray* services = @[
            [BLEUtility expandToMooshimUUID:METER_SERVICE_UUID],
            [BLEUtility expandToMooshimUUID:OAD_SERVICE_UUID],
            [CBUUID UUIDWithData:[NSData dataWithBytes:&tmp length:2]]];
    NSLog(@"Refresh requested");

    NSTimer* refresh_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reloadData) userInfo:nil repeats:YES];

    NSTimer *dot_timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:[NSBlockOperation blockOperationWithBlock:^{
                                                          static int i = 0;
                                                          NSMutableString* title = [NSMutableString stringWithString:@"Scanning."];
                                                          for(int j=0; j<i; j++) {
                                                              [title appendString:@"."];
                                                          }
                                                          for(int j=0; j<3-i; j++) {
                                                              [title appendString:@" "];
                                                          }
                                                          i++;
                                                          i%=3;
                                                          [self.scanButton setTitle:title forState:UIControlStateNormal];
                                                      }]
                                                    selector:@selector(main)
                                                    userInfo:nil
                                                     repeats:YES];

    [c scanForPeripheralsByInterval:5
                           services:services
                            options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
                         completion:^(NSArray *peripherals) {
                             NSLog(@"Found: %d", (int)peripherals.count);
                             [refresh_timer invalidate];
                             [dot_timer invalidate];
                             [self reloadData];
                             [self.scanButton setTitle:@"Start Scan" forState:UIControlStateNormal];
                         }];
}

-(void)reloadData {
    LGCentralManager* c = [LGCentralManager sharedInstance];
    self.peripherals = [c.peripherals copy];
    [self.tableView reloadData];
    if(self.peripherals.count==0) {
        [self setTitle:@"No meters Found"];
    } else if (self.peripherals.count==1){
        [self setTitle:@"Found 1 meter"];
    } else {
        [self setTitle:[NSString stringWithFormat:@"Found %d meters",self.peripherals.count]];
    }
}

-(void)handleScanViewRefreshRequest {
    [self scan];
}

void discoverRecursively(NSArray* services,uint32 i, LGPeripheralDiscoverServicesCallback aCallback) {
    LGService * service = services[i];
    i++;
    if(i == [services count]) {
        [service discoverCharacteristicsWithCompletion:aCallback];
    } else {
        [service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
            discoverRecursively(services, i, aCallback);
        }];
    }

}

-(void)handleScanViewSelect:(LGPeripheral*)p {
    switch( p.cbPeripheral.state ) {
        case CBPeripheralStateConnected:{
            // We selected one that's already connected, disconnect
            [p disconnectWithCompletion:^(NSError *error) {
                [self reloadData];
            }];
            break;}
        case CBPeripheralStateConnecting:{
            //What should we do if you click a connecting meter?
            NSLog(@"Already connecting...");
            [p disconnectWithCompletion:^(NSError *error) {
                [self reloadData];
            }];
            break;}
        case CBPeripheralStateDisconnecting:
        case CBPeripheralStateDisconnected:{
            NSLog(@"Connecting new...");
            [self wrapPeripheralInMooshimeterAndTransition:p];
            [self reloadData];
            break;}
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.nrow = 8;
    self.ncol = 1;

    self.scanButton = [self makeButton:[self makeRectInGrid:0 row_off:7 width:1 height:1] cb:@selector(handleScanViewRefreshRequest)];
    [self.scanButton setTitle:@"Start Scan" forState:UIControlStateNormal];

    self.tableView  = [[UITableView alloc] initWithFrame:[self makeRectInGrid:0 row_off:0 width:1 height:7]];
    [self.content_view addSubview:self.tableView];

    [self.tableView registerClass:[ScanTableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];

    self.active_meter = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Start a new scan for meters
    [self handleScanViewRefreshRequest];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setTitle:@"Scan"];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(void)populateNavBar {
    // Called from base class, overridden to give custom navbar behavior

    // Add settings button to navbar
    UIButton* b = [WidgetFactory makeButton:@"\u2699" callback:^{
        SmartNavigationController * gnav = [SmartNavigationController getSharedInstance];
        GlobalPreferenceVC * vc = [[GlobalPreferenceVC alloc] init];
        [gnav pushViewController:vc animated:YES];
    }];
    [b setFrame:CGRectMake(0,0,35,35)];
    [self addToNavBar:b];
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.peripherals.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* reuse_id = @"Cell";
    LGPeripheral* p;
    if(indexPath.row >= self.peripherals.count) {
        p = nil;
    } else {
        p = [self.peripherals objectAtIndex:indexPath.row];
    }
    
    ScanTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse_id forIndexPath:indexPath];

    if(cell == nil) {
        cell = [[ScanTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuse_id];
    }

    [cell setPeripheral:p];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {return NO;}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScanTableViewCell* c = [self.tableView cellForRowAtIndexPath:indexPath];
    [self handleScanViewSelect:c.peripheral];
}

-(void)transitionToMeterView:(MooshimeterDeviceBase*)meter {
    // We have a connected meter with the correct firmware.
    // Display the meter view.
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(meterDisconnected)
                                                 name:kLGPeripheralDidDisconnect
                                               object:nil];*/
    NSLog(@"Pushing meter view controller");
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    SmartNavigationController * nav = [SmartNavigationController getSharedInstance];
    MeterVC * mvc = [[MeterVC alloc] initWithMeter:meter];
    [nav pushViewController:mvc animated:YES];
    NSLog(@"Did push meter view controller");
}

-(void)transitionToOADView:(MooshimeterDeviceBase*)meter {
    NSLog(@"Pushing OAD view controller");
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    SmartNavigationController * nav = [SmartNavigationController getSharedInstance];
    OADViewController * mvc = [[OADViewController alloc] initWithMeter:meter];
    [nav pushViewController:mvc animated:YES];
    NSLog(@"Did push OAD view controller");
}

/*-(void)handlePeripheralConnected:(LGPeripheral*)p{
    [self reloadData];
    NSLog(@"Wrapping in Meter");

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
        NSLog(@"FIRMWARE OLD");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware Update" message:@"A new firmware version is available.  Upgrade now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upgrade Now", nil];
        [alert show];
    } else {
        [self transitionToMeterView];
    }
}*/

-(void)wrapPeripheralInMooshimeterAndTransition:(LGPeripheral*)p {
    [p connectWithTimeout:5 completion:^(NSError *error) {
        NSLog(@"Discovering services");
        [p discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
            discoverRecursively(services,0,^(NSArray *characteristics, NSError *error) {
                Class meter_class = [MooshimeterDeviceBase chooseSubClass:p];
                // We need to split alloc and init here because of some confusing callback issues
                // that might reference self.active_meter
                self.active_meter = [meter_class alloc];
                [self.active_meter init:p delegate:self];
                NSLog(@"Wrapped in meter!");
            });
        }];
    }];
}

-(void)chooseAndStartActivityFor:(MooshimeterDeviceBase*)device {
    if([device isKindOfClass:OADDevice.class]) {
        // Start OAD activity
        [self transitionToOADView:device];
    } else {
        // If the connected meter has an old version of fw
        if([MooshimeterDeviceBase getBuildTimeFromPeripheral:_active_meter.periph] < [FirmwareImageDownloader getBuildTime]
                && ![self.active_meter getPreference:@"SKIP_UPGRADE" def:NO]) {
            // We should offer to upgrade
            [WidgetFactory makeCancelContinueAlert:@"Firmware upgrade available" msg:@"This Mooshimeter's firmware is out of date.  Upgrade now?" callback:^(bool proceed) {
                if(proceed) {
                    // Now we need to disconnect and reconnect to the meter needing upgrade
                    [self forceReconnectInOADMode:_active_meter];
                } else {
                    [self transitionToMeterView:device];
                }
            }];
        } else {
            //Firmware is up to date, just start
            [self transitionToMeterView:device];
        }
    }
}

-(void)forceReconnectInOADMode:(MooshimeterDeviceBase*)m {
    // We're going to force the meter to disconnect, then reconnect real quick
    [m.periph registerDisconnectHandler:^(NSError *error) {
        [self wrapPeripheralInMooshimeterAndTransition:m.periph];
    }];
    [m reboot];
}

#pragma mark MooshimeterDelegateProtocol methods
- (void)onInit {
    [self chooseAndStartActivityFor:self.active_meter];
}
-(void)onRssiReceived:(int)rssi {
    //We should really do something with this but I designed the MooshimeterDeviceDelegate protocol poorly;
}
-(void)onBatteryVoltageReceived:(float)voltage {
    //We should really do something with this but I designed the MooshimeterDeviceDelegate protocol poorly
}
@end
