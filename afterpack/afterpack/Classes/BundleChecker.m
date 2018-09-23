//
//  afterpack.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "BundleChecker.h"
#import "BundleInfo.h"
#import "AssetsUtil.h"
#import "FileUtil.h"
#import "CmdUtil.h"
#import <objc/runtime.h>
#import "RenderUtil.h"


@interface BundleChecker ()

@property (nonatomic, strong) NSString *bundlePath;

@property (nonatomic, strong) NSString *workBundlePath;
@property (nonatomic, strong) NSString *workDirectoryPath;

@property (nonatomic, strong) NSMutableArray<BundleCheckpointRecord *> *recordList;

@end

@implementation BundleChecker

+ (BundleChecker *)sharedChecker {
    static dispatch_once_t onceToken;
    static BundleChecker *sharedChecker = nil;
    dispatch_once(&onceToken, ^{
        sharedChecker = [[BundleChecker alloc] init];
    });
    return sharedChecker;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSArray<id<BundleCheckPointProtocol>> *)availableCheckpoints {
    NSMutableArray <id<BundleCheckPointProtocol>> *resultList = [NSMutableArray array];
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        Class *classes = NULL;
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (NSInteger classIndex = 0; classIndex < numClasses; ++classIndex) {
            Class class = classes[classIndex];
            if(class_getSuperclass(class) == [BundleCheckpoint class]) {
                [resultList addObject:(id)class];
            }
        }
        free(classes);
    }
    return resultList;
}

- (void)runWithCheckpoints: (NSArray<NSString *> *)checkpointIds
                   options: (NSDictionary<NSString *,NSArray<BundleCheckpointOption *> *> *)checkpointsOptions
                bundlePath: (NSString *)bundlePath
{
    NSString *workBundlePath = [self prepareWorkspace:bundlePath];
    BundleInfo *bundleInfo = [self loadBundleInfo:workBundlePath];
    //run checkpoints
    NSArray<id<BundleCheckPointProtocol>> *checkpointClasses = [self availableCheckpoints];
    int __block passCount = 0;
    for (NSString *checkpointId in checkpointIds) {
        id<BundleCheckPointProtocol> checkpointClass = nil;
        for (id<BundleCheckPointProtocol> clazz in checkpointClasses) {
            if([[clazz identifier] isEqualToString:checkpointId]) {
                checkpointClass = clazz;
                break;
            }
        }
        NSAssert(checkpointClass != nil, @"could not find the checkpoint");
        NSString *checkpointName = [checkpointClass name];
        BundleCheckpoint *checkpoint = [[(id)checkpointClass alloc] init];
        NSArray<BundleCheckpointOption *> *options = checkpointsOptions[checkpointId];
        NSMutableDictionary *optionValues = [NSMutableDictionary dictionary];
        NSMutableString *beforeCheck = [NSMutableString string];
        [beforeCheck appendFormat:@"🔍 %@ ",checkpointName];
        if(options.count > 0) {
            [beforeCheck appendFormat:@"( "];
            for (int i=0;i<options.count;i++) {
                BundleCheckpointOption *option = options[i];
                optionValues[option.defination.key] = option;
                [beforeCheck appendFormat:@"%@: %@",option.defination.name,option.value];
                if(i<options.count-1) {
                    [beforeCheck appendString:@" , "];
                }
            }
            [beforeCheck appendFormat:@" )"];
        }
        printf("%s ",[beforeCheck UTF8String]);
        BundleCheckpointRecord * record = [[BundleCheckpointRecord alloc] init];
        record.checkpoint = checkpoint;
        record.options = options;
        [self.recordList addObject:record];
        //sync
        [checkpoint runWithBundleInfo:bundleInfo options:optionValues onCompletion:^(BOOL pass, NSString *message, NSString *html) {
            if(pass) {
                printf("✅\n");
                passCount ++;
            }else {
                printf("❌\n");
                printf("%s\n",[message UTF8String]);
            }
            record.success = pass;
            record.message = message;
            record.html = html;
        }];
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if(passCount == checkpointIds.count) {
        printf("\n🎉 all pass!\n");
        result[@"success"] = @(1);
        result[@"message"] = @"🎉 all pass!";
    }else {
        printf("\n%d ✅ %d ❌\n",passCount,(int)checkpointIds.count-passCount);
        result[@"success"] = @(0);
        result[@"message"] = [NSString stringWithFormat:@"%d ✅ %d ❌",passCount,(int)checkpointIds.count-passCount];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    result[@"date"] = dateStr;
    //json result
    NSString *jsonPath = [self.workDirectoryPath stringByAppendingPathComponent:@"result.json"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
    [FileUtil saveData:jsonData atPath:jsonPath];
    //html result
    NSDictionary *packageInfo = @{
                                  @"name" : [self.workBundlePath lastPathComponent],
                                  @"path" : self.workBundlePath,
                                  @"date" : dateStr,
                                  };
    NSString *html = [RenderUtil renderHtmlWithInfo:packageInfo checkResult:self.recordList];
    NSString *htmlPath = [self.workDirectoryPath stringByAppendingPathComponent:@"result.html"];
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    [FileUtil saveData:htmlData atPath:htmlPath];
    printf("\n");
    printf("→ open %s\n",[htmlPath UTF8String]);
    printf("→ open %s\n",[jsonPath UTF8String]);
    printf("\n");
}

- (NSString *)prepareWorkspace: (NSString *)bundlePath {
    self.recordList = [NSMutableArray array];
    //create work directory
    NSString *bundleName = [bundlePath lastPathComponent];
    NSString *name = [bundleName stringByDeletingPathExtension];
    NSString *extension = [bundleName pathExtension];
    NSString *dirName = [NSString stringWithFormat:@"%@-%@",name,[self appName]];
    NSString *parentPath = [bundlePath stringByDeletingLastPathComponent];
    NSString *workDirPath = [parentPath stringByAppendingPathComponent:dirName];
    if([FileUtil dirExistsAtPath:workDirPath]) {
        [FileUtil deleteFileAtPath:workDirPath];
    }
    [FileUtil createDirAtPath:workDirPath];
    NSString *workBundlePath = nil;
    if([extension isEqualToString:@"app"]) {
        //copy .app
        NSFileManager *fm = [NSFileManager defaultManager];
        workBundlePath = [workDirPath stringByAppendingPathComponent:bundleName];
        NSError *error = nil;
        if(![fm copyItemAtPath:bundlePath toPath:workBundlePath error:&error]) {
        
        }
    }else if([extension isEqualToString:@"ipa"]) {
        //unzip ipa
        NSString * cmd = [NSString stringWithFormat:@"unzip %@ -d '%@'",bundlePath,workDirPath];
        [CmdUtil runCmd:cmd workPath:workDirPath];
        //find
        NSFileManager *fm = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:workDirPath];
        NSString *packagePath = nil;
        for (NSString *item in enumerator) {
            if([item hasSuffix:@".app"]) {
                packagePath = item;
                break;
            }
        }
        if(packagePath) {
            workBundlePath = [workDirPath stringByAppendingPathComponent:packagePath];
        }
    }
    self.bundlePath = bundlePath;
    self.workDirectoryPath = workDirPath;
    self.workBundlePath = workBundlePath;
    return workBundlePath;
}

- (BundleInfo *)loadBundleInfo: (NSString *)bundlePath {
    
    NSMutableArray *resourceList = [NSMutableArray array];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *fileURL = [NSURL fileURLWithPath:bundlePath];
    NSArray *keys = @[
                      NSURLNameKey,
                      NSURLPathKey,
                      NSURLIsRegularFileKey,
                      NSURLIsDirectoryKey,
                      NSURLIsPackageKey,
                      NSURLIsHiddenKey,
                      NSURLCreationDateKey,
                      NSURLContentModificationDateKey,
                      NSURLIsExecutableKey,
                      NSURLFileSizeKey,
                      NSURLTypeIdentifierKey,
                      ];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtURL:fileURL includingPropertiesForKeys:keys options:0 errorHandler:nil];
    for (NSURL *itemURL in enumerator) {
        //name
        NSString *name = nil;
        [itemURL getResourceValue:&name forKey:NSURLNameKey error:nil];
        //path
        NSString *path = nil;
        [itemURL getResourceValue:&path forKey:NSURLPathKey error:nil];
        if(!name || !path) {
            continue;
        }
        //regular file
        NSNumber *regularFileValue = nil;
        [itemURL getResourceValue:&regularFileValue forKey:NSURLIsRegularFileKey error:nil];
        //directory
        NSNumber *directoryValue = nil;
        [itemURL getResourceValue:&directoryValue forKey:NSURLIsDirectoryKey error:nil];
        //package
        NSNumber *packageValue = nil;
        [itemURL getResourceValue:&packageValue forKey:NSURLIsPackageKey error:nil];
        //package
        NSNumber *hiddenValue = nil;
        [itemURL getResourceValue:&hiddenValue forKey:NSURLIsHiddenKey error:nil];
        //executable
        NSNumber *executableValue = nil;
        [itemURL getResourceValue:&executableValue forKey:NSURLIsExecutableKey error:nil];
        //file size
        NSNumber *fileSizeValue = nil;
        [itemURL getResourceValue:&fileSizeValue forKey:NSURLFileSizeKey error:nil];
        //creationDate
        NSDate *creationDate = nil;
        [itemURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
        //modificationDate
        NSDate *modificationDate = nil;
        [itemURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
        //UTI
        NSString *utiType = nil;
        [itemURL getResourceValue:&utiType forKey:NSURLTypeIdentifierKey error:nil];
        
        BundleResourceItem *bundleItem = [[BundleResourceItem alloc] init];
        
        bundleItem.name = name;
        bundleItem.path = path;
        bundleItem.bRegularFile = [regularFileValue boolValue];
        bundleItem.bDirectory = [directoryValue boolValue];
        bundleItem.bPackage = [packageValue boolValue];
        bundleItem.bHidden = [hiddenValue boolValue];
        bundleItem.bExecutable = [executableValue boolValue];
        bundleItem.fileSize = [fileSizeValue unsignedIntegerValue];
        bundleItem.creationDate = creationDate;
        bundleItem.modificationDate = modificationDate;
        bundleItem.level = [enumerator level];
        bundleItem.utiType = utiType;
        [resourceList addObject:bundleItem];
    }
    
    BundleInfo *info = [[BundleInfo alloc] init];
    info.bundlePath = bundlePath;
    info.resourceList = resourceList;
    NSMutableArray<CarResourceItem *> *carResourceList = [NSMutableArray array];
    for (BundleResourceItem *item in resourceList) {
        if([item.name hasSuffix:@".car"] && item.bRegularFile) {
            NSString *name = [item.name stringByDeletingPathExtension];
            NSString *outputName = [NSString stringWithFormat:@"%@-carOuput",name];
            NSString *parentPath = [item.path stringByDeletingLastPathComponent];
            NSString *outputPath = [parentPath stringByAppendingPathComponent:outputName];
            [FileUtil createDirAtPath:outputPath];
            NSString *carPath = [item path];
            NSArray<CarResourceItem *> * resourceList = [AssetsUtil unarchiveCarFile:carPath outputPath:outputPath];
            if(resourceList.count > 0) {
                [carResourceList addObjectsFromArray:resourceList];
            }
        }
    }
    if(carResourceList.count > 0) {
        info.carResourceList = [NSArray arrayWithArray:carResourceList];
    }
    return info;
}

- (NSString *)appName {
    return @"afterpack";
}

- (NSString *)homePage {
    return @"http://www.woodpeck.cn";
}

@end
