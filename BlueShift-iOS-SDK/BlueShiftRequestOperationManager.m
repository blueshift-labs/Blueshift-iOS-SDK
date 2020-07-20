//
//  BlueShiftRequestOperationManager.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestOperationManager.h"
#import "BlueShiftNotificationConstants.h"

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
    
    NSString *paramsString = [[NSString alloc] init];
    for(id key in params) {
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
    NSURLSessionDataTask * dataTask =[_backgroundSession dataTaskWithRequest:urlRequest
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
    [urlRequest setHTTPBody:JSONData];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSURLSessionDataTask * dataTask =[_backgroundSession dataTaskWithRequest:urlRequest
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

- (void)replayUniversalLink:(NSURL *)url completionHandler:(void (^)(BOOL, NSURL*, NSError*))handler {
    if(_replayURLSesion == NULL) {
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        _replayURLSesion = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    }
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL: url];
    [urlRequest setHTTPMethod:@"GET"];
    NSURLSessionDataTask *dataTask = [_replayURLSesion dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error == nil)
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if(httpResponse.URL != nil)
            {
                handler(YES, httpResponse.URL, nil);
            } else {
                handler(NO,nil,[NSError errorWithDomain:@"Failed to load redirection link" code:httpResponse.statusCode userInfo:nil]);
            }
        } else {
            handler(NO,nil,error);
        }
    }];
    [dataTask resume];
}


@end
