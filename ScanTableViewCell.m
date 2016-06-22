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

#import "ScanTableViewCell.h"
#import "WidgetFactory.h"

@implementation ScanTableViewCell

#pragma mark lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    CGRect f = self.frame;
    f.size.height = 100;
    self.frame = f;

    self.meter_name = [[UILabel alloc] init];
    [self.meter_name setFont:[UIFont systemFontOfSize:24]];
    self.fw_version = [[UILabel alloc] init];
    [self.fw_version setFont:[UIFont systemFontOfSize:16]];
    self.rssi_icon  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sig_icon_0.png"]];
    self.conn_icon  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disconnected.png"]];

    [self addSubview:_meter_name];
    [self addSubview:_fw_version];
    [self addSubview:_rssi_icon];
    [self addSubview:_conn_icon];

    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];

    // Place the name
    [self.meter_name sizeToFit];
    CGRect b = self.meter_name.bounds;
    b = [CG centerVert:self.bounds new_size:b.size];
    b = CGRectOffset(b,0,-b.size.height/2);
    b.origin.x = 10;
    self.meter_name.frame = b;

    // Place the FW version
    [self.fw_version sizeToFit];
    b = self.fw_version.bounds;
    b = [CG centerVert:self.bounds new_size:b.size];
    b = CGRectOffset(b,0,b.size.height/2);
    b.origin.x = 10;
    self.fw_version.frame = b;

    // Place the connection icon
    self.conn_icon.bounds = CGRectMake(0,0,50,50);
    b = [CG centerVert:self.bounds new_size:self.conn_icon.bounds.size];
    b = [CG alignRight:b to:self.bounds];
    b = CGRectOffset(b,-10,0);
    self.conn_icon.frame = b;

    // Place the rssi icon
    b = [CG centerVert:self.bounds new_size:self.rssi_icon.bounds.size];
    b = [CG abutRight:b to:self.conn_icon.frame];
    b = CGRectOffset(b,-10,0);
    self.rssi_icon.frame = b;
}

#pragma mark getters/setters

-(LGPeripheral*)getPeripheral {
    return _peripheral;
}
-(void)setPeripheral:(LGPeripheral *)peripheral {
    uint32 build_time = 0;
    
    _peripheral = peripheral;

    if(peripheral == nil) {
        NSLog(@"Shouldn't have received a nil device");
        return;
    }
        
    switch(self.peripheral.cbPeripheral.state) {
        case CBPeripheralStateDisconnecting:
            [self.conn_icon setImage:[UIImage imageNamed:@"disconnected.png"]];
            [self.conn_icon setAlpha:0.5];
            break;
        case CBPeripheralStateDisconnected:
            //self.backgroundColor = [UIColor whiteColor];
            [self.conn_icon setImage:[UIImage imageNamed:@"disconnected.png"]];
            [self.conn_icon setAlpha:1.0];
            break;
        case CBPeripheralStateConnecting:
            //self.backgroundColor = [UIColor orangeColor];
            [self.conn_icon setImage:[UIImage imageNamed:@"connected.png"]];
            [self.conn_icon setAlpha:0.5];
            break;
        case CBPeripheralStateConnected:
            //self.backgroundColor = [UIColor greenColor];
            [self.conn_icon setImage:[UIImage imageNamed:@"connected.png"]];
            [self.conn_icon setAlpha:1.0];
            break;
    }

    build_time = [MooshimeterDeviceBase getBuildTimeFromPeripheral:self.peripheral];
    self.meter_name.text = [NSString stringWithFormat:@"%@",self.peripheral.name];
    self.fw_version.text = [NSString stringWithFormat:@"FW Build: %u",build_time];

    int percent = peripheral.RSSI+100;
    percent=percent>100?100:percent;
    percent=percent<0?0:percent;
    [self.rssi_icon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sig_icon_%d.png",percent]]];
}
@end
