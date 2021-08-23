//
//  BlueShiftRequestOperationManager.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestOperationManager.h"
#import "BlueShiftNotificationConstants.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

static BlueShiftRequestOperationManager *_sharedRequestOperationManager = nil;

@implementation BlueShiftRequestOperationManager

// Method to get the shared instance for BlueShiftOperationManager ...
+ (BlueShiftRequestOperationManager *)sharedRequestOperationManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedRequestOperationManager = [[BlueShiftRequestOperationManager alloc]init];
    });
    return _sharedRequestOperationManager;
}

// Method to add Basic authentication request Header ...
- (void)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password {
    if(self.sessionConfiguraion) {
        return;
    }
    if (!password) {
        password = @"";
    }
    
    NSString *credentials = [NSString stringWithFormat:@"%@:%@",username,password];
    NSData *credentialsData = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    NSString *credentialsBase64String = [credentialsData base64EncodedStringWithOptions:0];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfigObject.HTTPAdditionalHeaders = @{
                                                  kBSAuthorization:credentialsBase64String,
                                                  kBSContentType:kBSApplicationJSON
                                                  };
    self.sessionConfiguraion = defaultConfigObject;
}

- (NSString*)getRequestParamStringForDictionary:(NSDictionary*)params {
    //add below params to the end of get url
    NSArray *keysAddedInEnd = [NSArray arrayWithObjects:kDeviceID, kAppName, kNotificationClickElementKey,kNotificationURLElementKey,nil];
    NSMutableArray *availbleKeysToAddAtEnd = [[NSMutableArray alloc] init];
    //remove the params which needs to be added in the end
    NSMutableDictionary *filteredParams = [params mutableCopy];
    for (NSString* key in keysAddedInEnd) {
        if ([filteredParams objectForKey:key]) {
            [availbleKeysToAddAtEnd addObject:[key copy]];
            [filteredParams removeObjectForKey:key];
        }
    }
    //Add rest of params first in sorted order and then add the params to be added in the end
    NSString *paramsString = [[NSString alloc] init];
    NSArray *filteredKeys = [[filteredParams allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *finalKeys = [filteredKeys arrayByAddingObjectsFromArray:availbleKeysToAddAtEnd];
    for(id key in finalKeys) {
        if(paramsString.length > 0) {
            paramsString = [NSString stringWithFormat:@"%@&%@=%@", paramsString, key, [params objectForKey:key]];
        } else {
            paramsString = [NSString stringWithFormat:@"%@=%@", key, [params objectForKey:key]];
        }
    }
    return  paramsString;
}

- (void)getRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary *,NSError *))handler{
    [self addBasicAuthenticationRequestHeaderForUsername:[BlueShift sharedInstance].config.apiKey andPassword:@""];
    if(!_mainURLSession) {
        _mainURLSession = [NSURLSession sessionWithConfiguration: self.sessionConfiguraion delegate: nil delegateQueue: [NSOperationQueue currentQueue]];
    }
    
    NSString *urlWithParams = [NSString stringWithFormat:@"%@?%@", urlString, [self getRequestParamStringForDictionary:params]];
    NSString *encodedString = [urlWithParams stringByReplacingOccurrencesOfString:@" " withString:kBsftEncodedSpace];
    NSURL *url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:kBSGETMethod];
    
    NSURLSessionDataTask * dataTask = [_mainURLSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        NSString *url = [[response URL] absoluteString];
        if(error == nil)
        {
            if (statusCode == kStatusCodeSuccessfullResponse) {
                NSDictionary *dictionary  = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"GET - Success %@",url] withDetails:nil statusCode:statusCode];
                handler(true, dictionary, error);
            } else {
                [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"GET - Fail %@",url] withDetails:nil statusCode:statusCode];
                handler(false, nil, error);
            }
        } else {
            [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"GET - Fail %@",url] withDetails:@{@"error":error} statusCode:statusCode];
            handler(false, nil, error);
        }
        
    }];
    [dataTask resume];
}

- (void)postRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary *,NSError *))handler{
    [self addBasicAuthenticationRequestHeaderForUsername:[BlueShift sharedInstance].config.apiKey andPassword:@""];
    if(!_mainURLSession) {
        _mainURLSession = [NSURLSession sessionWithConfiguration: self.sessionConfiguraion delegate: nil delegateQueue: [NSOperationQueue currentQueue]];
    }
    
    NSURL * url = [NSURL URLWithString:urlString];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:kBSPOSTMethod];
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    [urlRequest setHTTPBody:JSONData];
    [urlRequest setValue:kBSApplicationJSON forHTTPHeaderField:kBSContentType];
    [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"Initiated POST %@",urlString] withDetails:params statusCode:0];

    NSURLSessionDataTask * dataTask = [_mainURLSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        NSString *url = [[response URL] absoluteString];
        if(error == nil)
        {
            if (statusCode == kStatusCodeSuccessfullResponse) {
                NSDictionary *dictionary  = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"POST - Success %@",url] withDetails:nil statusCode:statusCode];
                handler(true, dictionary, error);
            } else {
                [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"POST - Fail %@",url] withDetails:nil statusCode:statusCode];
                handler(false, nil, error);
            }
        } else {
            [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"POST - Fail %@",url] withDetails:@{@"error":error} statusCode:statusCode];
            handler(false, nil, error);
        }
    }];
    [dataTask resume];
}

- (void)replayUniversalLink:(NSURL *)url completionHandler:(void (^)(BOOL, NSURL*, NSError*))handler {
    if(!_replayURLSesion) {
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        _replayURLSesion = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue currentQueue]];
    }
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL: url];
    [urlRequest setHTTPMethod:kBSGETMethod];
    [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"Initiated ULReplay for - %@", url.absoluteString] withDetails:nil statusCode:0];
    
    NSURLSessionDataTask *dataTask = [_replayURLSesion dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(error == nil)
        {
            NSString* redirectURLString = [httpResponse.allHeaderFields valueForKey:kURLSessionLocation];
            NSURL* redirectURL = nil;
            if(redirectURLString) {
                redirectURL = [[NSURL alloc] initWithString:redirectURLString];
            }
            if(redirectURL != nil)
            {
                [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"ULReplay - Success %@", redirectURLString] withDetails:nil statusCode:httpResponse.statusCode];
                handler(YES, redirectURL, nil);
            } else {
                [BlueshiftLog logAPICallInfo:@"ULReplay - Fail. Unable to find `location` url in the response." withDetails:nil statusCode:httpResponse.statusCode];
                handler(NO,nil,[NSError errorWithDomain:@"Failed to load redirection link" code:httpResponse.statusCode userInfo:nil]);
            }
        } else {
            [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"ULReplay - Fail %@",[[httpResponse URL] absoluteString]] withDetails:@{@"error":error} statusCode:httpResponse.statusCode];
            handler(NO,nil,error);
        }
    }];
    [dataTask resume];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    completionHandler(nil);
}

@end
