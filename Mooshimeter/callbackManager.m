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
