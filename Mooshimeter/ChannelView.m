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

@implementation ChannelView

-(instancetype)initWithFrame:(CGRect)frame ch:(NSInteger)ch{
    UILabel* l;
    self = [super initWithFrame:frame];
    self.userInteractionEnabled = YES;
    self->channel = ch;

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
    BOOL* b = &g_meter->disp_settings.auto_range[self->channel];
    *b = !*b;
    [self refreshAllControls];
}

-(void)auto_manual_button_refresh {
    BOOL* b = &g_meter->disp_settings.auto_range[self->channel];
    [MeterViewController style_auto_button:self.auto_manual_button on:*b];
}

-(void)display_set_button_press {
    // If on normal electrode input, toggle between AC and DC display
    // If reading CH3, cycle from VauxDC->VauxAC->Resistance->Diode
    // If reading temp, do nothing
    uint8 setting = [g_meter getChannelSetting:self->channel] & METER_CH_SETTINGS_INPUT_MASK;
    BOOL* const ac_setting = &g_meter->disp_settings.ac_display[self->channel];
    uint8* const ch3_mode  = &g_meter->disp_settings.ch3_mode;
    uint8* const measure_setting  = &g_meter->meter_settings.rw.measure_settings;
    switch(setting) {
        case 0x00:
            // Electrode input
            *ac_setting = !*ac_setting;
            break;
        case 0x04:
            // Temp input
            break;
        case 0x09:
            switch(*ch3_mode) {
                case CH3_VOLTAGE:
                    *ac_setting = !*ac_setting;
                    if(!*ac_setting) (*ch3_mode)++;
                    break;
                case CH3_RESISTANCE:
                    (*ch3_mode)++;
                    break;
                case CH3_DIODE:
                    (*ch3_mode) = CH3_VOLTAGE;
                    break;
            }
            [g_meter clearOffsets];
            switch(*ch3_mode) {
                case CH3_VOLTAGE:
                    *measure_setting &=~METER_MEASURE_SETTINGS_ISRC_ON;
                    *measure_setting &=~METER_MEASURE_SETTINGS_ISRC_LVL;
                    g_meter->meter_settings.rw.calc_settings    &=~METER_CALC_SETTINGS_RES;
                    break;
                case CH3_RESISTANCE:
                    *measure_setting |= METER_MEASURE_SETTINGS_ISRC_ON;
                    g_meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_RES;
                    break;
                case CH3_DIODE:
                    *measure_setting |= METER_MEASURE_SETTINGS_ISRC_ON;
                    g_meter->meter_settings.rw.calc_settings &=~METER_CALC_SETTINGS_RES;
                    break;
            }
            [g_meter clearOffsets];
            break;
    }
    [g_meter sendMeterSettings:^(NSError *error) {
        [self refreshAllControls];
    }];

}

-(void)display_set_button_refresh {
    [self.display_set_button setTitle:[g_meter getDescriptor:self->channel] forState:UIControlStateNormal];
}

-(void)input_set_button_press {
    uint8 setting       = [g_meter getChannelSetting:self->channel];
    uint8 other_setting = [g_meter getChannelSetting:self->channel==1?2:1];
    switch(setting & METER_CH_SETTINGS_INPUT_MASK) {
        case 0x00:
            // Electrode input: Advance to CH3 unless the other channel is already on CH3
            if((other_setting & METER_CH_SETTINGS_INPUT_MASK) == 0x09 ) {
                setting &= ~METER_CH_SETTINGS_INPUT_MASK;
                setting |= 0x04;
                // Turn off AC analysis - no such thing as AC temperature
                g_meter->disp_settings.ac_display[self->channel] = NO;
                // Temp input - set to PGA gain 1 always
                setting &=~METER_CH_SETTINGS_PGA_MASK;
                setting |= 0x10;
            } else {
                setting &= ~METER_CH_SETTINGS_INPUT_MASK;
                setting |= 0x09;
            }
            break;
        case 0x09:
            // CH3 input
            setting &= ~METER_CH_SETTINGS_INPUT_MASK;
            setting |= 0x04;
            // FIXME: Repeated code
            // Turn off AC analysis - no such thing as AC temperature
            g_meter->disp_settings.ac_display[self->channel] = NO;
            // Temp input - set to PGA gain 1 always
            setting &=~METER_CH_SETTINGS_PGA_MASK;
            setting |= 0x10;
            break;
        case 0x04:
            // Temp input 
            setting &= ~METER_CH_SETTINGS_INPUT_MASK;
            setting |= 0x00;
            break;
    }
    [g_meter setChannelSetting:self->channel set:setting];
    [g_meter sendMeterSettings:^(NSError *error) {
        [self refreshAllControls];
    }];
    
}

-(void)input_set_button_refresh {
    [self.input_set_button setTitle:[g_meter getInputLabel:self->channel] forState:UIControlStateNormal];
}

-(void)units_button_press {
    BOOL* b = &g_meter->disp_settings.raw_hex[self->channel];
    *b=!*b;
    [self refreshAllControls];
}

-(void)units_button_refresh {
    NSString* unit_str;
    if(!g_meter->disp_settings.raw_hex[self->channel]) {
        SignificantDigits digits = [g_meter getSigDigits:self->channel];
        const NSString* prefixes[] = {@"μ",@"m",@"",@"k",@"M"};
        uint8 prefix_i = 2;
        //TODO: Unify prefix handling.
        while(digits.high > 4) {
            digits.high -= 3;
            prefix_i++;
        }
        while(digits.high <=0) {
            digits.high += 3;
            prefix_i--;
        }
        unit_str = [NSString stringWithFormat:@"%@%@",prefixes[prefix_i],[g_meter getUnits:self->channel]];
    } else {
        unit_str = @"RAW";
    }
    [self.units_button setTitle:unit_str forState:UIControlStateNormal];
}

-(void)range_button_press {
    uint8 channel_setting = [g_meter getChannelSetting:self->channel];
    
    if(g_meter->disp_settings.auto_range[self->channel]) {
        return;
    }
    
    [g_meter bumpRange:self->channel raise:YES wrap:YES];
    [g_meter setChannelSetting:self->channel set:channel_setting];
    [g_meter sendMeterSettings:^(NSError *error) {
        [self refreshAllControls];
    }];
}

-(void)range_button_refresh {
    // How many different ranges do we want to support?
    // Supporting a range for every single PGA gain seems mighty excessive.
    
    uint8 channel_setting = [g_meter getChannelSetting:self->channel];
    uint8 measure_setting = g_meter->meter_settings.rw.measure_settings;
    uint8* const adc_setting = &g_meter->meter_settings.rw.adc_settings;
    uint8* const ch3_mode  = &g_meter->disp_settings.ch3_mode;
    NSString* lval;
    
    switch(channel_setting & METER_CH_SETTINGS_INPUT_MASK) {
        case 0x00:
            // Electrode input
            switch(self->channel) {
                case 0:
                    switch(channel_setting&METER_CH_SETTINGS_PGA_MASK) {
                        case 0x10:
                            lval = @"10A";
                            break;
                        case 0x40:
                            lval = @"2.5A";
                            break;
                        case 0x60:
                            lval = @"1A";
                            break;
                        default:
                            DLog(@"Invalid channel setting");
                            break;
                    }
                    break;
                case 1:
                    switch(*adc_setting & ADC_SETTINGS_GPIO_MASK) {
                        case 0x00:
                            lval = @"1.2V";
                            break;
                        case 0x10:
                            lval = @"60V";
                            break;
                        case 0x20:
                            lval = @"600V";
                            break;
                    }
                    break;
            }
            break;
        case 0x04:
            // Temp input
            lval = @"60C";
            break;
        case 0x09:
            switch(*ch3_mode) {
                case CH3_VOLTAGE:
                case CH3_DIODE:
                    switch(channel_setting&METER_CH_SETTINGS_PGA_MASK) {
                        case 0x10:
                            lval = @"1.2V";
                            break;
                        case 0x40:
                            lval = @"300mV";
                            break;
                        case 0x60:
                            lval = @"100mV";
                            break;
                    }
                    break;
                case CH3_RESISTANCE:
                    switch((channel_setting&METER_CH_SETTINGS_PGA_MASK) | (measure_setting & (METER_MEASURE_SETTINGS_ISRC_ON|METER_MEASURE_SETTINGS_ISRC_LVL))) {
                        case 0x13:
                            lval = @"10kΩ";
                            break;
                        case 0x43:
                            lval = @"2.5kΩ";
                            break;
                        case 0x63:
                            lval = @"1kΩ";
                            break;
                        case 0x12:
                            lval = @"250kΩ";
                            break;
                        case 0x42:
                            lval = @"100kΩ";
                            break;
                        case 0x62:
                            lval = @"25kΩ";
                            break;
                        case 0x11:
                            lval = @"10MΩ";
                            break;
                        case 0x41:
                            lval = @"2.5MΩ";
                            break;
                        case 0x61:
                            lval = @"1MΩ";
                            break;
                    }
                    break;
            }
            break;
    }
    [self.range_button setTitle:lval forState:UIControlStateNormal];
    if(g_meter->disp_settings.auto_range[self->channel]) {
        [self.range_button setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.range_button setBackgroundColor:[UIColor whiteColor]];
    }
}

-(void)value_label_refresh {
    const int c = self->channel;
    const BOOL ac = g_meter->disp_settings.ac_display[c];
    double val;
    int lsb_int;
    switch(channel) {
        case 0:
            if(ac) { lsb_int = (int)(sqrt(g_meter->meter_sample.ch1_ms)); }
            else   { lsb_int = [LegacyMooshimeterDevice to_int32:g_meter->meter_sample.ch1_reading_lsb]; }
            break;
        case 1:
            if(ac) { lsb_int = (int)(sqrt(g_meter->meter_sample.ch2_ms)); }
            else   { lsb_int = [LegacyMooshimeterDevice to_int32:g_meter->meter_sample.ch2_reading_lsb]; }
            break;
    }
    
    if(g_meter->disp_settings.raw_hex[c]) {
        lsb_int &= 0x00FFFFFF;
        self.value_label.text = [NSString stringWithFormat:@"%06X", lsb_int];
    } else {
        // If at the edge of your range, say overload
        // Remember the bounds are asymmetrical
        const int32 upper_limit_lsb =  1.1*(1<<22);
        const int32 lower_limit_lsb = -0.9*(1<<22);
        
        if(   lsb_int > upper_limit_lsb
           || lsb_int < lower_limit_lsb ) {
            self.value_label.text = @"OVERLOAD";
        } else {
            // FIXME: Resistance measurement completely breaks all our idioms because it is presented
            // by the meter in native units AND as LSB.  This is a transitional issue... future firmware
            // versions will be sending native units across the link, but we're stuck in the in-between
            // right now.
            uint8 chset = c?g_meter->meter_settings.rw.ch2set:g_meter->meter_settings.rw.ch1set;
            if(    0x09==(chset&METER_CH_SETTINGS_INPUT_MASK)   // If we're measuring CH3
               &&  (g_meter->meter_info.build_time > 1445139447)  // And we have a firmware version late enough that the resistance is calculated in firmware
               &&  0x00!=(g_meter->meter_settings.rw.calc_settings&METER_CALC_SETTINGS_RES) ) { // And the resistance calculation flag is set
                // FIXME: We're packing the calculated resistance in to the mean-square field!
                val = c?g_meter->meter_sample.ch2_ms:g_meter->meter_sample.ch1_ms;
            } else {
                val = [g_meter lsbToNativeUnits:lsb_int ch:c];
            }

            self.value_label.text = [MeterViewController formatReading:val digits:[g_meter getSigDigits:c] ];
        }
    }
}

-(void)refreshAllControls {
    [self display_set_button_refresh];
    [self input_set_button_refresh];
    [self auto_manual_button_refresh];
    [self units_button_refresh];
    [self range_button_refresh];
    //[self value_label_refresh];
}

@end
