//
//  OADViewController.m
//  TI BLE Multitool
//
//  Created by Ole Andreas Torvmark on 7/16/13.
//  Copyright (c) 2013 Ole Andreas Torvmark. All rights reserved.
//

#import "OADProgressViewController.h"
#import "Lock.h"

@implementation OADViewController


- (instancetype)initWithMeter:(MooshimeterDeviceBase*)meter
{
    self = [super init];
    // Initialization code
    self.meter = (OADDevice*)meter;
    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.view.backgroundColor = [UIColor whiteColor];

    self.label1 = [[UILabel alloc]init];
    self.label2 = [[UILabel alloc]init];
    self.label1.textAlignment = NSTextAlignmentCenter;
    self.label2.textAlignment = NSTextAlignmentCenter;
    self.label1.textColor = [UIColor blackColor];
    self.label2.textColor = [UIColor blackColor];
    self.label1.backgroundColor = [UIColor clearColor];
    self.label2.backgroundColor = [UIColor clearColor];
    self.label1.font = [UIFont boldSystemFontOfSize:14.0f];
    self.label2.font = [UIFont boldSystemFontOfSize:14.0f];
    self.label1.textAlignment = NSTextAlignmentCenter;
    self.label2.textAlignment = NSTextAlignmentCenter;

    [self setupView];

    [self.view addSubview:self.progressBar];
    [self.view addSubview:self.label1];
    [self.view addSubview:self.label2];

    self.title = @"Firmware upload in progress";
    self.label1.text = @"0%";
    [self.view setNeedsLayout];

    self.oad_profile = [[OADProfile alloc] init:self.meter];
    self.oad_profile.progressView = self;

    return self;
}

-(void) setupView {
    float center = self.view.bounds.size.width / 2;
    float width = self.view.bounds.size.width - 40;
    
    self.label1.frame = CGRectMake(center - (width / 2), 80, width, 20);
    self.label2.frame = CGRectMake(center - (width / 2), 110, width, 20);
    self.progressBar.frame = CGRectMake(center - (width /2), 150, width, 20);
}

-(void)viewWillAppear:(BOOL)animated {
    [self.oad_profile startUpload];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self setupView];
}

@end
