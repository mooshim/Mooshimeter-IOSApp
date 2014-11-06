/*
 BLETIOADProgressDialog.m
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "BLETIOADProgressDialog.h"

@implementation BLETIOADProgressDialog

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        self.label1 = [[UILabel alloc]init];
        self.label2 = [[UILabel alloc]init];
        self.label1.textColor = [UIColor whiteColor];
        self.label2.textColor = [UIColor whiteColor];
        self.label1.backgroundColor = [UIColor clearColor];
        self.label2.backgroundColor = [UIColor clearColor];
        self.label1.font = [UIFont boldSystemFontOfSize:14.0f];
        self.label2.font = [UIFont boldSystemFontOfSize:14.0f];
        self.label1.textAlignment = NSTextAlignmentCenter;
        self.label2.textAlignment = NSTextAlignmentCenter;
        [self addButtonWithTitle:@"Cancel"];
        self.cancelButtonIndex = 0;
        self.message = @"\n\n";	
        
        [self addSubview:self.progressBar];
        [self addSubview:self.label1];
        [self addSubview:self.label2];
        
        self.title = @"Firmware upload in progress";
        self.label1.text = @"0%";
        [self setNeedsLayout];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


-(void) layoutSubviews {
    self.frame = CGRectMake((self.superview.bounds.size.width / 2) - 150, (self.superview.bounds.size.height /2) - 80, self.frame.size.width, self.frame.size.height);
    [super layoutSubviews];
    self.progressBar.frame = CGRectMake(20, 45, 250, 10);
    self.label1.frame = CGRectMake(20,65,250,15);
    self.label2.frame = CGRectMake(20,80,250,15);
    
}

@end
