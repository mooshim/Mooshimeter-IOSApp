//
//  BLETIOADProgressViewController.m
//  TI BLE Multitool
//
//  Created by Ole Andreas Torvmark on 7/16/13.
//  Copyright (c) 2013 Ole Andreas Torvmark. All rights reserved.
//

#import "BLETIOADProgressViewController.h"

@implementation BLETIOADProgressViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
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
        //[self addButtonWithTitle:@"Cancel"];
        //self.cancelButtonIndex = 0;
        //self.message = @"\n\n";
        
        
        [self setupView];
        
        [self.view addSubview:self.progressBar];
        [self.view addSubview:self.label1];
        [self.view addSubview:self.label2];
        
        self.title = @"Firmware upload in progress";
        self.label1.text = @"0%";
        [self.view setNeedsLayout];
    }
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
    [self setupView];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self setupView];
}

@end
