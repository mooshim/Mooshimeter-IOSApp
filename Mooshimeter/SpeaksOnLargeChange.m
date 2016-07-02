//
// Created by James Whong on 5/19/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "SpeaksOnLargeChange.h"
#import "GCD.h"
#import <AVFoundation/AVFoundation.h>

@implementation SpeaksOnLargeChange

-(NSString*) formatValueLabelForSpeaking:(NSString*)input {
    // Changes suffixes to speech-friendly versions (eg. "m" is rendered as "meters", which is wrong)
    if(input==nil||input.length==0){
        return @"";
    }
    NSMutableString *outbuilder = [NSMutableString string];
    for(int i = 0; i < input.length; i++) {
        unichar c = [input characterAtIndex:i];
        switch(c) {
            case '-':
                [outbuilder appendString:@"neg "];
                break;
            case 'm':
                [outbuilder appendString:@" milli "];
                break;
            case 'k':
                [outbuilder appendString:@" kilo "];
                break;
            case 'M':
                [outbuilder appendString:@" mega "];
                break;
            case 'A':
                [outbuilder appendString:@" amps "];
                break;
            case 'V':
                [outbuilder appendString:@" volts "];
                break;
            case 0x03A9: // Capital omega
                [outbuilder appendString:@" ohms "];
                break;
            case 'W':
                [outbuilder appendString:@" watts "];
                break;
            case 'F':
                [outbuilder appendString:@" fahrenheit "];
                break;
            case 'C':
                [outbuilder appendString:@" celsius "];
                break;
            default:
                [outbuilder appendFormat:@"%c",c];
                break;
        }
    }
    return outbuilder;
}

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

-(BOOL)decideAndSpeak:(MeterReading*)val {
    double threshold = MAX(ABS(0.20 * val.value), ABS(0.05 * val.max));
    double change = ABS(_last_value - val.value);
    if( !_cooldown_active  || (change>threshold)) {
        // If the value has changed 20%, or just every 5 second
        _last_value = val.value;
        NSString* to_utter = [val toString];
        if([val isInRange]){
            to_utter = [self formatValueLabelForSpeaking:to_utter];
        }
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:to_utter];
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            // In iOS 9 and later, speech is Gump slow, need different settings
            utterance.rate = .55;
        } else {
            utterance.rate = .15;
        }
        AVSpeechSynthesizer *synth = [[AVSpeechSynthesizer alloc] init];
        [synth speakUtterance:utterance];
        _cooldown_active = YES;
        [GCD asyncMain:^{
            _cooldown_timer=[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(clearCooldown) userInfo:nil repeats:NO];
        }];
        return true;
    }
    return false;
}
-(void)clearCooldown {
    _cooldown_active=false;
}
@end