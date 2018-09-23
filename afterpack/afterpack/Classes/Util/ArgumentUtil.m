//
//  ArgumentUtil.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/22.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "ArgumentUtil.h"
#import "BundleChecker.h"
#import "FileUtil.h"

@interface Argument : NSObject

+ (instancetype)arg;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *value;

//only value
- (BOOL)isAction;
//name and value(may be nil)
- (BOOL)isOption;

@end

@implementation Argument

+ (instancetype)arg {
    return [[Argument alloc] init];
}

//only value
- (BOOL)isAction {
    return (self.name.length == 0 && self.value.length > 0);
}

//name and value(may be nil)
- (BOOL)isOption {
    return (self.name.length > 0);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %@",self.name?:@"",self.value?:@""];
}

@end



@implementation Action

+ (instancetype)action {
    return [[Action alloc] init];
}

- (BOOL)hasOption {
    return (self.options.count > 0);
}

@end

@implementation ArgumentUtil

+ (NSArray<Action *> *)parse: (NSArray *)values {
    int index = 0;
    int count = (int)values.count;
    NSMutableArray *args = [NSMutableArray array];
    while (index < count) {
        NSString *val = values[index];
        if([val hasPrefix:@"-"]) {
            if(val.length > 1) {
                //key
                Argument *arg = [Argument arg];
                arg.name = [val substringFromIndex:1];
                int nextIndex = index+1;
                if(nextIndex < count) {
                    NSString *nextVal = values[nextIndex];
                    if(![nextVal hasPrefix:@"-"]) {
                        arg.value = nextVal;
                        index ++;
                    }else {
                        arg.value = nil;
                    }
                    [args addObject:arg];
                }else {
                    [args addObject:arg];
                }
            }
        }else {
            Argument *arg = [Argument arg];
            arg.value = val;
            [args addObject:arg];
        }
        index ++;
    }
    
    int argIndex = 0;
    int argCount = (int)args.count;
    NSMutableArray *actions = [NSMutableArray array];
    while (argIndex < argCount) {
        Action * action = [Action action];
        Argument *arg = args[argIndex];
        if([arg isAction]) {
            action.name = arg.value;
            //find its options
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            int nextIndex = argIndex + 1;
            while (nextIndex < argCount) {
                Argument *nextArg = args[nextIndex];
                if([nextArg isOption]) {
                    options[nextArg.name] = nextArg.value?:@"";
                    argIndex ++;
                }else {
                    break;
                }
                nextIndex ++;
            }
            if(options.count > 0) {
                action.options = options;
            }
            [actions addObject:action];
        }
        argIndex ++;
    }
    return actions;
}


+ (BOOL)validateActions: (NSArray<Action *> *)actions message: (NSString **)message {
    BOOL pass = NO;
    do {
        //check bundle path
        NSString *bundlePath = nil;
        if(actions.count > 0) {
            Action *pathAction = [actions lastObject];
            if(![pathAction hasOption]) {
                bundlePath = pathAction.name;
            }
        }
        if(bundlePath.length == 0) {
            *message = @"bundle path is required";
            break;
        }
        NSString *extension = [[bundlePath pathExtension] lowercaseString];
        if([extension isEqualToString:@"app"]) {
            if(![FileUtil dirExistsAtPath:bundlePath]) {
                *message = [NSString stringWithFormat:@"file not exists at %@",bundlePath];
                break;
            }
        }else if([extension isEqualToString:@"ipa"]) {
            if(![FileUtil fileExistsAtPath:bundlePath]) {
                *message = [NSString stringWithFormat:@"file not exists at %@",bundlePath];
                break;
            }
        }else {
            *message = [NSString stringWithFormat:@"bundle file should be .app or .ipa"];
            break;
        }
        
        //check action match checkpoint
        if(actions.count > 1) {
            NSArray *checkpointActions = [actions subarrayWithRange:NSMakeRange(0, actions.count-1)];
            NSArray<id<BundleCheckPointProtocol>> *checkpointClasses = [[BundleChecker sharedChecker] availableCheckpoints];
            NSMutableArray *unmatchedActionNames = [NSMutableArray array];
            for (Action *action in checkpointActions) {
                NSString *actionId = action.name;
                BOOL match = NO;
                for (id<BundleCheckPointProtocol> checkpointClass in checkpointClasses) {
                    NSString *checkId = [checkpointClass identifier];
                    if([actionId isEqualToString:checkId]) {
                        match = YES;
                        break;
                    }
                }
                if(!match) {
                    [unmatchedActionNames addObject:action.name];
                }
            }
            if(unmatchedActionNames.count > 0) {
                *message = [NSString stringWithFormat:@"checkpoint: %@ not found",[unmatchedActionNames componentsJoinedByString:@","]];
                break;
            }
            //option value check
            BOOL optionPass = YES;
            for (Action *action in checkpointActions) {
                NSString *actionId = action.name;
                id<BundleCheckPointProtocol> checkpoint = nil;
                for (id<BundleCheckPointProtocol> checkpointClass in checkpointClasses) {
                    NSString *checkId = [checkpointClass identifier];
                    if([actionId isEqualToString:checkId]) {
                        checkpoint = checkpointClass;
                        break;
                    }
                }
                NSDictionary *options = action.options;
                __block BOOL thisPass = YES;
                NSArray *optionKeys = [options allKeys];
                for (NSString *key in optionKeys) {
                    NSString *value = options[key];
                    if(![checkpoint validateOptionValue:key value:value]) {
                        optionPass = NO;
                        BundleCheckOptionDefinition *theDefinition = nil;
                        NSArray<BundleCheckOptionDefinition *> *definitionList = [checkpoint optionList];
                        for (BundleCheckOptionDefinition *definition in definitionList) {
                            if([definition.key isEqualToString:key]) {
                                theDefinition = definition;
                                break;
                            }
                        }
                        NSString *tips = nil;
                        if(theDefinition.tip) {
                            tips = [NSString stringWithFormat:@"%@",theDefinition.tip];
                        }
                        *message = [NSString stringWithFormat:@"%@'s option value was invalid ( %@: %@ ) ➡️ %@",action.name,key,value,tips?:@""];
                        break;
                    }
                }
                if(!thisPass) {
                    optionPass = NO;
                    break;
                }
            }
            if(!optionPass) {
                break;
            }
        }
        pass = YES;
    } while (0);
    return pass;
    
}

@end

