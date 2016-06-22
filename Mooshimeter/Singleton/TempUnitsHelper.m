//
// Created by James Whong on 6/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "TempUnitsHelper.h"

typedef struct {
    double coeff[10];
    double low;
    double high;
}coeff_t;

const coeff_t K_coeff = {
        {0.0,
        2.508355e-2,
        7.860106e-8,
        -2.503131e-10,
        8.315270e-14,
        -1.228034e-17,
        9.804036e-22,
        -4.413030e-26,
        1.057734e-30,
        -1.052755e-35,},
        0,
        500,};

@implementation TempUnitsHelper

// All coefficients from Omega's datasheet:
// ITS-90 Thermocouple Direct and Inverse Polynomials
// https://www.omega.com/temperature/Z/pdf/z198-201.pdf




+(float)absK2C:(float)K {
    return (float) (K-273.15);
}
+(float)absK2F:(float)K {
    return (float) ((K - 273.15)* 1.8000 + 32.00);
}
+(float)absC2F:(float)C {
    return (float) ((C)* 1.8000 + 32.00);
}
+(float)relK2F:(float)C {
    return (float) ((C)* 1.8000);
}

+(double)applyPolyCoeff:(float)v coeff:(coeff_t)coeff {
    double uv = v*1e6;
    double out = 0.0;
    for(int n = 0; n < 10; n++) {
        out += coeff.coeff[n]*pow(uv,n);
    }
    if(out > coeff.high || out < coeff.low) {
        NSLog(@"Warning - using a temperature polynomial outside of it's recommended temp range");
    }
    return out;
}
+(float)KThermoVoltsToDegC:(float)v {
    return [TempUnitsHelper applyPolyCoeff:v coeff:K_coeff];
}


@end