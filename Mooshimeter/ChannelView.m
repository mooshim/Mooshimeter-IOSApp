//
//  ChannelView.m
//  Mooshimeter
//
//  Created by James Whong on 11/9/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import "ChannelView.h"

@implementation ChannelView

-(ChannelView*)initWithFrame:(CGRect)frame{
    // Assume height of 200px
    self = [super initWithFrame:frame];
    UILabel* l;
    
    float h = frame.size.height;
    float w = frame.size.width;
    
    self.display_set_button = [self makeButton:CGRectMake(0, 0, w*2/3, h/4) name:@"Display Name" cb:@selector(disp_setting_press)];
    
    self.input_set_button = [self makeButton:CGRectMake(w*2/3, 0, w/3, h/4) name:@"Input" cb:@selector(input_set_press)];
    
    self.auto_manual_button = [self makeButton:CGRectMake(0, h*3/4, w/6, h/4) name:@"A" cb:@selector(auto_manual_button_press)];
    
    self.range_button = [self makeButton:CGRectMake(w/6, h*3/4, w/3, h/4) name:@"RANGE" cb:@selector(range_button_press)];
    
    l = [[UILabel alloc] initWithFrame:CGRectMake(0, h/4, w, h*2/4)];
    l.textColor = [UIColor blackColor];
    l.font = [UIFont fontWithName:@"Courier New" size:70];
    l.text = @"0.00000";
    [self addSubview:l];
    self.value_label = l;
    
    l = [[UILabel alloc] initWithFrame:CGRectMake(w/2, h*3/4, w/2, h/4)];
    l.textColor = [UIColor blackColor];
    l.font = [UIFont systemFontOfSize:24];;
    l.text = @"UNITS";
    l.textAlignment = CPTTextAlignmentCenter;
    [[l layer] setBorderWidth:2];
    [[l layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    [self addSubview:l];
    self.units_label = l;
    
    [[self layer] setBorderWidth:5];
    [[self layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    
    return self;
}

-(UIButton*)makeButton:(CGRect)frame name:(NSString*)name cb:(SEL)cb {
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b addTarget:self action:cb forControlEvents:UIControlEventTouchUpInside];
    [b.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [b setTitle:name forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[b layer] setBorderWidth:2];
    [[b layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    b.frame = frame;
    [self addSubview:b];
    return b;
}

-(void)reload {
    
}

@end
