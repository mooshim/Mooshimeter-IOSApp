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
@synthesize ble_master, meters, openingMessage1, openingMessage2, meter_rssi;

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
    NSArray* services = [NSArray arrayWithObject:[CBUUID UUIDWithString:(@"FFA0")]];
    
    NSLog(@"Refresh requested");
    self.meter.manager.delegate = self;
    [self.ble_master stopScan];
    [self.meters removeAllObjects];
    [self.meter_rssi removeAllObjects];
    if( self.meter.p.isConnected ) {
        [self.meters addObject:self.meter.p];
        [self.meter.p readRSSI];
        [self.meter_rssi addObject:self.meter.p.RSSI];
    }
    [self.ble_master scanForPeripheralsWithServices:services options:nil];
    [self.tableView reloadData];
    [self performSelector:@selector(endScan) withObject:nil afterDelay:10.f];
    [self.openingMessage1 setText:@"Scanning..."];
}

-(void) endScan {
    [self.ble_master stopScan];
    self.meter.manager.delegate = self.meter;
    [self.refreshControl endRefreshing];
    [self.openingMessage1 setText:@"Pull down to scan"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"Initializing CBMaster...");
    // Custom initialization
    self.ble_master = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.meters = [[NSMutableArray alloc]init];
    self.meter_rssi = [[NSMutableArray alloc] init];
    [self.tabBarController.tabBar setHidden:YES];
    
    NSLog(@"Creating refresh handler...");
    UIRefreshControl *rescan_control = [[UIRefreshControl alloc] init];
    [rescan_control addTarget:self action:@selector(handleSwipe) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rescan_control;
    
    NSLog(@"Setting CBManager Delegate");
    self.ble_master.delegate = self;
    
    self.openingMessage1 = [[UILabel alloc] initWithFrame:CGRectMake(60, 310, 200, 34)];
    [self.openingMessage1 setText:@"Scanning..."];
    self.openingMessage1.backgroundColor = [UIColor clearColor];
    self.openingMessage1.textColor = [UIColor darkGrayColor];
    self.openingMessage1.font = [UIFont boldSystemFontOfSize:24];
    self.openingMessage1.font = [UIFont fontWithName:@"Arial" size:24];
    [self.view addSubview:self.openingMessage1];
    
    [self performSelector:@selector(endScan) withObject:nil afterDelay:10.f];
    
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
    NSNumber* RSSI = [self.meter_rssi objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",p.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"RSSI: %d dB", [RSSI integerValue]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {return NO;}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"BLE not supported !" message:[NSString stringWithFormat:@"CoreBluetooth return state: %d",central.state] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    else {
        NSLog(@"CBCentralManager scanning!");
        [self handleSwipe];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Found a BLE Device : %@",peripheral);

    NSLog(@"RSSI: %d", [RSSI integerValue]);
    
    
    BOOL replace = NO;
    

    // Match if we have this device from before
    for (int ii=0; ii < self.meters.count; ii++) {
        CBPeripheral *p = [self.meters objectAtIndex:ii];
        if ([p isEqual:peripheral]) {
            [self.meters replaceObjectAtIndex:ii withObject:peripheral];
            [self.meter_rssi replaceObjectAtIndex:ii withObject:RSSI];
            replace = YES;
        }
    }
    if (!replace) {
        [self.meters addObject:peripheral];
        [self.meter_rssi addObject:RSSI];
        [self.tableView reloadData];
    }

    //[central connectPeripheral:peripheral options:nil];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    //[peripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
}

#pragma  mark - CBPeripheral delegate

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
    
    if( self.meter != nil ) {
        if( self.meter.p.UUID == peripheral.UUID && self.meter.p.isConnected ) {
            NSLog(@"Disconnecting");
            [self.meter disconnect];
            return;
        }
        NSLog(@"Disconnecting old...");
        [self.meter disconnect];
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
    [self.tabBarController.tabBar setHidden:NO];
    [tc setSelectedIndex:1];
}

-(void)meterSetupCancelled {
    [self dismissMegaAnnoyingPopup];
    [self.meter disconnect];
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
