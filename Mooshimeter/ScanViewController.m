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

#import "ScanViewController.h"
#import "meterViewController.h"

// Uncomment if you want a simulated meter to appear in the scan list
#define SIMULATED_METER

@interface ScanViewController () {
    NSMutableArray *_objects;
}
@end

@implementation ScanViewController

-(instancetype)initWithDelegate:(id)d {
    self=[super init];
    self.delegate = d;
    self.peripherals = nil;
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)reloadData {
    NSLog(@"Reload requested");
    LGCentralManager* c = [LGCentralManager sharedInstance];
    self.peripherals = [c.peripherals copy];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[ScanTableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    NSLog(@"Creating refresh handler...");
    UIRefreshControl *rescan_control = [[UIRefreshControl alloc] init];
    [rescan_control addTarget:self.delegate action:@selector(handleScanViewRefreshRequest) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rescan_control;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self setTitle:@"Swipe down to scan"];
    if(g_meter) {
        // If we've appeared, disconnect whatever we were talking to.
        [g_meter disconnect:nil];
    }
    // Start a new scan for meters
    [self.delegate handleScanViewRefreshRequest];
}

-(BOOL)shouldAutorotate { return NO; }

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(void)settings_button_press {
    if(!self.settings_view) {
        CGRect frame = self.view.frame;
        frame.origin.x += .05*frame.size.width;
        frame.origin.y += (frame.size.height - 250)/2;
        frame.size.width  *= 0.9;
        frame.size.height =  250;
        ScanSettingsView* g = [[ScanSettingsView alloc] initWithFrame:frame];
        [g setBackgroundColor:[UIColor whiteColor]];
        [g setAlpha:0.9];
        self.settings_view = g;
    }
    if([self.view.subviews containsObject:self.settings_view]) {
        [self.settings_view removeFromSuperview];
    } else {
        [self.view addSubview:self.settings_view];
    }
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"RowCount");
#ifdef SIMULATED_METER
    return self.peripherals.count+1;
#else
    return self.peripherals.count;
#endif
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LGPeripheral* p;
    NSLog(@"Cell %d",(int)indexPath.row);
    if(indexPath.row >= self.peripherals.count) {
        p = nil;
    } else {
        p = [self.peripherals objectAtIndex:indexPath.row];
    }
    
    ScanTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    [cell setPeripheral:p];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {return NO;}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"You clicked a meter");
    ScanTableViewCell* c = (ScanTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    [self.delegate handleScanViewSelect:c.p];
}

@end
