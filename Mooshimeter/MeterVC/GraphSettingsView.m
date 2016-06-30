//
// Created by James Whong on 5/14/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "GraphSettingsView.h"
#import "WidgetFactory.h"
#import "PopupMenu.h"
#import "GCD.h"

@implementation TitledSwitch
-(instancetype)init {
    self = [super init];
    _title = [[UILabel alloc]init];
    [_title setFont:[UIFont systemFontOfSize:24]];
    DECLARE_WEAKSELF;
    _sw    = [WidgetFactory makeSwitch:^(bool i) {
        ws.callback(i);
    }];
    _title.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle)];
    [_title addGestureRecognizer:tapGesture];
    _callback=nil;
    [self addSubview:_title];
    [self addSubview:_sw];
    return self;
}
-(void)toggle {
    [_sw setOn:!_sw.on animated:YES];
    _callback(_sw.on);
}
-(void)layoutSubviews {
    CGRect f;
    f = self.bounds;
    [_title sizeToFit];
    f = _title.frame;
    f.size.width = self.bounds.size.width - _sw.bounds.size.width;
    f.origin.x = 0;
    //f = [CG centerIn:self.bounds new_size:f.size];
    //f = CGRectOffset(f,0,-f.size.height/2);
    [_title setFrame:f];

    f.size.width = _sw.bounds.size.width;
    f.origin.x += _title.frame.size.width;
    //f = [CG centerIn:self.bounds new_size:f.size];
    //f = CGRectOffset(f,0,f.size.height/2);
    [_sw setFrame:f];
}
@end

@implementation GraphSettingsView

-(instancetype)init {
    self = [super init];
    DECLARE_WEAKSELF;

    _xy_sw = [[TitledSwitch alloc]init];
    [_xy_sw.title setText:@"XY Mode"];
    _xy_sw.callback = ^(BOOL i) {
        ws.graph.xy_mode = i;
    };
    [self addSubview:_xy_sw];

    _buffer_sw = [[TitledSwitch alloc]init];
    [_buffer_sw.title setText:@"Buffer Mode"];
    _buffer_sw.callback = ^(BOOL i) {
        ws.graph.buffer_mode = i;
    };
    [self addSubview:_buffer_sw];

    _lock_sw = [[TitledSwitch alloc]init];
    [_lock_sw.title setText:@"Autoscroll"];
    _lock_sw.callback = ^(BOOL i) {
        ws.graph.autoscroll = i;
    };
    [self addSubview:_lock_sw];

    _ch1_auto = [[TitledSwitch alloc]init];
    [_ch1_auto.title setText:@"CH1 Autorange"];
    _ch1_auto.callback = ^(BOOL i) {
        ws.graph.left_axis_auto = i;
    };
    [self addSubview:_ch1_auto];

    _ch2_auto = [[TitledSwitch alloc]init];
    [_ch2_auto.title setText:@"CH2 Autorange"];
    _ch2_auto.callback = ^(BOOL i) {
        ws.graph.right_axis_auto = i;
    };
    [self addSubview:_ch2_auto];

    _n_samples_button = [WidgetFactory makeButton:@"override" callback:^{
        NSArray* option_vals = @[@50,@100,@200,@500,@1000];
        NSMutableArray* option_strings = [NSMutableArray array];
        for(NSNumber* val in option_vals) {
            [option_strings addObject:[NSString stringWithFormat:@"%@",val]];
        }
        [PopupMenu displayOptionsWithParent:self
                                      title:@"Select maximum number of points onscreen"
                                    options:option_strings
                                   callback:^(int i) {
                                       int n_points = [option_vals[i] intValue];
                                       self.graph.max_points_onscreen = n_points;
                                       [self.n_samples_button setTitle:[NSString stringWithFormat:@"Max datapoints: %d",n_points] forState:UIControlStateNormal];
                                   }];
    }];
    [self addSubview:_n_samples_button];
    return self;
}

-(void)setGraph:(GraphVC *)graph {
    _graph=graph;
    [_xy_sw.sw setOn:graph.xy_mode];
    [_buffer_sw.sw setOn:graph.buffer_mode];
    [_lock_sw.sw setOn:graph.autoscroll];
    [_ch1_auto.sw setOn:graph.left_axis_auto];
    [_ch2_auto.sw setOn:graph.right_axis_auto];
    [_n_samples_button setTitle:[NSString stringWithFormat:@"Max datapoints: %d",graph.max_points_onscreen] forState:UIControlStateNormal];
}

-(void)layoutSubviews {
    float bw = self.frame.size.width-20;
    float bh = 45;
    CGRect subframe = CGRectMake(10,10,bw,bh);

    _xy_sw.frame = subframe;
    subframe = CGRectOffset(subframe,0,bh);
    _buffer_sw.frame = subframe;
    subframe = CGRectOffset(subframe,0,bh);
    _lock_sw.frame = subframe;
    subframe = CGRectOffset(subframe,0,bh);
    _ch1_auto.frame = subframe;
    subframe = CGRectOffset(subframe,0,bh);
    _ch2_auto.frame = subframe;
    subframe = CGRectOffset(subframe,0,bh);
    _n_samples_button.frame = subframe;

}

@end