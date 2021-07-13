//
//  BlueShiftPushAnalytics.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/10/17.
//

#import "BlueShiftPushAnalytics.h"
#import "BlueShiftPushNotification.h"
#import "BlueshiftExtensionConstants.h"
#import "BlueshiftExtensionAnalyticsHelper.h"

#define kBaseURL                        @"https://api.getblueshift.com/"
#define kPushEventsUploadURL            @"track"
#define kStatusCodeSuccessfullResponse  200

@implementation BlueShiftPushAnalytics

+ (void)sendPushAnalytics:(NSString *)type withParams:(NSDictionary *)userInfo {
    if ([BlueshiftExtensionAnalyticsHelper isSendPushAnalytics: userInfo]) {
        NSDictionary *pushTrackParameterDictionary = [BlueshiftExtensionAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary: userInfo];
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        if (pushTrackParameterDictionary) {
            [parameterMutableDictionary addEntriesFromDictionary:pushTrackParameterDictionary];
        }
        [parameterMutableDictionary setObject:type forKey:@"a"];
        NSString *browserPlatform = [NSString stringWithFormat:@"%@ %@", kiOS, [[UIDevice currentDevice] systemVersion]];
        [parameterMutableDictionary setObject:browserPlatform forKey:kBrowserPlatform];
        NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kPushEventsUploadURL];
        [self fireAPICallWithURL:url data:parameterMutableDictionary andRetryCount:3];
    }
}

+ (void)fireAPICallWithURL:(NSString *)url data:(NSDictionary *)params andRetryCount:(NSInteger)count {
    if (@available(iOS 10.0, *)) {
        [self getRequestWithURL:url andParams:params completetionHandler:^(BOOL status, NSDictionary *response, NSError *error) {
            if (!status && count > 0) {
                [self fireAPICallWithURL:url data:params andRetryCount:count-1];
            }
        }];
    }
}

+ (NSDictionary*)getDeviceData {
    if (@available(iOS 10.0, *)) {
        if ([BlueShiftPushNotification sharedInstance].appGroupId && ![[BlueShiftPushNotification sharedInstance].appGroupId isEqualToString:@""]) {
            NSBundle *bundle = [NSBundle mainBundle];
            if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
                bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
            }
            NSString *bundleId = [bundle bundleIdentifier];
            if(bundleId) {
                NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[BlueShiftPushNotification sharedInstance].appGroupId];
                NSString *key = [NSString stringWithFormat:@"Blueshift:%@",bundleId];
                NSDictionary *deviceData = [userDefaults dictionaryForKey: key];
                return deviceData;
            }
        }
    }
    return nil;
}

+ (NSURLSessionConfiguration *)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password {
    if (password==nil || password == NULL) {
        password = @"";
    }
    NSString *credentials = [NSString stringWithFormat:@"%@:%@",username,password];
    NSData *credentialsData = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    NSString *credentialsBase64String = [credentialsData base64EncodedStringWithOptions:0];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfigObject.HTTPAdditionalHeaders = @{
                                                  @"Authorization":credentialsBase64String,
                                                  @"Content-Type":@"application/json"
                                                  };
    return defaultConfigObject;
}

+ (NSString*)getRequestParamStringForDictionary:(NSDictionary*)params {
    NSString *paramsString = [[NSString alloc] init];
    NSArray *keys = [[params allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for(id key in keys) {
        if(paramsString.length > 0) {
            paramsString = [NSString stringWithFormat:@"%@&%@=%@", paramsString, key, [params objectForKey:key]];
        } else {
            paramsString = [NSString stringWithFormat:@"%@=%@", key, [params objectForKey:key]];
        }
    }
    
    //Add device data in the end
    NSDictionary *deviceData = [self getDeviceData];
    if (deviceData) {
        for(id key in deviceData) {
            if(paramsString.length > 0) {
                paramsString = [NSString stringWithFormat:@"%@&%@=%@", paramsString, key, [deviceData objectForKey:key]];
            } else {
                paramsString = [NSString stringWithFormat:@"%@=%@", key, [deviceData objectForKey:key]];
            }
        }
    }
    return paramsString;
}

+ (void) getRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary *,NSError *))handler API_AVAILABLE(ios(10.0)){
    NSURLSessionConfiguration* sessionConfiguraion = [self addBasicAuthenticationRequestHeaderForUsername:[[BlueShiftPushNotification sharedInstance] apiKey] andPassword:@""];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: sessionConfiguraion delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    
    NSString *urlWithParams = [NSString stringWithFormat:@"%@?%@", urlString, [self getRequestParamStringForDictionary:params]];
    NSString *encodedString = [urlWithParams stringByReplacingOccurrencesOfString:@" " withString:kBsftEncodedSpace];
    NSURL * url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error == nil)
        {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            #ifdef DEBUG
                NSLog(@"[Blueshift] API call info -  %@, status %ld",[[(NSHTTPURLResponse *)response URL] absoluteString],(long)statusCode);
            #endif
            if (statusCode == kStatusCodeSuccessfullResponse) {
                NSDictionary *dictionary  = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                handler(true, dictionary, error);
            } else {
                handler(false, nil, error);
            }
        } else {
            handler(false, nil, error);
        }
        
    }];
    [dataTask resume];
}

@end
