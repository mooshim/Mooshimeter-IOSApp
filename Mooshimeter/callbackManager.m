//
//  callbackManager.m
//  Mooshimeter
//
//  Created by James Whong on 11/3/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import "callbackManager.h"

@implementation callbackManager

-(callbackManager*) init {
    self = [super init];
    self.cbs = [[NSMutableDictionary alloc] init];
    return self;
}

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb {
    [self createCB:key target:target cb:cb arg:[NSNull null]];
}

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:key target:target cb:cb arg:arg oneshot:YES];
}

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb arg:(id)arg oneshot:(BOOL)oneshot {
    NSLog(@"Creating cb %@", key);
    if( target == nil ) {
        return;
    }
    if( arg == nil ) {
        arg = [NSNull null];
    }
    NSArray* val = [NSArray arrayWithObjects:target, [NSValue valueWithPointer:cb], arg, [NSNumber numberWithBool:oneshot], nil];
    [self.cbs setObject:val forKey:key];
}

-(void) clearCB:(NSString*)key {
    [self.cbs removeObjectForKey:key];
}

-(void) callCB:(NSString*)key {
    NSArray *val = [self.cbs objectForKey:key];
    NSLog(@"Calling %@", key);
    if( val == nil ) {
        NSLog(@"No callback registered for %@!", key);
        return;
    }
    id target  = [val objectAtIndex:0];
    NSValue* cb_wrap = [val objectAtIndex:1];
    id arg = [val objectAtIndex:2];
    BOOL oneshot = [[val objectAtIndex:3] boolValue];
    SEL cb = [cb_wrap pointerValue];
    
    if(oneshot) {
        [self.cbs removeObjectForKey:key];
    }
    
    if( [target respondsToSelector:cb] ) {
        if( arg == [NSNull null] ) {
            [target performSelector:cb];
        } else {
            [target performSelector:cb withObject:arg];
        }
    } else {
        NSLog(@"Target does not respond to selector!");
    }
}

-(BOOL) checkCB:(NSString*)key {
    NSArray *val = [self.cbs objectForKey:key];
    return val != nil;
}

@end
