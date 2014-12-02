//
//  GraphSettingsView.m
//  Mooshimeter
//
//  Created by James Whong on 11/16/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import "GraphSettingsView.h"

@implementation GraphSettingsView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.userInteractionEnabled = YES;
    
    const int nrow = 2;
    const int ncol = 3;
    
    float h = frame.size.height/nrow;
    float w = frame.size.width/ncol;
    
#define cg(nx,ny,nw,nh) CGRectMake(nx*w,ny*h,nw*w,nh*h)
#define mb(name, nx,ny,nw,nh) self.name = [self makeButton:cg(nx,ny,nw,nh) cb:@selector(name##_press)]
    
    mb(trend_or_burst_button,  0,0,3,1);
    mb(ch1_on_button,          0,1,1,1);
    mb(ch2_on_button,          1,1,1,1);
    mb(xy_on_button,           2,1,1,1);
    
#undef cg
#undef mb
    
    [[self layer] setBorderWidth:5];
    [[self layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    [self refreshAllControls];
    return self;
}

-(UIButton*)makeButton:(CGRect)frame cb:(SEL)cb {
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.userInteractionEnabled = YES;
    [b addTarget:self action:cb forControlEvents:UIControlEventTouchUpInside];
    [b.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [b setTitle:@"T" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[b layer] setBorderWidth:2];
    [[b layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    b.frame = frame;
    [self addSubview:b];
    return b;
}

#define DEC_TOGGLE_HANDLER(fname, pname) -(void)fname {\
BOOL* const b = &g_meter->disp_settings.pname;\
*b=!*b;\
[self refreshAllControls];\
}


DEC_TOGGLE_HANDLER(trend_or_burst_button_press, burst_capture);
DEC_TOGGLE_HANDLER(ch1_on_button_press, channel_disp[0]);
DEC_TOGGLE_HANDLER(ch2_on_button_press, channel_disp[1]);
DEC_TOGGLE_HANDLER(xy_on_button_press, xy_mode);

#undef DEC_TOGGLE_HANDLER

#define DEC_REF_HANDLER(on, off, b, butname) -(void)butname##_refresh {\
NSString* title;\
if( g_meter->disp_settings.b ) {\
    title = on;\
} else {\
    title = off;\
}\
[self.butname setTitle:title forState:UIControlStateNormal];\
}

DEC_REF_HANDLER(@"Burst Mode", @"Trend Mode", burst_capture, trend_or_burst_button);
DEC_REF_HANDLER(@"CH1:ON", @"CH1:OFF", channel_disp[0], ch1_on_button);
DEC_REF_HANDLER(@"CH2:ON", @"CH2:OFF", channel_disp[1], ch2_on_button);
DEC_REF_HANDLER(@"XY:ON", @"XY:OFF", xy_mode, xy_on_button);


#undef DEC_REF_HANDLERxy_on_button_refresh

-(void)refreshAllControls {
    [self trend_or_burst_button_refresh];
    [self ch1_on_button_refresh];
    [self ch2_on_button_refresh];
    [self xy_on_button_refresh];
}

@end
