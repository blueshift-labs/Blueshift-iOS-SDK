//
//  HttpRequestOperationEntity.m
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 02/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import "HttpRequestOperationEntity.h"

@implementation HttpRequestOperationEntity

@dynamic httpMethodNumber;
@dynamic parameters;
@dynamic url;
@dynamic nextRetryTimeStamp;
@dynamic retryAttemptsCount;

// Method to insert Entry for a particular request operation in core data ...

- (void)insertEntryWithMethod:(BlueShiftHTTPMethod)httpMethod andParameters:(NSDictionary *)parameters andURL:(NSString *)url andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    
    // return if context is unavailable ...
    
    if (context == nil) {
        return ;
    }
    
    
    // gets the httpMethodNumber type for the enum ...
    
    self.httpMethodNumber = [NSNumber numberWithBlueShiftHTTPMethod:httpMethod];
    
    
    // will only archive parameters if they are present to prevent crash ...
    
    if (parameters) {
        self.parameters = [NSKeyedArchiver archivedDataWithRootObject:parameters];
    }
    
    self.url = url;
    self.nextRetryTimeStamp = [NSNumber numberWithDouble:nextRetryTimeStamp];
    self.retryAttemptsCount = [NSNumber numberWithInteger:retryAttemptsCount];
    
    NSError *error;
    if (![context save:&error]) {
        
        
        // unable to insert into core data ...
        
        NSLog(@"\n\n Error Queueing Request: %@ \n\n", [error localizedDescription]);
    }
    else {
        
        
        // request inserted to queue successfully (Core Data) ...
        
    }
}



// Method to return the httpMethod type as BlueShiftHTTPMethod enum ...

- (BlueShiftHTTPMethod)httpMethod {
    return [self.httpMethodNumber blueShiftHTTPMethodValue];
}



// Method to return the first record from Core Data ...

+ (HttpRequestOperationEntity *)fetchFirstRecordFromCoreData {
    
    @synchronized(self) {
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[UIApplication sharedApplication].delegate;
        NSManagedObjectContext *context = appDelegate.managedObjectContext;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"HttpRequestOperationEntity" inManagedObjectContext:context]];
        NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate] ];
        NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@", currentTimeStamp];
        [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
        [fetchRequest setFetchLimit:1];
        NSError *error;
        NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
        HttpRequestOperationEntity *operationEntityToBeExecuted = (HttpRequestOperationEntity *)[results firstObject];
        return operationEntityToBeExecuted;
    }
}

@end
