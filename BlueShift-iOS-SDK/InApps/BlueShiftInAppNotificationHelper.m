//
//  BlueShiftInAppNotificationHelper.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 11/07/19.
//
#import <CommonCrypto/CommonDigest.h>

#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShift.h"
#import "BlueShiftConstants.h"

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

+ (NSString *)createFileNameFromURL:(NSString *) fileURL {
    NSString *fileName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
    NSURL *url = [NSURL URLWithString: fileURL];
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

+ (CGFloat)convertPointsHeightToPercentage:(float) height forWindow:(UIWindow*)window {
    CGFloat presentationAreaHeight = [self getPresentationAreaHeightForWindow:window];
    CGFloat heightInPercentage = (CGFloat) (((height/presentationAreaHeight) * 100.0f));
    if(heightInPercentage > 100) {
        return 100;
    }
    return heightInPercentage;
}

+ (CGFloat)convertPointsWidthToPercentage:(float) width forWindow:(UIWindow*)window {
    CGFloat presentationAreaWidth = [self getPresentationAreaWidthForWindow:window];
    CGFloat widthInPercentage = (CGFloat) (((width/presentationAreaWidth) * 100.0f));
    if(widthInPercentage > 100) {
        return 100;
    }
    return  widthInPercentage;
}

+ (CGFloat)convertPercentageHeightToPoints:(float) height forWindow:(UIWindow*)window {
    CGFloat presentationAreaHeight = [self getPresentationAreaHeightForWindow:window];
    CGFloat heightInPoints = (CGFloat) round(presentationAreaHeight * (height / 100.0f));
    return heightInPoints;
}

+ (CGFloat)convertPercentageWidthToPoints:(float) width forWindow:(UIWindow*)window {
    CGFloat presentationAreaWidth = [self getPresentationAreaWidthForWindow:window];
    CGFloat widthInPoints = (CGFloat) round(presentationAreaWidth * (width / 100.0f));
    return widthInPoints;
}

+ (CGFloat)getPresentationAreaHeightForWindow:(UIWindow*)window {
    CGFloat topMargin = 0.0;
    CGFloat bottomMargin = 0.0;
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeAreaInsets = [self getApplicationWindowSafeAreaInsets:window];
        topMargin =  safeAreaInsets.top;
        bottomMargin = safeAreaInsets.bottom;
    } else {
        topMargin = [[UIApplication sharedApplication] statusBarFrame].size.height;
        bottomMargin = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    CGFloat windowHeight = [self getApplicationWindowSize:window].height;
    CGFloat presentationAreaHeight = windowHeight - topMargin - bottomMargin;
    return presentationAreaHeight;
}

+ (CGFloat)getPresentationAreaWidthForWindow:(UIWindow*)window {
    CGFloat leftMargin = 0.0;
    CGFloat rightMargin = 0.0;
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeAreaInsets = [self getApplicationWindowSafeAreaInsets:window];
        leftMargin = safeAreaInsets.left;
        rightMargin = safeAreaInsets.right;
    }
    CGFloat windowWidth = [self getApplicationWindowSize:window].width;
    CGFloat presentationAreaWidth = windowWidth - leftMargin - rightMargin;
    return presentationAreaWidth;
}

+ (UIWindow *)getApplicationKeyWindow {
    if (@available(iOS 13.0, *)) {
        if ([NSThread isMainThread] == YES) {
            if (@available(iOS 15.0, *)) {
                for(UIScene *scene in [[UIApplication sharedApplication].connectedScenes allObjects]) {
                    if (![scene isKindOfClass:[UIWindowScene class]]) {
                      continue;
                    }
                    
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    if(windowScene && windowScene.activationState == UISceneActivationStateForegroundActive && windowScene.keyWindow) {
                        return windowScene.keyWindow;
                    }
                }
            } else if (@available(iOS 13.0, *)) {
                for (UIWindow *window in [UIApplication sharedApplication].windows) {
                    if (window && window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

+ (CGSize)getApplicationWindowSize:(UIWindow *)window {
    if (window) {
        return window.bounds.size;
    } else if ([self getApplicationKeyWindow]) {
        return [self getApplicationKeyWindow].bounds.size;
    } else {
        return [[UIScreen mainScreen] bounds].size;
    }
}

+ (UIEdgeInsets)getApplicationWindowSafeAreaInsets:(UIWindow*)window API_AVAILABLE(ios(11.0)) {
    if (window) {
        return window.safeAreaInsets;
    } else if ([BlueShiftInAppNotificationHelper getApplicationKeyWindow]) {
        return [BlueShiftInAppNotificationHelper getApplicationKeyWindow].safeAreaInsets;
    } else {
        return  UIEdgeInsetsZero;
    }
}

+ (BOOL)checkAppDelegateWindowPresent {
    if (![[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        return NO;
    }
    return YES;
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

+ (BOOL)isIpadDevice {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

+ (NSDate*)getUTCDateFromDateString:(NSString*)createdAtDateString {
    if (createdAtDateString) {
        NSDateFormatter *dateFormatter = [self getUTCDateFormatter];
        NSDate* utcDate = [dateFormatter dateFromString:createdAtDateString];
        return utcDate;
    }
    return [NSDate date];
}

+ (NSDateFormatter*)getUTCDateFormatter {
    NSDateFormatter* utcDateFormatter = [[NSDateFormatter alloc] init];
    [utcDateFormatter setDateFormat:kDefaultDateFormat];
    [utcDateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601]];
    [utcDateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    [utcDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    return utcDateFormatter;
}

+ (NSString * _Nullable)getMessageUUID:(NSDictionary *)notificationPayload {
    if ([notificationPayload objectForKey: kBSMessageUUID]) {
        return (NSString *)[notificationPayload objectForKey: kBSMessageUUID];
    } else {
        if([notificationPayload objectForKey:kInAppNotificationDataKey]) {
            notificationPayload = [notificationPayload objectForKey:kInAppNotificationDataKey];
            if ([notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey]) {
                return (NSString *)[notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey];
            }
        }
    }
    return nil;
}

+ (BOOL)isExpired:(double)expiryTime {
    double currentTime =  [[NSDate date] timeIntervalSince1970];
    return currentTime > expiryTime;
}

#pragma mark - Font awesome support
+ (void)downloadFontAwesomeFile:(void(^)(void))completionHandler {
    NSString *fontFileName = [self createFileNameFromURL: kInAppNotificationFontFileDownlaodURL];
    if (![self hasFileExist: fontFileName]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL  *url = [NSURL URLWithString: kInAppNotificationFontFileDownlaodURL];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            if (urlData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *fontFilePath = [self getLocalDirectory: fontFileName];
                    [urlData writeToFile: fontFilePath atomically:YES];
                    completionHandler();
                });
            }
        });
    }
}

+ (BOOL)isValidWebURL:(NSURL*)url {
    NSString* urlScheme = url.scheme.lowercaseString;
    if (([urlScheme isEqualToString:@"http"] || [urlScheme isEqualToString:@"https"])) {
        return YES;
    }
    return NO;
}

+ (BOOL)isOpenInWebURL:(NSURL*)url {
    NSMutableDictionary *queryParams = [BlueshiftEventAnalyticsHelper getQueriesFromURL:url];
    if ([[queryParams objectForKey:kBSOpenInWebBrowserKey] isEqualToString:kBSOpenInWebBrowserValue]) {
        return YES;
    }
    return NO;
}

+ (NSURL* _Nullable)removeQueryParam:(NSString*)param FromURL:(NSURL*)url {
    if(param && url) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithString:url.absoluteString];
        NSMutableArray *updatedQueryItems = [NSMutableArray arrayWithCapacity:components.queryItems.count];
        for (NSURLQueryItem *queryItem in components.queryItems) {
            if (![queryItem.name isEqualToString:param]) {
                [updatedQueryItems addObject:queryItem];
            }
        }
        
        components.queryItems = updatedQueryItems;
        return [components URL];
    }
    return nil;
}

@end
