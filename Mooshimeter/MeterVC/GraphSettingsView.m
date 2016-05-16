//
// Created by James Whong on 5/14/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "GraphSettingsView.h"
#import "WidgetFactory.h"


@implementation GraphSettingsView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    __weak typeof(self) ws = self;
    UIButton* b = [WidgetFactory makeButton:@"HI THERE" callback:^{
        NSLog(@"PRESSED");
    }];
    b.frame = self.bounds;
    [self addSubview:b];
    return self;
}
@end