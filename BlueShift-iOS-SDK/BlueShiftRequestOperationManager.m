//
//  BlueShiftRequestOperationManager.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestOperationManager.h"

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
    NSString *requestValue = [NSString stringWithFormat:@"Basic %@",credentialsBase64String];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfigObject.HTTPAdditionalHeaders = @{
                                                  @"Authorization":credentialsBase64String,
                                                  @"Content-Type":@"application/json"
                                                  };
    self.sessionConfiguraion = defaultConfigObject;
    
}

- (void) postRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL))handler{
    [self addBasicAuthenticationRequestHeaderForUsername:[BlueShift sharedInstance].config.apiKey andPassword:@""];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: self.sessionConfiguraion delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    NSURL * url = [NSURL URLWithString:urlString];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    //NSString * params =@"user[name]=shahas&user[email]=sha@z.z&user[encrypted_password]=askfdsfkdk";
    
    NSDictionary *paramsDictionary = params;
    [urlRequest setHTTPMethod:@"POST"];
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:paramsDictionary
                                                       options:0
                                                         error:nil];
    [urlRequest setHTTPBody:JSONData];
    
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                           if(error == nil)
                                                           {
                                                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                                                               
                                                               if (statusCode == kStatusCodeSuccessfullResponse) {
                                                                   handler(true);
                                                               } else {
                                                                   handler(false);
                                                               }
                                                           } else {
                                                               handler(false);
                                                           }
                                                           
                                                       }];
    [dataTask resume];
    
}


@end
