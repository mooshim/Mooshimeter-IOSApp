//
//  mooshimeterMasterViewController.m
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "mooshimeterMasterViewController.h"

#import "mooshimeterDetailViewController.h"

@interface mooshimeterMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation mooshimeterMasterViewController
@synthesize ble_master, n_meters, meters;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)handleSwipe
{
    NSLog(@"Refresh requested");
    self.meter.manager.delegate = self;
    [self.ble_master stopScan];
    [self.meters removeAllObjects];
    if( self.meter.p.isConnected )
        [self.meters addObject:self.meter.p];
    [self.ble_master scanForPeripheralsWithServices:nil options:nil];
    [self.tableView reloadData];
    [self performSelector:@selector(endScan) withObject:nil afterDelay:10.f];
}

-(void) endScan {
    [self.ble_master stopScan];
    self.meter.manager.delegate = self.meter;
    [self.refreshControl endRefreshing];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"Initializing CBMaster...");
    // Custom initialization
    self.ble_master = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.n_meters = [[NSMutableArray alloc]init];
    self.meters = [[NSMutableArray alloc]init];
    self.meter_rssi = [[NSMutableDictionary alloc] init];
    
    NSLog(@"Creating refresh handler...");
    UIRefreshControl *rescan_control = [[UIRefreshControl alloc] init];
    [rescan_control addTarget:self action:@selector(handleSwipe) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rescan_control;
    
    NSLog(@"Setting CBManager Delegate");
    self.ble_master.delegate = self;
    
    self.detailViewController = (mooshimeterDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    //self.meter.manager.delegate = self;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.meters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    CBPeripheral *p = [self.meters objectAtIndex:indexPath.row];
    
    [p readRSSI];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",p.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"RSSI: %d dB", [p.RSSI integerValue]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if( p.UUID == self.meter.p.UUID ) {
        cell.contentView.backgroundColor = [UIColor cyanColor];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"BLE not supported !" message:[NSString stringWithFormat:@"CoreBluetooth return state: %d",central.state] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    else {
        NSLog(@"CBCentralManager scanning!");
        [central scanForPeripheralsWithServices:nil options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Found a BLE Device : %@",peripheral);
    
    /* iOS 6.0 bug workaround : connect to device before displaying UUID !
     The reason for this is that the CFUUID .UUID property of CBPeripheral
     here is null the first time an unknown (never connected before in any app)
     peripheral is connected. So therefore we connect to all peripherals we find.
     */
    NSLog(@"RSSI: %d", [RSSI integerValue]);
    
    BOOL replace = NO;
    BOOL found = NO;
    for (CBService *s in peripheral.services) {
        NSLog(@"Service found : %@",s.UUID);
        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"ffa0"]])  {
            NSLog(@"This is a Mooshimeter !");
            found = YES;
        }
    }
    if (found) {
        // Match if we have this device from before
        for (int ii=0; ii < self.meters.count; ii++) {
            CBPeripheral *p = [self.meters objectAtIndex:ii];
            if ([p isEqual:peripheral]) {
                [self.meters replaceObjectAtIndex:ii withObject:peripheral];
                replace = YES;
            }
        }
        if (!replace) {
            [self.meters addObject:peripheral];
            [self.tableView reloadData];
        }
    } else {
        peripheral.delegate = self;
        [central connectPeripheral:peripheral options:nil];
    }
    
    [self.n_meters addObject:peripheral];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [peripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
}

#pragma  mark - CBPeripheral delegate

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    BOOL replace = NO;
    BOOL found = NO;
    NSLog(@"Services scanned !");
    [self.ble_master cancelPeripheralConnection:peripheral];
    for (CBService *s in peripheral.services) {
        NSLog(@"Service found : %@",s.UUID);
        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"ffa0"]])  {
            NSLog(@"This is a Mooshimeter !");
            found = YES;
        }
    }
    if (found) {
        // Match if we have this device from before
        for (int ii=0; ii < self.meters.count; ii++) {
            CBPeripheral *p = [self.meters objectAtIndex:ii];
            if ([p isEqual:peripheral]) {
                [self.meters replaceObjectAtIndex:ii withObject:peripheral];
                replace = YES;
            }
        }
        if (!replace) {
            [self.meters addObject:peripheral];
            [self.tableView reloadData];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ error = %@",characteristic,error);
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic,error);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"You clicked a meter");
    CBPeripheral *peripheral = self.meters[indexPath.row];
    //mooshimeterTabBarController* tc = (mooshimeterTabBarController*)self.tabBarController;
    
    if( self.meter != nil ) {
        if( self.meter.p.UUID == peripheral.UUID && self.meter.p.isConnected ) {
            // Do nothing
            NSLog(@"Disconnecting");
            //[tc setSelectedIndex:1];
            [self.meter disconnect:nil cb:nil arg:nil];
            return;
        }
        NSLog(@"Disconnecting old...");
        [self.meter disconnect:nil cb:nil arg:nil];
    }
    
    [self invokeMegaAnnoyingPopup];
    
    self.meter = [[mooshimeter_device alloc] init:self.ble_master periph:peripheral];
    
    self.meter.p.delegate = self.meter;
    self.meter.manager.delegate = self.meter;
    
    [self.meter setup:self cb:@selector(meterSetupSuccessful) arg:nil];
}

-(void)meterSetupSuccessful {
    mooshimeterTabBarController* tc = (mooshimeterTabBarController*)self.tabBarController;
    [self dismissMegaAnnoyingPopup];
    [tc setDevice:self.meter];
    [tc setSelectedIndex:1];
}

-(void)meterSetupCancelled {
    [self dismissMegaAnnoyingPopup];
    [self.meter disconnect:nil cb:nil arg:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

}

#pragma mark - AlertView delegate

-(void)invokeMegaAnnoyingPopup
{
    NSLog(@"Bring out the popup");
    self.megaAlert = [[[UIAlertView alloc] initWithTitle:nil
                                                 message:@"Connecting..." delegate:self cancelButtonTitle:@"Cancel"
                                       otherButtonTitles: nil] init];
    
    [self.megaAlert show];
    
    //UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]
    //                                      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    //indicator.center = CGPointMake(self.megaAlert.bounds.size.width / 2,
    //                               self.megaAlert.bounds.size.height);
    //[indicator startAnimating];
    //[self.megaAlert addSubview:indicator];
}

-(void)dismissMegaAnnoyingPopup
{
    [self.megaAlert dismissWithClickedButtonIndex:0 animated:YES];
    self.megaAlert = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.meter disconnect:nil cb:nil arg:nil];
    [self dismissMegaAnnoyingPopup];
}

@end
