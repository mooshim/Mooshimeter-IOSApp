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

-(void) setMeter:(MooshimeterDevice*)device {
    self.d = device;
    self.textLabel.text = [NSString stringWithFormat:@"%@",self.d.p.name];
    
    UIActivityIndicatorView* spinner = (UIActivityIndicatorView*)self.accessoryView;
    
    switch(self.d.p.state) {
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
    
    self.detailTextLabel.text = [NSString stringWithFormat:@"RSSI: %d        FW Build: %u",[self.d.RSSI integerValue], [self.d.advBuildTime integerValue]];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
