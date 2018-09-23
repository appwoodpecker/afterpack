//
//  AssetsUtil.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/16.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "AssetsUtil.h"
#import "FileUtil.h"

//from cartool
typedef enum kCoreThemeIdiom {
    kCoreThemeIdiomUniversal,
    kCoreThemeIdiomPhone,
    kCoreThemeIdiomPad,
    kCoreThemeIdiomTV,
    kCoreThemeIdiomCar,
    kCoreThemeIdiomWatch,
    kCoreThemeIdiomMarketing
} kCoreThemeIdiom;

typedef NS_ENUM(NSInteger, UIUserInterfaceSizeClass) {
    UIUserInterfaceSizeClassUnspecified = 0,
    UIUserInterfaceSizeClassCompact     = 1,
    UIUserInterfaceSizeClassRegular     = 2,
};

struct renditionkeytoken {
    unsigned short identifier;
    unsigned short value;
};

@interface CUIRenditionKey : NSObject

+ (id)renditionKeyWithKeyList:(const struct renditionkeytoken *)keyList;
- (const struct renditionkeytoken *)keyList;
- (NSUInteger) themeScale;
- (kCoreThemeIdiom) themeIdiom;
- (UIUserInterfaceSizeClass) themeSizeClassHorizontal;
- (UIUserInterfaceSizeClass) themeSizeClassVertical;

@end


@interface CUIThemeRendition : NSObject

- (id)initWithCSIData:(id)csiData forKey:(const struct renditionkeytoken *)arg2;
- (struct renditionkeytoken *)key;

@property(nonatomic) CoreThemeType type;
- (NSString *)name;
- (CGImageRef)uncroppedImage;
- (NSData*) data;
- (NSString *)utiType;

@end

@interface CUICommonAssetStorage : NSObject

- (id)initWithPath:(NSString *)p;
- (id)allAssetKeys;
- (id)allRenditionNames;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(struct renditionkeytoken *keyList, NSData *csiData))block;
- (id)renditionNameForKeyList:(struct renditionkeytoken *)arg1;

@end

@interface CUIStructuredThemeStore : NSObject

- (id)initWithPath:(id)arg1;
- (CUICommonAssetStorage *)store;
- (id)renditionWithKey:(const struct renditionkeytoken *)arg1;


@end

@implementation AssetsUtil

+ (NSArray<CarResourceItem *> *)unarchiveCarFile: (NSString *)carPath outputPath: (NSString *)ouputPath {
    CUIStructuredThemeStore *themeStore = [[CUIStructuredThemeStore alloc] initWithPath:carPath];
    CUICommonAssetStorage *storage = [themeStore store];
    NSMutableArray<CarResourceItem *> *resourceList = [NSMutableArray array];
    NSArray<CUIRenditionKey *> *renditionKeyList = [storage allAssetKeys];
    for (CUIRenditionKey *key in renditionKeyList) {
        CUIThemeRendition *rendition = [themeStore renditionWithKey:[key keyList]];
        if(rendition.type == CoreThemeTypeAssetPack) {
            //ignore asset package
            continue;
        }
        if([AssetsUtil isStorableRendition:rendition]) {
            NSString *dirPath = nil;
            //rendition name
            NSString *name = nil;
            CarResourceItem *item = [[CarResourceItem alloc] init];
            item.assetType = rendition.type;
            [resourceList addObject:item];
            NSString *renditionName = [storage renditionNameForKeyList:[rendition key]];
            if(![AssetsUtil isStandaloneRendition:rendition]) {
                NSString *path = [ouputPath stringByAppendingPathComponent:renditionName];
                if(![FileUtil dirExistsAtPath:path]) {
                    [FileUtil createDirAtPath:path];
                }
                dirPath = path;
            }else {
                dirPath = ouputPath;
            }
            if(rendition.type == CoreThemeTypeOnePart) {
                name = rendition.name;
                if([name rangeOfString:@".pdf" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    name = nil;
                }
            }
            if(name.length == 0) {
                CUIRenditionKey *renditionKey = [CUIRenditionKey renditionKeyWithKeyList:[rendition key]];
                name = rendtionFilename(renditionName, renditionKey, rendition);
            }
            item.name = name;
            item.assetName = renditionName;
            NSData *data = nil;
            if (rendition.data) {
                data = [rendition data];
            }else if(rendition.uncroppedImage) {
                // try to use the UTI
                CGImageRef image = rendition.uncroppedImage;
                CFStringRef uti = (__bridge CFStringRef)renditionUTI(rendition);
                NSMutableData *imageBuffer = [NSMutableData data];
                CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageBuffer, uti, 1, NULL);
                CGImageDestinationAddImage(destination, image, nil);
                CGImageDestinationFinalize(destination);
                CFRelease(destination);
                if(imageBuffer.length > 0) {
                    data = imageBuffer;
                }
                item.imageWidth = CGImageGetWidth(image);
                item.imageHeight = CGImageGetHeight(image);
            }
            if(data) {
                NSString *assetPath = [dirPath stringByAppendingPathComponent:name];
                [FileUtil saveData:data atPath:assetPath];
                item.fileSize = data.length;
                item.path = assetPath;
            }
            [resourceList addObject:item];
        }else {
            //other types
            NSString *assetName = [storage renditionNameForKeyList:[rendition key]];
            NSString *name = rendition.name;
            CarResourceItem *item = [[CarResourceItem alloc] init];
            item.assetName = assetName;
            item.name = name;
            item.assetType = rendition.type;
            [resourceList addObject:item];
        }
    }
    return [NSArray arrayWithArray:resourceList];
}

/**
 * support image(0) and rawData(1000)
 */
+ (BOOL)isStorableRendition: (CUIThemeRendition *)rendition {
    BOOL ret = NO;
    CoreThemeType type = rendition.type;
    switch (type) {
        case CoreThemeTypeOnePart:
        case CoreThemeTypeRawData:
            ret = YES;
            break;
        default:
            break;
    }
    return ret;
}

+ (BOOL)isStandaloneRendition: (CUIThemeRendition *)rendition {
    BOOL ret = NO;
    CoreThemeType type = rendition.type;
    ret = (type != CoreThemeTypeOnePart);
    return ret;
}

NSString *idiomSuffixForCoreThemeIdiom(kCoreThemeIdiom idiom) {
    switch (idiom) {
        case kCoreThemeIdiomUniversal:
            return @"";
            break;
        case kCoreThemeIdiomPhone:
            return @"~iphone";
            break;
        case kCoreThemeIdiomPad:
            return @"~ipad";
            break;
        case kCoreThemeIdiomTV:
            return @"~tv";
            break;
        case kCoreThemeIdiomCar:
            return @"~carplay";
            break;
        case kCoreThemeIdiomWatch:
            return @"~watch";
            break;
        case kCoreThemeIdiomMarketing:
            return @"~marketing";
            break;
        default:
            break;
    }
    
    return @"";
}

//rendition uti, specially for image
NSString *renditionUTI(CUIThemeRendition* rendition) {
    __block NSString *uti = rendition.utiType;
    if(uti.length == 0) {
        NSString *name = [rendition name];
        NSDictionary * extUtiMapping = @{
                                               @"png" : (__bridge NSString *)kUTTypePNG,
                                               @"jpeg" : (__bridge NSString *)kUTTypeJPEG,
                                               @"jpg" : (__bridge NSString *)kUTTypeJPEG,
                                               @"gif" : (__bridge NSString *)kUTTypeGIF,
                                               @"bmp" : (__bridge NSString *)kUTTypeBMP,
                                               };
        [extUtiMapping enumerateKeysAndObjectsUsingBlock:^(NSString *ext, NSString *value, BOOL * _Nonnull stop) {
            if([name rangeOfString:ext options:NSCaseInsensitiveSearch].location != NSNotFound) {
                uti = value;
                *stop = YES;
            }
        }];
    }
    if(uti.length == 0) {
        //default png
        uti = (__bridge NSString*)kUTTypePNG;
    }
    return uti;
}

NSString *sizeClassSuffixForSizeClass(UIUserInterfaceSizeClass sizeClass) {
    switch (sizeClass)
    {
        case UIUserInterfaceSizeClassCompact:
            return @"C";
            break;
        case UIUserInterfaceSizeClassRegular:
            return @"R";
            break;
        default:
            return @"A";
    }
}

//get rendition extension
NSString* rendtionFileExtension(CUIThemeRendition* rendition) {
    NSString *extension = nil;
    // try to use the UTI
    if (rendition.utiType) {
        NSArray* extensions = CFBridgingRelease(UTTypeCopyAllTagsWithClass((__bridge CFStringRef _Nonnull)(rendition.utiType), kUTTagClassFilenameExtension));
        if (extensions.count > 0) {
            extension = extensions.firstObject;
        }
    }
    if(extension.length == 0) {
        if (rendition.type == 9) {
            extension = @"pdf";
        }
    }
    if(extension.length == 0) {
        extension = @"png";
    }
    return extension;
}

//get rendition file name
NSString* rendtionFilename(NSString* renditionName, CUIRenditionKey* key, CUIThemeRendition* rendition) {
    NSString *idiomSuffix = idiomSuffixForCoreThemeIdiom(key.themeIdiom);
    NSString *sizeClassSuffix = @"";
    if (key.themeSizeClassHorizontal || key.themeSizeClassVertical) {
        sizeClassSuffix = [NSString stringWithFormat:@"-%@x%@", sizeClassSuffixForSizeClass(key.themeSizeClassHorizontal), sizeClassSuffixForSizeClass(key.themeSizeClassVertical)];
    }
    NSString *scale = key.themeScale > 1 ? [NSString stringWithFormat:@"@%lux", key.themeScale] : @"";
    NSString* extension = rendtionFileExtension(rendition);
    NSString * name = [NSString stringWithFormat:@"%@%@%@%@", renditionName, idiomSuffix, sizeClassSuffix, scale];
    if(extension.length > 0) {
        name = [NSString stringWithFormat:@"%@.%@",name,extension];
    }
    return name;
}

@end
