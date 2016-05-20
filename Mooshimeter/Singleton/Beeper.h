//
// Created by James Whong on 5/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "oad.h"

@interface Beeper : NSObject <AVAudioPlayerDelegate>
@property AVAudioPlayer * audioPlayer;
+(void)beep;
@end