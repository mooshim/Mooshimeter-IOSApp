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

#import "SmartNavigationController.h"

@interface SmartNavigationController ()

@end

@implementation SmartNavigationController

static SmartNavigationController *shared = nil;

+ (instancetype)getSharedInstance {
    return shared;
}

-(instancetype)init {
    if(shared != nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"init for this singleton should not be called more than once!"
                                     userInfo:nil];
    } else {
        // Do actual initialization
        self = [super initWithNavigationBarClass:[UINavigationBar class] toolbarClass:[UIToolbar class]];
        shared = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration NS_DEPRECATED_IOS(2_0,8_0, "Implement viewWillTransitionToSize:withTransitionCoordinator: instead") {
    return [self.topViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
@end
