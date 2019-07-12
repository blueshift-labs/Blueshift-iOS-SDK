//
//  InAppNotificationEntity.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 12/07/19.
//

#import "InAppNotificationEntity.h"
#import "NSNumber+BlueShiftHelpers.h"
#import "BlueShiftAppDelegate.h"
#import "NSDate+BlueShiftDateHelpers.h"

@implementation InAppNotificationEntity

- (void)fetchBy:(NSString *)key withValue:(NSString *)value {
    
}

- (void)insert:(NSDictionary *)dictionary {
    BlueShiftAppDelegate * appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    if (appDelegate) {
        @try {
            masterContext = appDelegate.managedObjectContext;
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
    }
    if (masterContext) {
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = masterContext;
        // return if context is unavailable ...
        if (context == nil || masterContext == nil) {
            return ;
        }
        [self map:dictionary];
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    NSError *error = nil;
                    [context save:&error];
                    if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                        [masterContext performBlock:^{
                            NSError *error = nil;
                            [masterContext save:&error];
                        }];
                    }
                }];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
    } else {
        return ;
    }
}

- (void)update:(NSDictionary *)dictionary {
    
}

- (void)delete {
    
}

- (void)map:(NSDictionary *)dictionary {
    self.id = [dictionary objectForKey:@"id"];
    self.type = [dictionary objectForKey:@"type"];
    self.startTime = [NSNumber numberWithDouble: [[dictionary objectForKey:@"start_time"] doubleValue]];
    self.endTime = [NSNumber numberWithDouble: [[dictionary objectForKey:@"end_time"] doubleValue]];
    self.payload = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    self.priority = @"MEDIUM";
    self.triggerMode = @"NOW";
    self.eventName = @"";
    self.status = @"READY";
}

@end
