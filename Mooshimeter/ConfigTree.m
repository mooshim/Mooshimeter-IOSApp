//
// Created by James Whong on 5/26/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "ConfigTree.h"
#import "CRC32.h"
#import "NSMutableData+ByteBuffer.h"
#import "NSData+zlib.h"
#import "GCD.h"

@interface NSMutableDictionary(SubscriptExtension)
@end
@implementation NSMutableDictionary(SubscriptExtension)
-(id)objectAtIndexedSubscript:(NSUInteger)subscript {
    return [self objectForKey:[NSNumber numberWithInt:subscript]];
}
-(void)setObject:(id)object atIndexedSubscript:(NSUInteger)subscript {
    [self setObject:object forKey:[NSNumber numberWithInt:subscript]];
}
@end

@implementation ConfigTree {

}
//////////////////////
// STATICS
//////////////////////
typedef void(^NodeProcessor)(ConfigNode*);

////////////////////////////////
// NOTIFICATION CALLBACKS
////////////////////////////////

-(void)interpretAggregate {
    int expecting_bytes;
    int starting_bytes;
    while(_recv_buf.length>0) {
        NSMutableData *b = [_recv_buf mutableCopy];
        starting_bytes = [_recv_buf length];
        @try {
            int opcode = [b popUint8];
            if(self.code_list[opcode]!=nil) {
                ConfigNode *n = _code_list[opcode];
                NSString *s;
                switch(n.ntype) {
                    case NTYPE_PLAIN  :
                        NSLog(@"Shouldn't receive notification here!");
                        return;
                    case NTYPE_CHOOSER:
                        [n notify:[NSNumber numberWithInt:[b popUint8]]];
                        break;
                    case NTYPE_LINK   :
                        NSLog(@"Shouldn't receive notification here!");
                        return;
                    case NTYPE_VAL_U8 :
                    case NTYPE_VAL_S8 :
                        [n notify:[NSNumber numberWithInt:[b popUint8]]];
                        break;
                    case NTYPE_VAL_U16:
                    case NTYPE_VAL_S16:
                        [n notify:[NSNumber numberWithInt:[b popShort]]];
                        break;
                    case NTYPE_VAL_U32:
                    case NTYPE_VAL_S32:
                        [n notify:[NSNumber numberWithInt:[b popInt]]];
                        break;
                    case NTYPE_VAL_STR:
                        expecting_bytes = [b popShort];
                        if(b.length<expecting_bytes) {
                            // Wait for the aggregator to fill up more
                            return;
                        }
                        s = [[NSString alloc] initWithData:[b pop:expecting_bytes] encoding:NSASCIIStringEncoding];
                        [n notify:s];
                        break;
                    case NTYPE_VAL_BIN:
                        expecting_bytes = [b popShort];
                        if(b.length<expecting_bytes) {
                            // Wait for the aggregator to fill up more
                            return;
                        }
                        [n notify:[b pop:expecting_bytes]];
                        break;
                    case NTYPE_VAL_FLT:
                        [n notify:[NSNumber numberWithFloat:[b popFloat]]];
                        break;
                }
            } else {
                NSLog(@"UNRECOGNIZED SHORTCODE %d",opcode);
                // This puts us in an awkward position.  Since we don't recognize
                // the shortcode, we don't know how far to advance the buffer.
                // Just clear it and hope for the best... FIXME
                [_recv_buf pop:_recv_buf.length];
                return;
            }
        }
        @catch(NSException *e) {
            if([e.name isEqualToString:@"NSRangeException"]) {
                // This is an underflow exception and perfectly normal.
            } else {
                NSLog(@"Exception caught");
                NSLog(@"%@",e);
            }
            return;
        }
        // Advance recv_buf
        int consumed = starting_bytes - b.length;
        [_recv_buf pop:consumed];
    }
}

//////////////////////
// Methods for interacting with remote device
//////////////////////

-(void)attach:(MooshimeterDevice*)meter{
    _meter = meter;
    LGCharacteristic* c = [_meter getLGChar:METER_SEROUT];
    [c setNotifyValueBlocking:YES onUpdate:serout_callback];
    NSLog(@"Registered serout callback");
    // Load the tree from the remote device
    // This call should block until we receive the value
    [self command:@"ADMIN:TREE"];

    // Send the CRC to the remote side to tell them we understand their language and are ready to talk
    NSNumber* crc_obj = (NSNumber*)[self getNode:@"ADMIN:CRC32"].value;
    uint32_t crc = [crc_obj unsignedIntValue];
    if(crc==0) {
        NSLog(@"Something went wrong with the config tree download");
        return;
    }
    NSMutableString* crc_cmd = [@"ADMIN:CRC32 " mutableCopy];
    [crc_cmd appendFormat:@"%u",crc];
    [self command:crc_cmd];
    // Let's read it back now just for double checking
    [self command:@"ADMIN:CRC32"];

}

-(void)sendBytes:(NSData*)payload {
    if(![self.meter isConnected]) {
        NSLog(@"Trying to talk to a disconnected meter");
        return;
    }
    if (payload.length > 19) {
        NSLog(@"Payload too long!");
        return;
    }
    NSMutableData* wrapped_payload = [NSMutableData dataWithCapacity:20];
    [wrapped_payload appendBytes:&_send_seq_n length:1]; // Sequence number, for keeping track of which packet is which
    [wrapped_payload appendData:payload];                // Payload data
    uint8 bind_seqn = _send_seq_n;
    _send_seq_n++;
    LGCharacteristic *c = [self.meter getLGChar:METER_SERIN];
    [c writeValue:wrapped_payload completion:^(NSError *error) {
        if(error) {
            NSLog(@"Badness on send");
        } else {
            NSLog(@"SENT: %u %u bytes",bind_seqn,wrapped_payload.length);
        }
    }];
}

//////////////////////
// Methods
//////////////////////

// Callback triggered by sample received
void (^serout_callback)(NSData*,NSError*);

-(instancetype)init {
    self = [super init];
    _recv_buf = [NSMutableData data];
    // Always assume a tree starts with this configuration
    _root = [[ConfigNode alloc] init:self ntype_arg:NTYPE_PLAIN name_arg:@"" children_arg:@[
            [[ConfigNode alloc] init:self ntype_arg:NTYPE_PLAIN name_arg:@"ADMIN" children_arg:@[
                    [[ConfigNode alloc] init:self ntype_arg:NTYPE_VAL_U32 name_arg:@"CRC32" children_arg:@[]],
                    [[ConfigNode alloc] init:self ntype_arg:NTYPE_VAL_BIN name_arg:@"TREE" children_arg:@[]],
                    [[ConfigNode alloc] init:self ntype_arg:NTYPE_VAL_STR name_arg:@"DIAGNOSTIC" children_arg:@[]],
            ]],
    ]];
    [self assignShortCodes];
    _code_list = [[self getShortCodeMap] mutableCopy];

    serout_callback = ^(NSData* payload,NSError* error) {
        NSMutableData *mutable = [payload mutableCopy];
        uint8_t seq_n = [mutable popUint8];
        if(seq_n != (_recv_seq_n+1) && seq_n!=0) {
            NSLog(@"OUT OF ORDER PACKET");
            NSLog(@"EXPECTED: %d",((_recv_seq_n+1)));
            NSLog(@"GOT:      %d",(seq_n));
        } else {
            NSLog(@"RECV: %d %d bytes",seq_n,payload.length);
        }
        _recv_seq_n = seq_n;
        // Append to aggregate buffer
        [self.recv_buf appendData:mutable];
        [self interpretAggregate];
    };

    ConfigNode *tree_bin = [self getNode:@"ADMIN:TREE"];
    [tree_bin addNotifyHandler:^(NSObject *payload) {
        @try {
            // This will replace all the internal members of the tree!
            NSData* pdata = (NSData*)payload;
            [self unpackRaw:pdata];
            _code_list = [self getShortCodeMap];
            [self enumerate];
            uint32_t crc = [pdata crc32];
            NSLog(@"CALC CRC: %0X",crc);
            [self getNode:@"ADMIN:CRC32"].value = [NSNumber numberWithInt:crc];
        }
        @catch (NSException * e) {
            NSLog(@"%@",e);
        }
    }];
    return self;
}

-(NSString*)enumerate:(ConfigNode*)n indent:(NSString*)indent aggregate:(NSMutableString*)aggregate {
    NSString* newline = [NSString stringWithFormat:@"%@%@\n",indent, [n toString]];
    NSLog(newline);
    [aggregate appendString:newline];
    indent = [indent stringByAppendingString:@"  "];
    for(ConfigNode *c in n.children) {
        [self enumerate:c indent:indent aggregate:aggregate];
    }
    return aggregate;
}
-(NSString*)enumerate:(ConfigNode*)n {
    return [self enumerate:n indent:@"" aggregate:[@"" mutableCopy]];
}
-(NSString*)enumerate {
    return [self enumerate:_root];
}
-(int)addNotifyHandler:(NSString*)node_name handler:(NotifyHandler)h {
    ConfigNode *n = [self getNode:node_name];
    if(n==nil) {
        return -1;
    }
    [n addNotifyHandler:h];
    return 0;
}
-(ConfigNode*)unpack:(NSMutableData*)b {
    int ntype = [b popUint8];
    int nlen  = [b popUint8];
    NSString* name = [[NSString alloc] initWithData:[b pop:nlen] encoding:NSASCIIStringEncoding];
    int n_children = [b popUint8];
    NSMutableArray<ConfigNode *>*clist = [@[] mutableCopy];
    for(int i = 0; i < n_children; i++) {
        [clist addObject:[self unpack:b]];
    }
    return [[ConfigNode alloc] init:self ntype_arg:ntype name_arg:name children_arg:clist];
}

-(void)unpackRaw:(NSData*)compressed {
    // Sanity check
    NSError * error;
    NSMutableData *uncompressed = [[compressed bbs_dataByInflatingWithError:&error] mutableCopy];
    NSLog(@"Inflated from %d bytes to %d bytes", compressed.length, uncompressed.length);
    _root = [self unpack:uncompressed];
    [self assignShortCodes];
}

+(void)walkRecursive:(ConfigNode*)node processor:(NodeProcessor)p {
    p(node);
    for(ConfigNode* c in node.children) {
        [ConfigTree walkRecursive:c processor:p];
    }
}
-(void)walk:(NodeProcessor)p {
    [ConfigTree walkRecursive:_root processor:p];
}

-(void)assignShortCodes {
    NSMutableArray * g_code = [@[@0] mutableCopy];
    NodeProcessor p = ^(ConfigNode*n){
        n.tree = self;
        if(n.children!=nil) {
            for(ConfigNode *c in n.children) {
                c.parent=n;
            }
        }
        if([n needsShortCode]) {
            int code = [g_code[0] intValue];
            n.code = code;
            code++;
            g_code[0] = [NSNumber numberWithInt:code];
        }
    };
    [self walk:p];
}
-(ConfigNode*) getNode:(NSString*)name {
    NSArray<NSString*>*tokens = [name componentsSeparatedByString:@":"];
    ConfigNode* n = _root;
    for(NSString* t in tokens) {
        n = [n getChild:t];
        if(n==nil) {
            // Not found!
            return nil;
        }
    }
    return n;
}
-(NSObject*)getValueAt:(NSString*)name {
    ConfigNode *n = [self getNode:name];
    if(n==nil) {
        return nil;
    }
    return n.value;
}
-(ConfigNode*)getChosenNode:(NSString*)name {
    ConfigNode *n = [self getNode:name];
    if(n.value == nil) {
        // FIXME: Assume always initialized to zero!
        n.value = @0;
    }
    ConfigNode *rval = [n getChosen];
    // Follow link
    if(rval.ntype==NTYPE_LINK) {
        return [self getNode:(NSString*)rval.value];
    } else {
        return rval;
    }
}
-(NSString*)getChosenName:(NSString*)name {
    return [self getChosenNode:name].name;
}
-(NSMutableDictionary<NSNumber*,ConfigNode*>*) getShortCodeMap {
    //NSMutableDictionary<NSNumber*,ConfigNode*>* rval = [@{} mutableCopy];
    NSMutableDictionary* rval = [@{} mutableCopy];
    NodeProcessor p = ^(ConfigNode * n) {
        if(n.code != -1) {
            rval[n.code] = n;
        }
    };
    [self walk:p];
    return rval;
}

-(void)command:(NSString*)cmd {
    NSLog(@"CMD: %@",cmd);
    // cmd might contain a payload, in which case split it out
    NSArray<NSString *> *tokens = [cmd componentsSeparatedByString:@" "];
    if(tokens.count>2){
        NSLog(@"More than two tokens in a command string!  What?");
    }
    NSString* node_str = tokens[0];
    NSString* payload_str;
    if(tokens.count==2) {
        payload_str = tokens[1];
    } else {
        payload_str = nil;
    }
    node_str = [node_str uppercaseString];
    ConfigNode *node = [self getNode:node_str];
    if(node==nil) {
        NSLog(@"Node not found at %@", node_str);
        return;
    }
    if (payload_str != nil) {
        NSObject *val = [node parseValueString:payload_str];
        [node sendValue:val blocking:YES];
    } else {
        [node reqValue];
    }
}

-(void)refreshAll {
    // Shortcodes are guaranteed to be consecutive
    int n_codes = _code_list.count;
    // Set up a semaphore so we can refresh all these values concurrently, saves time
    dispatch_semaphore_t s = dispatch_semaphore_create(0);
    // Skip the first 3 codes (they are for CRC, tree and diagnostic
    for(int i = 3; i < n_codes; i++) {
        ConfigNode *n = _code_list[i];
        if(   n.ntype != NTYPE_VAL_BIN ) {
            [GCD asyncBack:^{
                [n reqValue];
                dispatch_semaphore_signal(s);
            }];
        } else {
            dispatch_semaphore_signal(s);
        }
        //if(![self.meter isConnected]) { return; } TODO find a way to add this check back in
    }
    for(int i = 3; i < n_codes; i++) {
        if(dispatch_semaphore_wait(s,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_MSEC*500))) {
            NSLog(@"Timeout refreshing tree!");
            return;
        }
    }
}

@end