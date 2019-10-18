//
//  BlueShiftPushNotification.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//


#import "BlueShiftPushNotification.h"
#import "BlueShiftPushAnalytics.h"
#import "BlueshiftInAppEntityAppDelegate.h"


API_AVAILABLE(ios(10.0))
static BlueShiftPushNotification *_sharedInstance = nil;

@implementation BlueShiftPushNotification

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request {
    if([request.content.userInfo objectForKey:@"image_url"] || [request.content.userInfo objectForKey:@"gif_url"] || [request.content.userInfo objectForKey:@"audio_url"] || [request.content.userInfo objectForKey:@"video_url"] || [request.content.userInfo objectForKey:@"carousel_elements"] || [request.content.userInfo objectForKey:@"bsft_message_uuid"]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)hasBlueShiftAttachments {
    if([BlueShiftPushNotification sharedInstance].attachments && [BlueShiftPushNotification sharedInstance].attachments.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setBlueshiftInAppNotification:(UNNotificationRequest *)request andAppGroupID:(NSString *)appGroupID{
    if ([self hasBlueshiftInAppNotification: request]) {
        NSDictionary *payload = request.content.userInfo;
        BlueshiftInAppEntityAppDelegate *blueshiftInAppentityDelegate = [[BlueshiftInAppEntityAppDelegate alloc] init];
        [blueshiftInAppentityDelegate addInAppNotificationToDataStore: payload andAppGroupID:(NSString *)appGroupID];
    }
}

- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request andAppGroupID:(NSString *)appGroupID {
    [[BlueShiftPushNotification sharedInstance] setBlueshiftInAppNotification: request andAppGroupID: appGroupID];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self trackPushViewedWithRequest:request];
    });
    
    if ([request.content.categoryIdentifier isEqualToString: @"carousel"] || [request.content.categoryIdentifier isEqualToString: @"carousel_animation"]) {
        return [self carouselAttachmentsDownload:request];
    } else {
        return [self mediaAttachmentDownlaod:request];
    }
}

- (void)trackPushViewedWithRequest:(UNNotificationRequest *)request {
    NSDictionary *userInfo = request.content.userInfo;
    if(userInfo && [[BlueShiftPushNotification sharedInstance] apiKey] && ![[[BlueShiftPushNotification sharedInstance] apiKey] isEqualToString:@""]) {
        [BlueShiftPushAnalytics sendPushAnalytics:@"delivered" withParams:userInfo];
    }
}

- (NSArray *)carouselAttachmentsDownload:(UNNotificationRequest *)request {
    NSArray *images = [[NSArray alloc]init];
    images = [request.content.userInfo objectForKey:@"carousel_elements"];
    NSMutableArray *attachments = [[NSMutableArray alloc]init];
    self.attachments = attachments;
    [images enumerateObjectsUsingBlock:
     ^(NSDictionary *image, NSUInteger index, BOOL *stop)
     {
         NSURL *imageURL = [NSURL URLWithString:[image objectForKey:@"image_url"]];
         NSData *imageData = nil;
         if(imageURL != nil && imageURL.absoluteString.length != 0) {
             imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
             if(imageData) {
                 NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                 NSString  *documentsDirectory = [paths objectAtIndex:0];
                 
                 NSString *attachmentName = [NSString stringWithFormat:@"image_%lu.jpg", (unsigned long)index];
                 NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
                 NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
                 NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
                 [imageData writeToFile:filePathToWrite atomically:YES];
                 
                 NSError *error3;
                 UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error3];
                 NSLog(@"%@", error3);
                 if(attachment != nil) {
                     [attachments addObject:attachment];
                     self.attachments = attachments;
                 }
             }
         }
     }];
    return attachments;
}

- (NSArray *)mediaAttachmentDownlaod:(UNNotificationRequest *)request {
    NSURL *imageURL = [NSURL URLWithString:[request.content.userInfo objectForKey:@"image_url"]];
    NSURL *videoURL = [NSURL URLWithString:[request.content.userInfo objectForKey:@"video_url"]];
    NSURL *audioURL = [NSURL URLWithString:[request.content.userInfo objectForKey:@"audio_url"]];
    NSURL *gifURL   = [NSURL URLWithString:[request.content.userInfo objectForKey:@"gif_url"]];
    
    NSData *imageData = nil;
    NSData *videoData = nil;
    NSData *audioData = nil;
    NSData *gifData   = nil;
    
    NSMutableArray *attachments = [[NSMutableArray alloc]init];
    
    if(imageURL != nil) {
        imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
        if(imageData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:@"image.jpg"];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [imageData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error3;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error3];
            NSLog(@"%@", error3);
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    if(videoURL != nil) {
        videoData = [[NSData alloc] initWithContentsOfURL: videoURL];
        if(videoData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:@"video.mp4"];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [videoData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error3;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error3];
            NSLog(@"%@", error3);
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    if(gifURL != nil) {
        gifData = [[NSData alloc] initWithContentsOfURL: gifURL];
        if(gifData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:@"gifImage.gif"];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [gifData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error3;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error3];
            NSLog(@"%@", error3);
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    if(audioURL != nil) {
        audioData = [[NSData alloc] initWithContentsOfURL: audioURL];
        if(audioData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:@"audio.mp3"];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [audioData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error3;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error3];
            NSLog(@"%@", error3);
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    return attachments;
}

- (BOOL)hasBlueshiftInAppNotification: (UNNotificationRequest *)request {
    NSDictionary *userInfo = request.content.userInfo;
    BOOL isIAMPayloadPresent = false;
    if (nil != userInfo) {
        
        NSDictionary *dataPayload =  [userInfo objectForKey: @"data"];
        if (nil != dataPayload) {
            isIAMPayloadPresent = true;
        } else {
            
            NSDictionary *apNSData = [userInfo objectForKey:@"aps"];
            NSNumber *num = [NSNumber numberWithInt:1];
            isIAMPayloadPresent = [[apNSData objectForKey:@"content-available"] isEqualToNumber:num];
        }
    }
    return isIAMPayloadPresent;
}

@end
