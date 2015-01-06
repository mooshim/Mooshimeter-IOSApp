//
//  callbackManager.h
//  Mooshimeter
//
//  Created by James Whong on 11/3/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface callbackManager : NSObject

@property (strong,nonatomic)   NSMutableDictionary *cbs;

-(callbackManager*) init;

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb;

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb arg:(id)arg;

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb arg:(id)arg oneshot:(BOOL)oneshot;

-(void) clearCB:(NSString*)key;

-(void) callCB:(NSString*)key;

-(BOOL) checkCB:(NSString*)key;

@end
