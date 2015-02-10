//
//  ScanSettingsView.m
//  Mooshimeter
//
//  Created by James Whong on 2/10/15.
//  Copyright (c) 2015 mooshim. All rights reserved.
//

#import "ScanSettingsView.h"

@implementation ScanSettingsView


-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.userInteractionEnabled = YES;
    
    // Initialize values and helpers
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // Lay out the controls
    const int nrow = 2;
    const int ncol = 1;
    
    float h = frame.size.height/nrow;
    float w = frame.size.width/ncol;
    
#define cg(nx,ny,nw,nh) CGRectMake(nx*w,ny*h,nw*w,nh*h)
    self.about_section  = [[UILabel  alloc]initWithFrame:cg(0,0,1,1)];
    self.help_button    = [[UIButton alloc]initWithFrame:cg(0,1,1,1)];
#undef cg
    
    // Set properties
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
    NSString *bundleName = infoDictionary[(NSString *)kCFBundleNameKey];
    
    NSString* about_string = [NSString stringWithFormat:@"Mooshimeter iOS App\nVersion Name: %@\nBuild:%@", bundleName, build];
    [self.about_section setText:about_string];
    [self.about_section setFont:[UIFont systemFontOfSize:20]];
    [self.about_section setTextAlignment:NSTextAlignmentCenter];
    self.about_section.numberOfLines = 3;
    
    [ self.help_button addTarget:self action:@selector(launchHelp) forControlEvents:UIControlEventTouchUpInside];
    [ self.help_button setTitle:@"Open Help Site" forState:UIControlStateNormal];
    [ self.help_button.titleLabel setFont:[UIFont systemFontOfSize:30]];
    [ self.help_button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[self.help_button layer] setBorderWidth:2];
    [[self.help_button layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    
    // Add as subviews
    [self addSubview:self.about_section];
    [self addSubview:self.help_button];
    
    [[self layer] setBorderWidth:5];
    [[self layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    return self;
}

// Control Callbacks

-(void)launchHelp {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://moosh.im/support/"]];
}


@end
