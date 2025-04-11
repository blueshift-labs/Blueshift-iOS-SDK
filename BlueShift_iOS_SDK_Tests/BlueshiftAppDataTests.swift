//
//  BlueShiftAppDataTests.swift
//  BlueShift_iOS_SDK_Tests
//
//  Created by Ketan Shikhare on 09/10/23.
//

import XCTest
@testable import BlueShift_iOS_SDK

final class BlueShiftAppDataTests: XCTestCase {

    var appData: BlueShiftAppData!

    override func setUp() {
        super.setUp()
        appData = BlueShiftAppData.current()
    }

    override func tearDown() {
        appData = nil
        super.tearDown()
    }

    func testAppName() {
        let expectedAppName = Bundle.main.infoDictionary?["CFBundleName"] as? String
        XCTAssertEqual(appData.appName, expectedAppName, "App name does not match")
    }

    func testAppVersion() {
        let expectedAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        XCTAssertEqual(appData.appVersion, expectedAppVersion, "App version does not match")
    }

    func testSDKVersion() {
        XCTAssertEqual(appData.sdkVersion, kBlueshiftSDKVersion, "SDK version does not match")
    }

    func testAppBuildNumber() {
        let expectedBuildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        XCTAssertEqual(appData.appBuildNumber, expectedBuildNumber, "Build number does not match")
    }

    func testBundleIdentifier() {
        let expectedBundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
        XCTAssertEqual(appData.bundleIdentifier, expectedBundleIdentifier, "Bundle identifier does not match")
    }

    func testEnablePushDefaultsToTrue() {
        UserDefaults.standard.removeObject(forKey: kBlueshiftEnablePush)
        XCTAssertTrue(appData.enablePush, "Enable push should default to true")
    }

    func testEnablePushSetAndRetrieve() {
        appData.enablePush = false
        XCTAssertFalse(appData.enablePush, "Enable push should be false")

        appData.enablePush = true
        XCTAssertTrue(appData.enablePush, "Enable push should be true")
    }

    func testEnableInAppDefaultsToTrue() {
        UserDefaults.standard.removeObject(forKey: kBlueshiftEnableInApp)
        XCTAssertTrue(appData.enableInApp, "Enable in-app should default to true")
    }

    func testEnableInAppSetAndRetrieve() {
        appData.enableInApp = false
        XCTAssertFalse(appData.enableInApp, "Enable in-app should be false")

        appData.enableInApp = true
        XCTAssertTrue(appData.enableInApp, "Enable in-app should be true")
    }

    func testGetCurrentInAppNotificationStatus() {
        BlueShift.sharedInstance()?.config = BlueShiftConfig()
        BlueShift.sharedInstance()?.config?.enableInAppNotification = true
        appData.enableInApp = true

        XCTAssertTrue(appData.getCurrentInAppNotificationStatus(), "In-app notification status should be true")

        appData.enableInApp = false
        XCTAssertFalse(appData.getCurrentInAppNotificationStatus(), "In-app notification status should be false")

        BlueShift.sharedInstance()?.config?.enableInAppNotification = false
        XCTAssertFalse(appData.getCurrentInAppNotificationStatus(), "In-app notification status should be false when config is disabled")
    }

    func testToDictionary() {
        let dictionary = appData.toDictionary()
        XCTAssertNotNil(dictionary, "Dictionary should not be nil")
        XCTAssertEqual(dictionary?[kAppName] as? String, appData.bundleIdentifier, "App name in dictionary does not match")
        XCTAssertEqual(dictionary?[kAppVersion] as? String, appData.appVersion, "App version in dictionary does not match")
        XCTAssertEqual(dictionary?[kBuildNumber] as? String, appData.appBuildNumber, "Build number in dictionary does not match")
        XCTAssertEqual(dictionary?[kBundleIdentifier] as? String, appData.bundleIdentifier, "Bundle identifier in dictionary does not match")
        XCTAssertEqual(dictionary?[kEnableInApp] as? Bool, appData.getCurrentInAppNotificationStatus(), "Enable in-app in dictionary does not match")
        XCTAssertEqual(dictionary?[kInAppNotificationModalSDKVersionKey] as? String, appData.sdkVersion, "SDK version in dictionary does not match")
    }
}
