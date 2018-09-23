//
//  main.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BundleChecker.h"
#import "ArgumentUtil.h"

int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        NSMutableArray *values = [NSMutableArray array];
        for (int i=1; i<argc; i++) {
            const char * arg = argv[i];
            NSString *value = [NSString stringWithUTF8String:arg];
            [values addObject:value];
        }
        NSArray<Action *> * actions = [ArgumentUtil parse:values];
        //validate actions
        NSString *message = nil;
        if(![ArgumentUtil validateActions:actions message:&message]) {
            printf("%s\n\n",[message UTF8String]);
            return -1;
        }
        
        NSString *bundlePath = nil;
        NSArray<Action *> *checkpointActions = nil;
        Action *pathAction = [actions lastObject];
        if(![pathAction hasOption]) {
            bundlePath = pathAction.name;
        }
        if(actions.count > 1) {
            checkpointActions = [actions subarrayWithRange:NSMakeRange(0, actions.count-1)];
        }
        NSArray<id<BundleCheckPointProtocol>> *checkpoints = nil;
        NSArray<id<BundleCheckPointProtocol>> *availableCheckpoints = [[BundleChecker sharedChecker] availableCheckpoints];
        if(checkpointActions.count > 0) {
            //user choosed checkpoints
            NSMutableArray<id<BundleCheckPointProtocol>> *choosedCheckpoints = [NSMutableArray array];
            for (Action *action in checkpointActions) {
                NSString *actionId = action.name;
                for (id<BundleCheckPointProtocol> checkpointClass in availableCheckpoints) {
                    NSString *checkId = [checkpointClass identifier];
                    if([actionId isEqualToString:checkId]) {
                        [choosedCheckpoints addObject:checkpointClass];
                        break;
                    }
                }
            }
            checkpoints = choosedCheckpoints;
        }else {
            //all checkpoints
            checkpoints = availableCheckpoints;
        }
        //filled with option values
        NSMutableArray *checkpointIds = [NSMutableArray array];
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        for (int i=0;i<checkpoints.count;i++) {
            id<BundleCheckPointProtocol> checkpoint = checkpoints[i];
            NSString *checkId = [checkpoint identifier];
            Action * thisAction = nil;
            if(checkpointActions.count > 0) {
                thisAction = checkpointActions[i];
            }
            NSArray<BundleCheckOptionDefinition *> *definitionList = [checkpoint optionList];
            NSMutableArray *optionList = [NSMutableArray array];
            for (BundleCheckOptionDefinition *definition in definitionList) {
                BundleCheckpointOption *option = [[BundleCheckpointOption alloc] init];
                option.defination = definition;
                NSString *value = definition.defaultValue;
                if(thisAction) {
                    NSString *optionValue = thisAction.options[definition.key];
                    if(optionValue) {
                        value = optionValue;
                    }
                }
                option.value = value;
                [optionList addObject:option];
            }
            options[checkId] = optionList;
            [checkpointIds addObject:checkId];
        }
        [[BundleChecker sharedChecker] runWithCheckpoints:checkpointIds options:options bundlePath:bundlePath];
    }
    return 0;
}


