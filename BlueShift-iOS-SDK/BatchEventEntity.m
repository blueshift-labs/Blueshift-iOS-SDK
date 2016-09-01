//
//  BatchEventEntity.m
//  Pods
//
//  Created by Shahas on 31/08/16.
//
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
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[UIApplication sharedApplication].delegate;
        NSManagedObjectContext *context = appDelegate.managedObjectContext;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"BatchEventEntity" inManagedObjectContext:context]];
        NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
        NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@", currentTimeStamp];
        [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
        //[fetchRequest setFetchLimit:10];
        NSError *error;
        NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
        
        return results;
    }
}


@end
