//
//  BlueShiftPushAnalytics.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/10/17.
//

#import "BlueShiftPushAnalytics.h"
#import "ExtensionSDKVersion.h"
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

+ (NSURLSessionConfiguration *)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password {
    if (password==nil || password == NULL) {
        password = @"";
    }
    // Generates the Base 64 encryption for the request ...
    // Adds it to the request Header ...
    
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

+ (void) getRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary *,NSError *))handler API_AVAILABLE(ios(10.0)){
    NSURLSessionConfiguration* sessionConfiguraion = [self addBasicAuthenticationRequestHeaderForUsername:[[BlueShiftPushNotification sharedInstance] apiKey] andPassword:@""];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: sessionConfiguraion delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    NSString *paramsString = [[NSString alloc] init];
    NSArray *keys = [[params allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for(id key in keys) {
        if(paramsString.length > 0) {
            paramsString = [NSString stringWithFormat:@"%@&%@=%@", paramsString, key, [params objectForKey:key]];
        } else {
            paramsString = [NSString stringWithFormat:@"%@=%@", key, [params objectForKey:key]];
        }
    }
    
    NSString *urlWithParams = [NSString stringWithFormat:@"%@?%@", urlString, paramsString];
    NSString *encodedString = [urlWithParams stringByReplacingOccurrencesOfString:@" " withString:kBsftEncodedSpace];
    NSURL * url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                           if(error == nil)
                                                           {
                                                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                                                               
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
