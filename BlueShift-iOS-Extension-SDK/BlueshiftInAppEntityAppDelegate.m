//
//  BlueshiftInAppEntityAppDelegate.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 23/08/19.
//

#import "BlueshiftInAppEntityAppDelegate.h"
#import "InAppNotificationEntity.h"
#import <CoreData/CoreData.h>
#import "BlueShiftNotificationConstants.h"

@interface BlueshiftInAppEntityAppDelegate ()

@property (readonly, strong, nonatomic) NSManagedObjectContext * _Nullable managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext * _Nullable realEventManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext * _Nullable batchEventManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel * _Nullable managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator * _Nullable persistentStoreCoordinator;
@property (readwrite, strong, nonatomic) NSString * _Nullable appGroupID;

@end

@implementation BlueshiftInAppEntityAppDelegate

- (void)checkInAppNotificationExist:(NSDictionary *)payload handler:(void (^)(BOOL))handler{
    if (payload) {
        NSEntityDescription *entity;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        @try {
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext: self.managedObjectContext];
            [fetchRequest setEntity:entity];
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }

        if(entity != nil && fetchRequest.entity != nil) {
            if ([payload objectForKey: kInAppNotificationModalMessageUDIDKey]) {
                NSString *notificationID = (NSString *)[payload objectForKey: kInAppNotificationModalMessageUDIDKey];
                [InAppNotificationEntity fetchNotificationByID: self.managedObjectContext forNotificatioID: notificationID request: fetchRequest handler:^(BOOL status, NSArray *result){
                    if (status) {
                        handler(NO);
                    } else {
                        handler(YES);
                    }
                }];
            }
        }
    }
}

- (void)addInAppNotificationToDataStore:(NSDictionary *)notificationPayload andAppGroupID:(NSString *)appGroupID {
    self.appGroupID = appGroupID;
    
    [self checkInAppNotificationExist: notificationPayload handler:^(BOOL status){
        if (status) {
            NSEntityDescription *entity;
            @try {
                entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext: self.managedObjectContext];
            }
            @catch (NSException *exception) {
                NSLog(@"Caught exception %@", exception);
            }
            
            if(entity != nil) {
                InAppNotificationEntity *inAppEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: self.managedObjectContext];
                if (nil != inAppEntity){
                    @try {
                        NSManagedObjectContext* privateObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                        
                        [inAppEntity insert:notificationPayload  usingPrivateContext: privateObjectContext andMainContext:self.managedObjectContext handler:^(BOOL done) {
                            if (done) {
                               
                            }
                        }];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Caught exception %@", exception);
                    }
                } else {
                    printf("\n App entity is nil");
                }
            }
        }
    }];
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize realEventManagedObjectContext = _realEventManagedObjectContext;
@synthesize batchEventManagedObjectContext = _batchEventManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory in the application's documents directory.
    //[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    if(self.appGroupID != nil && ![self.appGroupID isEqualToString:@""])
        return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: self.appGroupID];
    else
        return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    //NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/BlueShiftBundle.bundle",[[NSBundle mainBundle] resourcePath]]];
    //NSBundle *dataBundle = [NSBundle bundleWithURL:url];
    
    //    NSString *bundlePath = [[NSBundle bundleForClass:self.class] pathForResource:@"BlueShiftBundle" ofType:@"bundle"];
    //
    //    NSBundle *dataBundle = [NSBundle bundleWithPath:bundlePath];
    
    
    //NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[dataBundle]];
    
    //NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BlueShiftSDKDataModel" withExtension:@"momd"];
    NSString * path = @"";
    if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_Bundle.framework"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_Bundle.framework"];
    }
    if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_iOS_SDK.framework"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_iOS_SDK.framework"];
    }
    if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd"];
    }
    
    NSURL *modelURL = [NSURL fileURLWithPath:path];
    
    //    NSURL *modelURL = [dataBundle URLForResource:@"BlueShiftSDKDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BlueShift-iOS-SDK.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

- (NSManagedObjectContext *)realEventManagedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_realEventManagedObjectContext != nil) {
        return _realEventManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _realEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_realEventManagedObjectContext setPersistentStoreCoordinator:coordinator];
    return _realEventManagedObjectContext;
}

- (NSManagedObjectContext *)batchEventManagedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_batchEventManagedObjectContext != nil) {
        return _batchEventManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _batchEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_batchEventManagedObjectContext setPersistentStoreCoordinator:coordinator];
    return _batchEventManagedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}


@end
