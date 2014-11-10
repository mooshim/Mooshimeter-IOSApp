//
//  SmartNavigationController.m
//  Mooshimeter
//
//  Created by James Whong on 11/6/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import "SmartNavigationController.h"

@interface SmartNavigationController ()

@end

@implementation SmartNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration NS_DEPRECATED_IOS(2_0,8_0, "Implement viewWillTransitionToSize:withTransitionCoordinator: instead") {
    NSLog(@"TODO!");
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator NS_AVAILABLE_IOS(8_0) {
    NSLog(@"TODO!");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
