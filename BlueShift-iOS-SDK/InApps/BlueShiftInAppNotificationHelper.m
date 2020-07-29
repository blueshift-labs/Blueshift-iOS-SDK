//
//  BlueShiftInAppNotificationHelper.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftInAppNotificationConstant.h"

static NSDictionary *_inAppTypeDictionay;

@implementation BlueShiftInAppNotificationHelper

+ (void)load {
    _inAppTypeDictionay = @{
                        kInAppNotificationModalHTMLKey: @(BlueShiftInAppTypeHTML),
                        kInAppNotificationTypeCenterPopUpKey: @(BlueShiftInAppTypeModal),
                        kInAppNotificationTypeSlideBannerKey: @(BlueShiftNotificationSlideBanner),
                        kInAppNotificationTypeRatingKey: @(BlueShiftNotificationRating)
                    };
}

+ (BlueShiftInAppType)inAppTypeFromString:(NSString*)inAppType {
    NSNumber *_inAppType = inAppType != nil ? _inAppTypeDictionay[inAppType] : @(BlueShiftInAppDefault);
    return [_inAppType integerValue];
}

+ (NSString *)getLocalDirectory:(NSString *) fileName {
    NSString* tempPath = NSTemporaryDirectory();
    return [tempPath stringByAppendingPathComponent: fileName];
}

+ (BOOL)hasFileExist:(NSString *) fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath: [self getLocalDirectory: fileName]];
}

+ (NSString *)createFileNameFromURL:(NSString *) imageURL {
    NSString *fileName = [[imageURL lastPathComponent] stringByDeletingPathExtension];
    NSURL *url = [NSURL URLWithString: imageURL];
    NSString *extension = [url pathExtension];
    fileName = [fileName stringByAppendingString:@"."];
    return [fileName stringByAppendingString: extension];
}

+ (BOOL)hasDigits:(NSString *) digits {
    NSCharacterSet *notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return ([digits rangeOfCharacterFromSet: notDigits].location == NSNotFound);
}

+ (void)deleteFileFromLocal:(NSString *) fileName {
    NSString *filePath = [self getLocalDirectory: fileName];
    if ([self hasFileExist: fileName]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
}

+ (CGFloat)convertHeightToPercentage:(UIView *) notificationView {
    CGFloat presentationAreaHeight = [self getPresentationAreaHeight];
    CGFloat viewHeight = notificationView.frame.size.height;
    return ((viewHeight/presentationAreaHeight) * 100);
}

+ (CGFloat)convertPercentageHeightToPoints:(float) height {
    CGFloat presentationAreaHeight = [self getPresentationAreaHeight];
    CGFloat heightInPoints = (CGFloat) ceil(presentationAreaHeight * (height / 100.0f));
    return heightInPoints;
}

+ (CGFloat)getPresentationAreaHeight {
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat topMargin = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat bottomMargin = 0.0;
    if (@available(iOS 11.0, *)) {
        bottomMargin = window.safeAreaInsets.bottom != 0.0 ? window.safeAreaInsets.bottom : topMargin ;
    } else {
        bottomMargin = topMargin;
    }
    CGFloat presentationAreaHeight = [[UIScreen mainScreen] bounds].size.height - topMargin - bottomMargin;
    return presentationAreaHeight;
}

+ (NSString*)getEncodedURLString:(NSString*) urlString {
    if (urlString && ![urlString isEqualToString:@""]) {
        NSString *charactersToEscape = @"!*'();:@&=+$,/?%#[]<>^`\{|}"" ";
        NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
        NSString *escapedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
        return escapedURLString;
    }
    return urlString;
}

@end
