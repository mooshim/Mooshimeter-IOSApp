//
// Created by James Whong on 5/26/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigTree.h"

@class ConfigTree;

enum NTYPE {
    NTYPE_PLAIN   =0 , // May be an informational node, or a choice in a chooser
    NTYPE_LINK    =1 , // A link to somewhere else in the tree
    NTYPE_CHOOSER =2 , // The children of a CHOOSER can only be selected by one CHOOSER, and a CHOOSER can only select one child
    NTYPE_VAL_U8  =3 , // These nodes have readable and writable values of the type specified
    NTYPE_VAL_U16 =4 , // These nodes have readable and writable values of the type specified
    NTYPE_VAL_U32 =5 , // These nodes have readable and writable values of the type specified
    NTYPE_VAL_S8  =6 , // These nodes have readable and writable values of the type specified
    NTYPE_VAL_S16 =7 , // These nodes have readable and writable values of the type specified
    NTYPE_VAL_S32 =8 , // These nodes have readable and writable values of the type specified
    NTYPE_VAL_STR =9 , // These nodes have readable and writable values of the type specified
    NTYPE_VAL_BIN =10, // These nodes have readable and writable values of the type specified
    NTYPE_VAL_FLT =11, // These nodes have readable and writable values of the type specified
    NTYPE_NOTSET  =-1  // May be an informational node, or a choice in a chooser
};

typedef void(^NotifyHandler)(NSObject* payload);

@interface ConfigNode : NSObject

@property int8_t code;
@property int ntype;
@property NSString* name;
@property NSMutableArray *children;
@property ConfigNode *parent ;
@property ConfigTree *tree   ;
@property NSMutableArray *notify_handlers;
@property (strong,atomic) NSObject *value;
@property NSString *cache_longname;

-(instancetype)init:(ConfigTree*)tree_arg ntype_arg:(int)ntype_arg name_arg:(NSString*)name_arg children_arg:(NSArray*)children_arg;

- (NSString *)toString;

-(void)addNotifyHandler:(NotifyHandler)h;
-(void)removeNotifyHandler:(NotifyHandler)h;
-(void)clearNotifyHandlers;
-(void)notify:(NSObject*)notification;

-(NSObject*)reqValue;
-(void)sendValue:(NSObject*)new_value blocking:(BOOL)blocking;

-(ConfigNode*)getChild:(NSString*)name_arg;

- (NSObject *)parseValueString:(NSString *)str;

-(ConfigNode*) getChosen;
-(BOOL)needsShortCode;
-(void)choose;
@end