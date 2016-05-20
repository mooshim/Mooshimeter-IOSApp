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
#import "WidgetFactory.h"

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
    self.range_button       = mb(4,0,2,1,range_button_press);
    self.zero_button        = mb(0,3,3,1,zero_button_press);
    self.sound_button       = mb(3,3,3,1,sound_button_press);

    l = [[UILabel alloc] initWithFrame:cg(0,1,6,2)];
    l.textColor = [UIColor blackColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont fontWithName:@"Courier New" size:65];
    l.text = @"0.00000";
    l.adjustsFontSizeToFitWidth = YES;
    [self addSubview:l];
    self.value_label = l;
    
#undef cg
#undef mb
    return self;
}

-(UIButton*)makeButton:(CGRect)frame cb:(SEL)cb {
    UIButton* b;
    __weak id weakself=self;
    b=[WidgetFactory makeButton:@"FILL" callback:^{
        if(weakself==nil){return;}
        if(![weakself respondsToSelector:cb]){return;}
        [weakself performSelector:cb];
    }];
    [b setFrame:frame];
    [self addSubview:b];
    return b;
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

-(void)range_button_press {
    NSArray* range_list = [self.meter getRangeNameList:self.channel];
    [PopupMenu displayOptionsWithParent:self
                                  title:@"Range"
                                options:range_list
                                 cancel:@"AUTORANGE"
                               callback:^(int i) {
                                   if(i>= [range_list count]) {
                                       self.meter.range_auto[self.channel]=YES;
                                   } else {
                                       self.meter.range_auto[self.channel]=NO;
                                       NSArray<RangeDescriptor*>* choices = [self.meter getRangeList:self.channel];
                                       [self.meter setRange:self.channel rd:choices[i]];
                                   }
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

-(void)value_label_refresh:(MeterReading*)value {
    self.value_label.text = [value toString];
}

-(void) zero_button_press {
    MeterReading * offset = [self.meter getOffset:self.channel];
    if(offset==nil || offset.value==0) {
        // No offset is set
        MeterReading * val = [self.meter getValue:self.channel];
        [self.meter setOffset:self.channel offset:val.value];
    } else {
        // Clear the offset
        [self.meter setOffset:self.channel offset:0];
    }
}

-(void) zero_button_refresh {
    MeterReading * offset = [self.meter getOffset:self.channel];
    if(offset==nil || offset.value==0) {
        // No offset is set
        [self.zero_button setTitle:@"ZERO" forState:UIControlStateNormal];
    } else {
        [self.zero_button setTitle:[offset toString] forState:UIControlStateNormal];
    }
}

-(void) sound_button_press {
    NSLog(@"sound");
    uint8 other_channel = (self.channel+1)%2;
    self.meter.speech_on[self.channel] = !self.meter.speech_on[self.channel];
    // FIXME: We need a way to reach over and poke the other button!
    //if(self.meter.speech_on[self.channel]) {
    //    self.meter.speech_on[other_channel] = NO;
    //}
    [self sound_button_refresh];
};

-(void)sound_button_refresh {
    // Toggle sound setting for meter
    uint8 other_channel = (self.channel+1)%2;
    NSString* title;

    if(self.meter.speech_on[self.channel]) {
        title = @"SOUND:ON";
    } else {
        title = @"SOUND:OFF";
    }
    [self.sound_button setTitle:title forState:UIControlStateNormal];
}

-(void)refreshAllControls {
    [self display_set_button_refresh];
    [self range_button_refresh];
    [self zero_button_refresh];
    [self sound_button_refresh];
}

@end
