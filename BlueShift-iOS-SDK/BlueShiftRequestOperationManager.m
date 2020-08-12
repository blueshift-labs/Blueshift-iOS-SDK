//
//  BlueShiftRequestOperationManager.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestOperationManager.h"
#import "BlueShiftNotificationConstants.h"
#import "InApps/BlueShiftInAppNotificationConstant.h"
#import "BlueshiftLog.h"

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
    self.sessionConfiguraion = defaultConfigObject;
    
}

- (void) getRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary *,NSError *))handler{
    [self addBasicAuthenticationRequestHeaderForUsername:[BlueShift sharedInstance].config.apiKey andPassword:@""];
    if(_backgroundSession == NULL) {
        _backgroundSession = [NSURLSession sessionWithConfiguration: self.sessionConfiguraion delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    }
    //add below params to the end of get url
    NSArray *keysAddedInEnd = [NSArray arrayWithObjects:@"device_id", @"app_name", kNotificationClickElementKey,kNotificationURLElementKey,nil];
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
    
    NSString *urlWithParams = [NSString stringWithFormat:@"%@?%@", urlString, paramsString];
    NSString *encodedString = [urlWithParams stringByReplacingOccurrencesOfString:@" " withString:kBsftEncodedSpace];
    NSURL * url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod:@"GET"];
    NSURLSessionDataTask * dataTask =[_backgroundSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
            [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"GET - Fail %@",url] withDetails:nil statusCode:statusCode];
            handler(false, nil, error);
        }
        
    }];
    [dataTask resume];
}

- (void) postRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary *,NSError *))handler{
    [self addBasicAuthenticationRequestHeaderForUsername:[BlueShift sharedInstance].config.apiKey andPassword:@""];
    if(_backgroundSession == NULL) {
        _backgroundSession = [NSURLSession sessionWithConfiguration: self.sessionConfiguraion delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    }
    
    NSURL * url = [NSURL URLWithString:urlString];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    NSDictionary *paramsDictionary = params;
    [urlRequest setHTTPMethod:@"POST"];
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:paramsDictionary
                                                       options:0
                                                         error:nil];
    [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"Initiated POST %@",urlString] withDetails:params statusCode:0];
    [urlRequest setHTTPBody:JSONData];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSURLSessionDataTask * dataTask =[_backgroundSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
            [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"POST - Fail %@",url] withDetails:nil statusCode:statusCode];
            handler(false, nil, error);
        }
        
    }];
    [dataTask resume];
}

- (void)replayUniversalLink:(NSURL *)url completionHandler:(void (^)(BOOL, NSURL*, NSError*))handler {
    if(_replayURLSesion == NULL) {
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        _replayURLSesion = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    }
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL: url];
    [urlRequest setHTTPMethod:@"GET"];
    [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"Initiated ULReplay for - %@", url.absoluteString] withDetails:nil statusCode:0];
    NSURLSessionDataTask *dataTask = [_replayURLSesion dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(error == nil)
        {
            if(httpResponse.URL != nil)
            {
                [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"ULReplay - Success %@", [[httpResponse URL] absoluteString]] withDetails:nil statusCode:httpResponse.statusCode];
                handler(YES, httpResponse.URL, nil);
            } else {
                [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"ULReplay - Fail %@", [[httpResponse URL] absoluteString]] withDetails:nil statusCode:httpResponse.statusCode];
                handler(NO,nil,[NSError errorWithDomain:@"Failed to load redirection link" code:httpResponse.statusCode userInfo:nil]);
            }
        } else {
            [BlueshiftLog logAPICallInfo:[NSString stringWithFormat:@"ULReplay - Fail %@",[[httpResponse URL] absoluteString]] withDetails:nil statusCode:httpResponse.statusCode];
            handler(NO,nil,error);
        }
    }];
    [dataTask resume];
}


@end
