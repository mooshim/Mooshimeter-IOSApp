//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MeterReading.h"

@implementation MeterReading
-(MeterReading*)initWithValue:(float)value_arg n_digits_arg:(int)n_digits_arg max_arg:(float)max_arg units_arg:(NSString*)units_arg {
    self = [super init];
    self.value    = value_arg;
    self.n_digits =n_digits_arg;
    self.max      = max_arg;
    self.units    = units_arg;

    if(self.max == 0) {
        // Formatting code will break if max is 0
        self.max = 1;
    }

    int high = (int)log10(self.max);
    self.format_mult = 1;
    self.format_prefix = 3;

    while(high > 3) {
        self.format_prefix++;
        high -= 3;
        self.format_mult /= 1000;
    }
    while(high <= 0) {
        self.format_prefix--;
        high += 3;
        self.format_mult *= 1000;
    }

    self.format = [NSString stringWithFormat:@"%%0%d.%df", high, self.n_digits-high];
    return self;
}

    ////////////////////////////////
    // Convenience functions
    ////////////////////////////////
    -(NSString*) toString {
        if(self.max==0) {
            return self.units;
        }

        static NSString* prefixes[] = {@"n",@"\u03bc",@"m",@"",@"k",@"M",@"G"};
        float lval = self.value;
        if(fabs(lval) > 1.2*self.max) {
            return @"OUT OF RANGE";
        }
        NSMutableString* rval = [[NSMutableString alloc] init];
        if(lval>=0) {
            [rval appendString:@" "]; // Space for neg sign
        }
        [rval appendString:[NSString stringWithFormat:self.format, lval*self.format_mult]];
        [rval appendString:prefixes[self.format_prefix]];
        [rval appendString:self.units];
        return rval;
    }

    +(MeterReading*) mult:(MeterReading*)m0 m1:(MeterReading*)m1 {
        MeterReading* rval = [[MeterReading alloc] initWithValue:(m0.value*m1.value)
                                       n_digits_arg:((m0.n_digits+m1.n_digits)/2)
                                            max_arg:(m0.max*m1.max)
                                          units_arg:[m0.units stringByAppendingString:m1.units]
        ];
        if([rval.units isEqualToString:@"AV"]) {
            rval.units = @"W";
        }
        return rval;
    }
@end