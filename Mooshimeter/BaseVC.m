//
// Created by James Whong on 5/11/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "BaseVC.h"
#import "GCD.h"
#import "WidgetFactory.h"
#import "UIView+Toast.h"

@implementation BaseVC

/////////////////
// Lifecycle
/////////////////

- (void)viewDidLoad
{
    [super viewDidLoad];
    // For debug
    NSLog(@"View %@ loaded!",NSStringFromClass([self class]));

    // Calculate the content area to save the subclasses some math
    self.visible_h = (self.view.bounds.size.height);
    self.visible_w = (self.view.bounds.size.width);
    self.ncol = 0;
    self.nrow = 0;

    float origin_y = 0;
    origin_y += [[UIApplication sharedApplication] statusBarFrame].size.height;
    origin_y += self.navigationController.navigationBar.frame.size.height;

    self.visible_h -= origin_y;

    self.content_view = [[UIView alloc] initWithFrame:CGRectMake(0, origin_y, self.visible_w, self.visible_h)];

    self.view.userInteractionEnabled = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.content_view];
    // Should be overridden by base classes
    [self populateNavBar];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"View %@ will appear!",NSStringFromClass([self class]));
    // Always clear the navigation bar
    //[[SmartNavigationController getSharedInstance] clearNavBar];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"View %@ will disappear!",NSStringFromClass([self class]));
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"View %@ did appear!",NSStringFromClass([self class]));
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"View %@ did disappear!",NSStringFromClass([self class]));
}

-(BOOL)shouldAutorotate { return NO; }

/////////////////
// Convenience calls
/////////////////

-(CGRect)makeRectInGrid:(int)col_off row_off:(int)row_off
                  width:(int)col_w height:(int)row_h {

    if(self.ncol==0 || self.nrow==0) {
        NSLog(@"ERROR!  YOU NEED TO SET ncol AND nrow BEFORE CALLING THIS!");
        return CGRectMake(0,0,0,0);
    }
    float h = self.visible_h/self.nrow;
    float w = self.visible_w/self.ncol;
    return CGRectMake(col_off*w,row_off*h,col_w*w,row_h*h);
}

-(UIButton*)makeButton:(CGRect)frame cb:(SEL)cb {
    DECLARE_WEAKSELF;
    UIButton *b = [WidgetFactory makeButton:@"Refactor!" callback:^{
        if(ws != nil && [ws respondsToSelector:cb]) {
            [ws performSelector:cb];
        }
    }];
    [b setFrame:frame];
    [self.content_view addSubview:b];
    return b;
}

- (void)populateNavBar {
    NSLog(@"Override populateNavBar in the subclasses!");
}

-(void)addToNavBar:(UIView*)new_item {
    NSMutableArray * items;
    if(self.navigationItem.rightBarButtonItems==nil) {
        items = [NSMutableArray array];
    } else {
        items = [self.navigationItem.rightBarButtonItems mutableCopy];
    }
    UIBarButtonItem * barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:new_item];
    [items addObject:barButtonItem];
    self.navigationItem.rightBarButtonItems = items;
}

-(void)setBusy:(BOOL)busy {
    [GCD asyncMain:^{
        if(_busymsg_up && !busy) {
            _busymsg_up=NO;
            [self.content_view hideToastActivity];
        }
        if(!_busymsg_up && busy) {
            _busymsg_up=YES;
            [self.content_view makeToastActivity:CSToastPositionCenter];
        }
    }];
}
@end