//
//  ScanTableViewCell.m
//  Mooshimeter
//
//  Created by James Whong on 11/4/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import "ScanTableViewCell.h"

@implementation ScanTableViewCell

-(ScanTableViewCell*) init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ScanCell"];
    return self;
}

- (ScanTableViewCell*)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}

-(void) setPeripheral:(CBPeripheral*)device {
    self.p = device;
    self.textLabel.text = [NSString stringWithFormat:@"%@",self.p.name];
    
    
    switch(self.p.state) {
        case CBPeripheralStateDisconnected:
            self.backgroundColor = [UIColor whiteColor];
            break;
        case CBPeripheralStateConnecting:
            self.backgroundColor = [UIColor orangeColor];
            break;
        case CBPeripheralStateConnected:
            self.backgroundColor = [UIColor greenColor];
            break;
    }
}

-(void) setRSSI:(NSNumber*)RSSI {
    self.detailTextLabel.text = [RSSI stringValue];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
