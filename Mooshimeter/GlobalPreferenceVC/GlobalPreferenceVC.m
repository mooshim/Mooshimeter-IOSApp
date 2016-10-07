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

#import "GlobalPreferenceVC.h"
#import "WidgetFactory.h"
#import "Prefman.h"


@implementation GlobalPreferenceVC {
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setTitle:@"Global Preferences"];

    {
        NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString* vstring = [NSString stringWithFormat:@"Mooshimeter iOS App %@ (%@)", appVersionString, appBuildString];
        [self addPreferenceCell:@"Version Information" msg:vstring accessory:nil];
    }

    [self addPreferenceCell:@"Temperature" msg:@"Use Fahrenheit?" accessory:[GlobalPreferenceVC makePrefSwitch:@"USE_FAHRENHEIT"]];

    {
        UIButton* help_button = [WidgetFactory makeButton:@"Go" callback:^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://moosh.im/support/"]];
        }];
        help_button.frame = CGRectMake(0,0,50,50);
        [self addPreferenceCell:@"Support" msg:@"Open help site" accessory:help_button];
    }
}

@end
