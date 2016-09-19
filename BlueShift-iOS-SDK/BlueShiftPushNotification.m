//
//  BlueShiftPushNotification.m
//  Pods
//
//  Created by Shahas on 18/09/16.
//
//

#import "BlueShiftPushNotification.h"

@interface BlueShiftPushNotification ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

static BlueShiftPushNotification *_sharedInstance = nil;

@implementation BlueShiftPushNotification

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}


- (void)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    //self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", @"shahas"];
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
        self.bestAttemptContent.attachments = @[attachment];
        self.contentHandler(self.bestAttemptContent);
    }
}

@end
