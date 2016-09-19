//
//  BlueShiftPushNotification.m
//  Pods
//
//  Created by Shahas on 18/09/16.
//
//

#import "BlueShiftPushNotification.h"


static BlueShiftPushNotification *_sharedInstance = nil;

@implementation BlueShiftPushNotification

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}


- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request {
    
    NSURL *url = [NSURL URLWithString:[request.content.userInfo objectForKey:@"media-attachment"]];
    NSString *type = [NSString stringWithFormat:@"%@", [request.content.userInfo objectForKey:@"attachment-type"]];
    NSData *data = [[NSData alloc] initWithContentsOfURL: url];
    if (data)
    {
        NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString  *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *attachmentName = [NSString stringWithFormat:@"attachment.%@", type];
        NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
        NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
        NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
        [data writeToFile:filePathToWrite atomically:YES];
        
        NSError *error3;
        
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error3];
        NSLog(@"%@", error3);
        NSArray *attachments = [[NSArray alloc] initWithObjects:attachment, nil];
        return attachments;
    }
}

@end
