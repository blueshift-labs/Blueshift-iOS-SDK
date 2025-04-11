//
//  AppDelegate.m
//  BlueShift_iOS_SDK_Tests
//
//  Created by Ketan Shikhare on 07/03/25.
//

#import <XCTest/XCTest.h>
#import <BlueShift_iOS_SDK/BlueShift.h>
#import <BlueShift_iOS_SDK/BlueshiftConstants.h>

#import <OCMock/OCMock.h>

@interface AppDelegate : XCTestCase
@property (nonatomic, strong) BlueShiftAppDelegate *appDelegate;
@property (nonatomic, strong) id userDefaultsMock;
@property (nonatomic, strong) id blueShiftMock;
@property (nonatomic, strong) id deviceDataMock;
@end

@implementation AppDelegate

- (void)setUp {
    [super setUp];
    self.appDelegate = [[BlueShiftAppDelegate alloc] init];

    // Mock NSUserDefaults
    self.userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([self.userDefaultsMock standardUserDefaults]).andReturn(self.userDefaultsMock);
    
    // Mocking BlueShift singleton
    self.blueShiftMock = OCMClassMock([BlueShift class]);
    OCMStub([self.blueShiftMock sharedInstance]).andReturn(self.blueShiftMock);
    
    // Mocking BlueShiftDeviceData singleton
    self.deviceDataMock = OCMClassMock([BlueShiftDeviceData class]);
    OCMStub([self.deviceDataMock currentDeviceData]).andReturn(self.deviceDataMock);
}

- (void)tearDown {
    [self.userDefaultsMock stopMocking];
    self.appDelegate = nil;
    [self.blueShiftMock stopMocking];
    [self.deviceDataMock stopMocking];
    [super tearDown];
}

- (void)testGetLastModifiedUNAuthorizationStatus_WhenKeyExists {
    // Stub NSUserDefaults to return a mock authorization status
    NSString *mockStatus = @"authorized";
    OCMStub([self.userDefaultsMock objectForKey:kBlueshiftUNAuthorizationStatus]).andReturn(mockStatus);

    // Call the method
    NSString *result = [self.appDelegate getLastModifiedUNAuthorizationStatus];

    // Assert result matches the expected value
    XCTAssertEqualObjects(result, mockStatus, @"Expected authorization status to be returned correctly.");
}

- (void)testGetLastModifiedUNAuthorizationStatus_WhenKeyDoesNotExist {
    // Stub NSUserDefaults to return nil
    OCMStub([self.userDefaultsMock objectForKey:kBlueshiftUNAuthorizationStatus]).andReturn(nil);

    // Call the method
    NSString *result = [self.appDelegate getLastModifiedUNAuthorizationStatus];

    // Assert result is nil
    XCTAssertNil(result, @"Expected nil when authorization status key does not exist.");
}

// Test case: Verify authorization status is stored in NSUserDefaults
- (void)testSetLastModifiedUNAuthorizationStatus_SavesToUserDefaults {
    NSString *mockStatus = @"denied";

    // Expect NSUserDefaults to set the value
    OCMExpect([self.userDefaultsMock setObject:mockStatus forKey:kBlueshiftUNAuthorizationStatus]);
    
    // Expect synchronize to be called
    OCMExpect([self.userDefaultsMock synchronize]);

    [self.appDelegate performSelector:@selector(setLastModifiedUNAuthorizationStatus:) withObject:mockStatus];

    // Verify expectations
    OCMVerifyAll(self.userDefaultsMock);
}

- (NSData *)dataFromHexString:(NSString *)hexString {
    NSMutableData *data = [[NSMutableData alloc] init];
    unsigned char wholeByte;
    char byteChars[3] = {'\0', '\0', '\0'};
    
    for (int i = 0; i < hexString.length / 2; i++) {
        byteChars[0] = [hexString characterAtIndex:i * 2];
        byteChars[1] = [hexString characterAtIndex:i * 2 + 1];
        wholeByte = strtol(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

// Test Case 1: Register for Remote Notifications with Valid Device Token
- (void)testRegisterForRemoteNotification_WithValidDeviceToken {
    NSData *mockDeviceToken = [self dataFromHexString:@"de9be73e102127bc4d456f6a8981ad4ad60a88aba191a449234f9ac52bf50b48"];
    
    OCMStub([self.blueShiftMock getDeviceToken]).andReturn(@"de9be73e102127bc4d456f6a8981ad4ad60a88aba191a449234f9ac52bf50b48");
    OCMReject([self.blueShiftMock identifyUserWithDetails:nil canBatchThisEvent:NO]);

    [self.appDelegate registerForRemoteNotification:mockDeviceToken];

    OCMVerifyAll(self.blueShiftMock);
}

// Test Case 3: Auto Identify is Called on Device Token Change
- (void)testRegisterForRemoteNotification_ShouldCallAutoIdentifyOnChange {
    // Mock the device token (new token)
    NSData *mockDeviceToken = [self dataFromHexString:@"de9be73e102127bc4d456f6a8981ad4ad60a88aba191a449234f9ac52bf50b48"];

    // Mock previous token to simulate change
    OCMStub([self.blueShiftMock getDeviceToken]).andReturn(@"oldDeviceToken");
    OCMExpect([self.blueShiftMock setDeviceToken]);
    OCMExpect([self.blueShiftMock identifyUserWithDetails:nil canBatchThisEvent:NO]);

    // Call the method
    [self.appDelegate registerForRemoteNotification:mockDeviceToken];

    // Verify that autoIdentifyOnDeviceTokenChange was called
    OCMVerifyAll(self.blueShiftMock);
}

// Test Case 4: Auto Identify is Called When No Previous Device Token Exists
- (void)testRegisterForRemoteNotification_ShouldCallAutoIdentifyOnFirstToken {
    // Mock the device token (first-time token)
    NSData *mockDeviceToken = [self dataFromHexString:@"de9be73e102127bc4d456f6a8981ad4ad60a88aba191a449234f9ac52bf50b48"];

    // Mock previous token as nil (first-time registration)
    OCMStub([self.blueShiftMock getDeviceToken]).andReturn(nil);
    OCMExpect([self.blueShiftMock setDeviceToken]);
    OCMExpect([self.blueShiftMock identifyUserWithDetails:nil canBatchThisEvent:NO]);

    // Call the method
    [self.appDelegate registerForRemoteNotification:mockDeviceToken];

    // Verify autoIdentifyOnDeviceTokenChange was called
    OCMVerify([self.blueShiftMock setDeviceToken]);
    OCMVerify([self.blueShiftMock identifyUserWithDetails:nil canBatchThisEvent:NO]);
}

@end
