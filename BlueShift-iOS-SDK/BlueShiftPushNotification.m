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
    
    if ([request.content.categoryIdentifier isEqualToString: @"carousel"]) {
        return [self carouselAttachmentsDownload:request];
    } else {
        return [self mediaAttachmentDownlaod:request];
    }
}

- (NSArray *)carouselAttachmentsDownload:(UNNotificationRequest *)request {
    NSArray *images = [[NSArray alloc]init];
    images = [request.content.userInfo objectForKey:@"carousel_images"];
    NSMutableArray *attachments = [[NSMutableArray alloc]init];
    
    [images enumerateObjectsUsingBlock:
     ^(NSDictionary *image, NSUInteger index, BOOL *stop)
     {
         NSURL *imageURL = [NSURL URLWithString:[image objectForKey:@"image_url"]];
         NSData *imageData = nil;
         if(imageURL != nil) {
             imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
             if(imageData) {
                 NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                 NSString  *documentsDirectory = [paths objectAtIndex:0];
                 
                 NSString *attachmentName = [NSString stringWithFormat:@"image_%d.jpg", index];
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

@end
