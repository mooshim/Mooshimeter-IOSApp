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
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.hidesWhenStopped = YES;
    self.accessoryView = spinner;
    return self;
}

-(void) setPeripheral:(LGPeripheral *)device {
    self.p = device;
    self.textLabel.text = [NSString stringWithFormat:@"%@",self.p.name];
    
    UIActivityIndicatorView* spinner = (UIActivityIndicatorView*)self.accessoryView;
    
    switch(self.p.cbPeripheral.state) {
        case CBPeripheralStateDisconnected:
            self.backgroundColor = [UIColor whiteColor];
            [spinner stopAnimating];
            break;
        case CBPeripheralStateConnecting:
            self.backgroundColor = [UIColor orangeColor];
            [spinner startAnimating];
            break;
        case CBPeripheralStateConnected:
            self.backgroundColor = [UIColor greenColor];
            [spinner stopAnimating];
            break;
    }
    
    uint32 build_time = 0;
    NSData* tmp;
    
    tmp = [self.p.advertisingData valueForKey:@"kCBAdvDataManufacturerData"];
    if( tmp != nil ) {
        [tmp getBytes:&build_time length:4];
    }

    self.detailTextLabel.text = [NSString stringWithFormat:@"RSSI: %d        FW Build: %u",self.p.RSSI, build_time];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
