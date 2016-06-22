//
// Created by James Whong on 5/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "Beeper.h"

@implementation Beeper

static Beeper *shared = nil;

+(void)beep {
    if(shared==nil) {
        shared = [[Beeper alloc]init];
    }
    [shared.audioPlayer play];
}
-(instancetype)init {
    self = [super init];
    // Make a beeper
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
            pathForResource:@"beep"
                     ofType:@"wav"]];
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc]
            initWithContentsOfURL:url
                            error:&error];
    if (error) {
        NSLog(@"Error in audioPlayer: %@",[error localizedDescription]);
    } else {
        _audioPlayer.delegate = self;
    }
    return self;
}
@end