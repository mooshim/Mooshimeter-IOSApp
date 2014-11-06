//
//  mooshimeterMasterViewController.m
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "mooshimeterScanViewController.h"

#import "mooshimeterMeterViewController.h"

@interface mooshimeterScanViewController () {
    NSMutableArray *_objects;
}
@end

@implementation mooshimeterScanViewController

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
    [self.app scanForMeters];
}

-(void)reloadData {
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.app = (mooshimeterAppDelegate*)[UIApplication sharedApplication].delegate;

    [self.tableView registerClass:[ScanTableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    NSLog(@"Creating refresh handler...");
    UIRefreshControl *rescan_control = [[UIRefreshControl alloc] init];
    [rescan_control addTarget:self action:@selector(handleSwipe) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rescan_control;
}

-(void)viewDidAppear:(BOOL)animated
{
    
}

-(void)endRefresh {
    [self.refreshControl endRefreshing];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.app.meters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral *p = [self.app.meters objectAtIndex:indexPath.row];
    NSNumber* RSSI = [self.app.meter_rssi objectAtIndex:indexPath.row];
    
    ScanTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    [cell setPeripheral:p];
    [cell setRSSI:RSSI];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {return NO;}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"You clicked a meter");
    CBPeripheral *peripheral = self.app.meters[indexPath.row];
    [self.app selectPeripheral:peripheral];
}

@end
