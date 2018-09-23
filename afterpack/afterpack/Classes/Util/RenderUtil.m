//
//  RenderUtil.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/23.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "RenderUtil.h"
#import "BundleChecker.h"

@implementation RenderUtil

+ (NSString *)renderHtmlWithInfo: (NSDictionary *)packageInfo checkResult:(NSArray<BundleCheckpointRecord *> *) recordList {
    
    int passCount = 0;
    for (BundleCheckpointRecord *record in recordList) {
        if(record.success) {
            passCount ++;
        }
    }
    NSMutableString *html = [NSMutableString string];
    [html appendString:@"<html>\n"];
    [html appendString:@"<head>\n"];
    [html appendString:@"\t<style type='text/css'>\n"];
    [html appendString:@"\t\t#title {color: #42BD56;text-align: center;}\n"];
    [html appendString:@"\t\t#result {text-align: center;font-weight: bold;}\n"];
    [html appendString:@"\t\t.checkpoint {color: #42BD56;margin-left: 16px;}\n"];
    [html appendString:@"\t\t.message {background-color: #f5f5f5;margin: 20px;padding: 10px;}\n"];
    [html appendString:@"\t\ta {color: #42BD56;text-decoration: none;}\n"];
    [html appendString:@"\t\t#footer {margin-top: 30px;text-align: center;font-weight: bold;}\n"];
    [html appendString:@"\t</style>\n"];
    [html appendString:@"</head>\n"];
    [html appendString:@"<body>\n"];
    NSString *name = packageInfo[@"name"];
    [html appendFormat:@"\t<h1 id='title'>%@ Report</h1>\n",name];
    //final result
    if(passCount == (int)recordList.count) {
        [html appendFormat:@"\t<h2 id='result'>🎉 all pass!</h2>\n"];
    }else {
        [html appendFormat:@"\t<h2 id='result'>%d ✅&nbsp&nbsp%d ❌</h2>\n",passCount,(int)recordList.count-passCount];
    }
    //detail
    for (int i=0; i<recordList.count;i++) {
        BundleCheckpointRecord *record = recordList[i];
        BundleCheckpoint *checkpoint = record.checkpoint;
        id<BundleCheckPointProtocol> clazz = (id<BundleCheckPointProtocol>)[checkpoint class];
        NSMutableString *checkpointTitle = [NSMutableString string];
        NSString *checkpointName = [clazz name];
        [checkpointTitle appendFormat:@"%@ ",checkpointName];
        NSArray<BundleCheckpointOption *> *options = record.options;
        if(options.count > 0) {
            [checkpointTitle appendFormat:@"( "];
            for (int i=0;i<options.count;i++) {
                BundleCheckpointOption *option = options[i];
                [checkpointTitle appendFormat:@"%@: %@",option.defination.name,option.value];
                if(i<options.count-1) {
                    [checkpointTitle appendString:@" , "];
                }
            }
            [checkpointTitle appendFormat:@" )"];
        }
        [checkpointTitle appendFormat:@" %@",record.success ? @"✅" : @"❌"];
        [html appendFormat:@"\t<h3 class='checkpoint'>%@</h3>\n",checkpointTitle];
        if(record.html) {
            [html appendFormat:@"\t<div class='message'>\n"];
            [html appendFormat:@"\t\t%@\n",record.html];
            [html appendFormat:@"\t</div>\n"];
        }else if(record.message) {
            NSString *message = [record.message stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>\n\t\t"];
            [html appendFormat:@"\t<div class='message'>\n"];
            [html appendFormat:@"\t\t%@\n",message];
            [html appendFormat:@"\t</div>\n"];
        }
    }
    //footer
    [html appendString:@"\t<div id='footer'>"];
    NSString *appName = [[BundleChecker sharedChecker] appName];
    NSString *homePage = [[BundleChecker sharedChecker] homePage];
    [html appendFormat:@"\t\tCreated by: <a href='%@'>%@</a> ",homePage,appName];
    //authors
    NSMutableArray *authors = [NSMutableArray array];
    NSMutableArray *authorLinks = [NSMutableArray array];
    for (int i=0; i<recordList.count;i++) {
        BundleCheckpointRecord *record = recordList[i];
        BundleCheckpoint *checkpoint = record.checkpoint;
        id<BundleCheckPointProtocol> clazz = (id<BundleCheckPointProtocol>)[checkpoint class];
        NSDictionary *authorData = [clazz author];
        NSString * name = authorData[kBundleCheckpointAuthorName];
        NSString * link = authorData[kBundleCheckpointAuthorLink];
        if(name.length > 0) {
            BOOL exists = NO;
            for (NSString *author in authors) {
                if([author isEqualToString:name]) {
                    exists = YES;
                    break;
                }
            }
            if(!exists) {
                [authors addObject:name];
                [authorLinks addObject:link?:@""];
            }
        }
    }
    if(authors.count > 0) {
        [html appendFormat:@"Authors: "];
        for (int i=0;i<authors.count;i++) {
            NSString *author = authors[i];
            NSString *link = authorLinks[i];
            [html appendFormat:@"<a href='%@'>%@</a>",link,author];
            if(i < authors.count-1) {
                [html appendFormat:@", "];
            }
        }
    }
    NSString *date = packageInfo[@"date"];
    [html appendFormat:@" %@\n",date];
    [html appendString:@"\t</div>"];
    [html appendString:@"\t<br/><br/>"];
    [html appendString:@"</body>\n"];
    [html appendString:@"</html>"];
    return html;
}

@end
