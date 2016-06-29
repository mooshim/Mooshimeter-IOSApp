//
// Created by James Whong on 5/26/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "ConfigNode.h"
#import "Lock.h"

@implementation ConfigNode {
    Lock* lock;
}

-(instancetype)init:(ConfigTree*)tree_arg ntype_arg:(int)ntype_arg name_arg:(NSString*)name_arg children_arg:(NSArray*)children_arg {
    self = [super init];

    lock = [[Lock alloc]init];

    self.code = -1;
    self.ntype = NTYPE_NOTSET;
    self.name = @"";
    self.children = [@[] mutableCopy];
    self.parent = nil;
    self.tree   = nil;
    self.notify_handlers = [@[] mutableCopy];
    self.value = @0;
    self.cache_longname=nil;
    
    self.tree = tree_arg;
    self.ntype=ntype_arg;
    self.name=name_arg;
    if(children_arg!=nil){
        for(ConfigNode *c in children_arg) {
            [self.children addObject:c];
        }
    }
    return self;
}
-(NSString*)toString {
    NSMutableString* s = [NSMutableString string];
    if(self.code != -1) {
        [s appendFormat:@"%d",self.code];
        [s appendString:@":"];
        [s appendString:self.name];
    } else {
        [s appendString:self.name];
    }
    return s;
}
-(int)getIndex {
    return [self.parent.children indexOfObject:self];
}
-(void)getLongNameHelper:(NSMutableString*)rval sep:(NSString*)sep {
    // This is the recursive call
    if(self.parent!=nil) {
        [self.parent getLongNameHelper:rval sep:sep];
    }
    [rval appendString:self.name];
    [rval appendString:sep];
}
-(NSString*)getLongName:(NSString*)sep {
    if(self.cache_longname==nil) {
        NSMutableString* rval = [NSMutableString string];
        [self getLongNameHelper:rval sep:sep];
        // This will have an extra seperator on the end and beginning
        [rval deleteCharactersInRange:NSMakeRange(0,1)];
        [rval deleteCharactersInRange:NSMakeRange([rval length]-1,1)];
        self.cache_longname = [rval copy];
    }
    return self.cache_longname;
}
-(NSString*)getLongName { return [self getLongName:@":"]; }
-(ConfigNode*) getChosen {
    NSNumber* cast = (NSNumber*)self.value;
    ConfigNode* rval = self.children[[cast unsignedIntegerValue]];
    while(rval.ntype==NTYPE_LINK) {
        rval = [_tree getNode:rval.name];
    }
    return rval;
}
-(ConfigNode*)getChild:(NSString*)name_arg {
    for(ConfigNode *c in self.children) {
        if([c.name isEqualToString:name_arg]) {
            return c;
        }
    }
    return nil;
}
-(BOOL)needsShortCode { 
    return self.ntype>=NTYPE_CHOOSER;
}

//////////////////
// Helpers for interacting with remote device
//////////////////

-(NSObject*)parseValueString:(NSString*)str {
    switch (_ntype) {
        case NTYPE_PLAIN:
            return nil;
        case NTYPE_CHOOSER:
            return [NSNumber numberWithInt:[str intValue]];
        case NTYPE_LINK:
            return nil;
        case NTYPE_VAL_S8:
        case NTYPE_VAL_S16:
        case NTYPE_VAL_S32:
            return [NSNumber numberWithInt:[str intValue]];
        case NTYPE_VAL_U8:
        case NTYPE_VAL_U16:
        case NTYPE_VAL_U32:
            return [NSNumber numberWithUnsignedInt:strtoul([str UTF8String],NULL,0)];
        case NTYPE_VAL_STR:
            return str;
        case NTYPE_VAL_BIN:
            NSLog(@"Not implemented yet");
            return nil;
        case NTYPE_VAL_FLT:
            return [NSNumber numberWithFloat:[str floatValue]];
    }
    NSLog(@"Bad ntype!");
    return nil;
}
-(void) packToSerial:(NSMutableData*)b {
    // This will pack a read request in to the serial channel
    [b appendBytes:&_code length:1];
}
-(void) packToSerial:(NSMutableData*)b new_value:(NSObject*)new_value {
#define THIS_COMMAND_TAKES_NO_PAYLOAD @"THIS COMMAND TAKES NO PAYLOAD"
    // This will pack a write request with the new value
    // Signify a write
    uint8_t opcode = _code | (uint8_t)0x80;
    [b appendBytes:&opcode length:1];
    switch(_ntype) {
        case NTYPE_PLAIN:
            NSLog(THIS_COMMAND_TAKES_NO_PAYLOAD);
            break;
        case NTYPE_CHOOSER: {
            uint8_t v = [((NSNumber*)new_value) unsignedCharValue];
            [b appendBytes:&v length:1];
            } break;
        case NTYPE_LINK:
            NSLog(THIS_COMMAND_TAKES_NO_PAYLOAD);
            return;
        case NTYPE_VAL_U8:
        case NTYPE_VAL_S8:{
            int8_t v = [((NSNumber*)new_value) charValue];
            [b appendBytes:&v length:1];
        } break;
        case NTYPE_VAL_U16:
        case NTYPE_VAL_S16:{
            int16_t v = [((NSNumber*)new_value) shortValue];
            [b appendBytes:&v length:2];
        } break;
        case NTYPE_VAL_U32:
        case NTYPE_VAL_S32:{
            int32_t v = [((NSNumber*)new_value) intValue];
            [b appendBytes:&v length:4];
        } break;
        case NTYPE_VAL_STR: {
            NSString* cast = (NSString*)new_value;
            uint16_t l = (uint16_t)cast.length;
            [b appendBytes:&l length:2];
            [b appendBytes:[cast cString] length:l];
            } break;
        case NTYPE_VAL_BIN:
            NSLog(@ "Not implemented yet");
            break;
        case NTYPE_VAL_FLT:{
            float v = [((NSNumber*)new_value) floatValue];
            [b appendBytes:&v length:4];
        } break;
        default:
            NSLog(@"Unhandled node type!");
            break;
    }
}
-(void)choose {
    if(_parent.ntype==NTYPE_CHOOSER) {
        [_parent sendValue:[NSNumber numberWithInt:[self getIndex]] blocking:YES];
    }
}
-(NSObject*)reqValue {
    // Forces a refresh of the value at this node
    if(_code==-1) {
        NSLog(@"Requested value for a node with no shortcode!");
        return nil;
    }
    if(![self.tree.meter isConnected]) {
        NSLog(@"Trying to talk to a disconnected meter");
        return self.value;
    }
    [_tree sendBytes:[NSData dataWithBytes:&_code length:1]];
    [lock wait:2000];
    return self.value;
}
-(void)sendValue:(NSObject*)new_value blocking:(BOOL)blocking {
    if(![self.tree.meter isConnected]) {
        NSLog(@"Trying to talk to a disconnected meter");
        return;
    }
    NSMutableData * b = [NSMutableData data];
    [self packToSerial:b new_value:new_value];
    if(!blocking) {
        // Assume it will get through
        self.value = new_value;
    }
    [_tree sendBytes:b];
    if(blocking) {
        [lock wait:2000];
    }
}

//////////////////
// Notification helpers
//////////////////

-(void)addNotifyHandler:(NotifyHandler)h {
    if(h!=nil) {
        [self.notify_handlers addObject:h];
    }
}
-(void)removeNotifyHandler:(NotifyHandler)h {
    [self.notify_handlers removeObject:h];
}
-(void)clearNotifyHandlers {
    [self.notify_handlers removeAllObjects];
}
-(void)notify:(NSObject*)notification {
    NSLog(@"%@%@%@", [self getLongName],@":",notification);
    self.value = notification;
    for(NotifyHandler handler in _notify_handlers) {
        handler(notification);
    }
    [lock signal];
}
@end