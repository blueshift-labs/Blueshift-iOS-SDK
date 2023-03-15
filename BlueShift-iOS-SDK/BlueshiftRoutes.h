//
//  BlueshiftRoutes.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#ifndef BlueShift_iOS_SDK_BlueShiftRoutes_h
#define BlueShift_iOS_SDK_BlueShiftRoutes_h


#define kBS_USBaseURL              @"http://localhost:3000/"
#define kBS_EUBaseURL              @"https://api.eu.getblueshift.com/"
#define kBSRealtimeEvent           @"api/v1/event"
#define kBSBulkEvents              @"api/v1/bulkevents"
#define kBSTrackAPI                @"track"
#define kBSLiveContent             @"live"
#define kBSInAppMessages           @"http://localhost:7000/inapp/msg"
#define kBSInboxMessages           @"http://localhost:7000/inbox/api/v1/messages"
#define kBSInboxStatus             @"http://localhost:7000/inbox/api/v1/status"
#define kBSInboxUpdate             @"http://localhost:7000/inbox/api/v1/update"

@interface BlueshiftRoutes : NSObject

+ (NSString*)getBaseURLString;
+ (NSString*)getRealtimeEventsURL;
+ (NSString*)getBulkEventsURL;
+ (NSString*)getTrackURL;
+ (NSString*)getLiveContentURL;
+ (NSString*)getInAppMessagesURL;
+ (NSString*)getInboxMessagesURL;
+ (NSString*)getInboxStatusURL;
+ (NSString*)getInboxUpdateURL;

@end


#endif
