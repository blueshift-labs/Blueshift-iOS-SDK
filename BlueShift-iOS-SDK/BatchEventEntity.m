//
//  BatchEventEntity.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BatchEventEntity.h"

@implementation BatchEventEntity

@dynamic paramsArray;
@dynamic nextRetryTimeStamp;
@dynamic retryAttemptsCount;

// Method to insert Entry for a particular request operation in core data ...

- (void)insertEntryParametersList:(NSArray *)parametersArray andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount {
    //NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    // return if context is unavailable ...
    
    if (context == nil) {
        return ;
    }
    
    
    
    // will only archive parameters list if they are present to prevent crash ...
    
    if (parametersArray) {
        self.paramsArray = [NSKeyedArchiver archivedDataWithRootObject:parametersArray];
    }
    
    self.nextRetryTimeStamp = [NSNumber numberWithDouble:nextRetryTimeStamp];
    self.retryAttemptsCount = [NSNumber numberWithInteger:retryAttemptsCount];
    
    NSError *error;
    [context save:&error];
}


// Method to return the failed batch records from Core Data ....

+ (NSArray *)fetchBatchesFromCoreData {
    @synchronized(self) {
        NSArray *results = [[NSArray alloc]init];
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        if(appDelegate != nil && appDelegate.managedObjectContext != nil) {
            NSManagedObjectContext *context = appDelegate.managedObjectContext;
            if(context != nil) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setEntity:[NSEntityDescription entityForName:@"BatchEventEntity" inManagedObjectContext:context]];
                if(fetchRequest.entity != nil) {
                    NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
                    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@", currentTimeStamp];
                    [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
                    NSError *error;
                    @try {
                        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                            results = [context executeFetchRequest:fetchRequest error:&error];
                        }
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Caught exception %@", exception);
                    }
                }
            }
        }
        return results;
    }
}


@end
