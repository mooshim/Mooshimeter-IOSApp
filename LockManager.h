//
//  LockManager.h
//  Mooshimeter
//
//  Created by James Whong on 11/10/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LockManager : NSObject

@property (strong,atomic)   NSMutableDictionary *locks;

-(instancetype) init;
-(void) createLock:(NSString*)name;
-(BOOL) waitOnLock:(NSString*)name timeout:(NSTimeInterval)timeout;
-(void) signalLock:(NSString*)name;
-(void) releaseLock:(NSString*)name;


@end
