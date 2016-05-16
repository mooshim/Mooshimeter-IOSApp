//
// Created by James Whong on 5/14/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "GraphSettingsVC.h"
#import "WidgetFactory.h"
#import "WYPopoverController.h"


@implementation GraphSettingsVC

-(BOOL)shouldAutorotate { return YES; }
-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft;
}
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeLeft;
}

-(void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof(self) ws = self;
    UIButton* b = [WidgetFactory makeButton:@"DISMISS" callback:^{
        [ws.popover dismissPopoverAnimated:YES completion:^{
            NSLog(@"Dismissed");
        }];
    }];
    [b setFrame:self.view.frame];
    [self.view addSubview:b];
}
@end