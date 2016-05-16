//
// Created by James Whong on 5/11/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "BaseVC.h"


@implementation BaseVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"View %@ loaded!",NSStringFromClass([self class]));

    volatile CGRect frame  = self.view.frame;
    volatile CGRect bounds = self.view.bounds;

    //self.visible_h = (self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height)-status_bar_offset;
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
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"View %@ will appear!",NSStringFromClass([self class]));
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
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.userInteractionEnabled = YES;
    [b addTarget:self action:cb forControlEvents:UIControlEventTouchUpInside];
    [b.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [b setTitle:@"TBD" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[b layer] setBorderWidth:2];
    [[b layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    b.frame = frame;
    [self.content_view addSubview:b];
    return b;
}

@end