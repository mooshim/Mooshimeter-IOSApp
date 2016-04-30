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

#import "ChannelView.h"
#import "PopupMenu.h"

@implementation ChannelView

-(instancetype)initWithFrame:(CGRect)frame ch:(NSInteger)ch meter:(MooshimeterDeviceBase *)meter{
    UILabel* l;
    self = [super initWithFrame:frame];
    self.userInteractionEnabled = YES;
    self.channel = ch;
    self.meter = meter;

    float h = frame.size.height/4;
    float w = frame.size.width/6;
    
#define cg(nx,ny,nw,nh) CGRectMake(nx*w,ny*h,nw*w,nh*h)
#define mb(nx,ny,nw,nh,s) [self makeButton:cg(nx,ny,nw,nh) cb:@selector(s)]

    self.display_set_button = mb(0,0,4,1,display_set_button_press);
    self.input_set_button   = mb(4,0,2,1,input_set_button_press);
    self.auto_manual_button = mb(0,3,1,1,auto_manual_button_press);
    self.range_button       = mb(1,3,2,1,range_button_press);
    self.units_button       = mb(3,3,3,1,units_button_press);
    
    l = [[UILabel alloc] initWithFrame:cg(0,1,6,2)];
    l.textColor = [UIColor blackColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont fontWithName:@"Courier New" size:65];
    l.text = @"0.00000";
    [self addSubview:l];
    self.value_label = l;
    
#undef cg
#undef mb
    
    [[self layer] setBorderWidth:5];
    [[self layer] setBorderColor:[UIColor blackColor].CGColor];
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
    [[b layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    b.frame = frame;
    [self addSubview:b];
    return b;
}


-(void)auto_manual_button_press{
    self.meter.range_auto[self.channel] = !self.meter.range_auto[self.channel];
    [self refreshAllControls];
}

-(void)auto_manual_button_refresh {
    [MeterViewController style_auto_button:self.auto_manual_button on:self.meter.range_auto[self.channel]];
}

-(void)display_set_button_press {
    // If on normal electrode input, toggle between AC and DC display
    // If reading CH3, cycle from VauxDC->VauxAC->Resistance->Diode
    // If reading temp, do nothing

    [PopupMenu displayOptionsWithParent:self
                                  title:@"Input Select"
                                options:[self.meter getInputNameList:self.channel]
                               callback:^(int i) {
                                   NSLog(@"Received %d", i);
                                   [self.meter setInput:self.channel
                                             descriptor:[self.meter getInputList:self.channel][i]];
                               }];
}

-(void)display_set_button_refresh {
    [self.display_set_button setTitle:[self.meter getInputLabel:self.channel] forState:UIControlStateNormal];
}

-(void)input_set_button_press {
    //fewafwafewa
}

-(void)input_set_button_refresh {
    // NO LONGER RELEVANT
    //[self.input_set_button setTitle:[g_meter getInputLabel:self.channel] forState:UIControlStateNormal];
}

-(void)units_button_press {
    // NO LONGER RELEVANT
}

-(void)units_button_refresh {
    // NO LONGER RELEVANT
}

-(void)range_button_press {
    [PopupMenu displayOptionsWithParent:self
                                  title:@"Range"
                                options:[self.meter getRangeNameList:self.channel]
                               callback:^(int i) {
                                   NSArray<RangeDescriptor*>* choices = [self.meter getRangeList:self.channel];
                                   [self.meter setRange:self.channel rd:choices[i]];
                               }];
}

-(void)range_button_refresh {
    NSString * lval = [self.meter getRangeLabel:self.channel];
    [self.range_button setTitle:lval forState:UIControlStateNormal];
    if(self.meter.range_auto[self.channel]) {
        [self.range_button setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.range_button setBackgroundColor:[UIColor whiteColor]];
    }
}

-(void)value_label_refresh {
    self.value_label.text = [[self.meter getValue:self.channel] toString];
}

-(void)refreshAllControls {
    [self display_set_button_refresh];
    [self input_set_button_refresh];
    [self auto_manual_button_refresh];
    [self units_button_refresh];
    [self range_button_refresh];
    [self value_label_refresh];
}

@end
