//
//  BlueShiftDeviceDataTests.m
//  BlueShift_iOS_SDK_Tests
//
//  Created by Ketan Shikhare on 09/10/23.
//

import XCTest
@testable import BlueShift_iOS_SDK

final class BlueShiftDeviceDataTests: XCTestCase {

    var deviceData: BlueShiftDeviceData!

    override func setUpWithError() throws {
        try super.setUpWithError()
        deviceData = BlueShiftDeviceData.current()
    }

    override func tearDownWithError() throws {
        deviceData = nil
        try super.tearDownWithError()
    }

    func testSingletonInstance() {
        let instance1 = BlueShiftDeviceData.current()
        let instance2 = BlueShiftDeviceData.current()
        XCTAssertTrue(instance1 === instance2, "currentDeviceData should return the same instance")
    }

    func testDeviceUUIDForIDFVSource() {
        deviceData.blueshiftDeviceIdSource = .IDFV
        XCTAssertEqual(deviceData.deviceUUID, deviceData.deviceIDFV, "DeviceUUID should match IDFV when IDFV source is used")
    }

    func testDeviceUUIDForUUIDSource() {
        deviceData.blueshiftDeviceIdSource = .UUID
        let uuid = deviceData.deviceUUID
        XCTAssertNotNil(uuid, "DeviceUUID should not be nil when UUID source is used")
    }

    func testDeviceUUIDForIDFVBundleIDSource() {
        deviceData.blueshiftDeviceIdSource = .idfvBundleID
        let uuid = deviceData.deviceUUID
        XCTAssertNotNil(uuid, "DeviceUUID should not be nil when IDFV:BundleID source is used")
    }

    func testDeviceUUIDForCustomSource() {
        deviceData.blueshiftDeviceIdSource = .custom
        deviceData.customDeviceID = "CustomID123"
        XCTAssertEqual(deviceData.deviceUUID, "CustomID123", "DeviceUUID should match the custom device ID")
    }

    func testResetDeviceUUID() {
        deviceData.blueshiftDeviceIdSource = .UUID
        let oldUUID = deviceData.deviceUUID
        deviceData.resetDeviceUUID()
        let newUUID = deviceData.deviceUUID
        XCTAssertNotEqual(oldUUID, newUUID, "DeviceUUID should change after reset")
    }

    func testResetDeviceUUIDForNonUUIDSource() {
        deviceData.blueshiftDeviceIdSource = .IDFV
        let oldUUID = deviceData.deviceUUID
        deviceData.resetDeviceUUID()
        let newUUID = deviceData.deviceUUID
        XCTAssertEqual(oldUUID, newUUID, "DeviceUUID should not change for non-UUID sources")
    }

    func testToDictionary() {
        deviceData.blueshiftDeviceIdSource = .UUID
        deviceData.deviceToken = "TestDeviceToken"
        BlueShift.sharedInstance()?.setDeviceToken()
        deviceData.deviceIDFA = "TestIDFA"
        deviceData.deviceLanguage = "en"
        deviceData.deviceCountry = "US"
        deviceData.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let deviceDict = deviceData.toDictionary()

        XCTAssertEqual(deviceDict![kDeviceID] as? String, deviceData.deviceUUID, "DeviceID should match")
        XCTAssertEqual(deviceDict![kDeviceToken] as? String, "TestDeviceToken", "DeviceToken should match")
        XCTAssertEqual(deviceDict![kDeviceIDFA] as? String, "TestIDFA", "DeviceIDFA should match")
        XCTAssertEqual(deviceDict![kLanguageCode] as? String, "en", "DeviceLanguage should match")
        XCTAssertEqual(deviceDict![kCountryCode] as? String, "US", "DeviceCountry should match")
        XCTAssertEqual(deviceDict![kLatitude] as? Float, 37.7749, "Latitude should match")
        XCTAssertEqual(deviceDict![kLongitude] as? Float, -122.4194, "Longitude should match")
    }

    func testDeviceIDFV() {
        let idfv = deviceData.deviceIDFV
        XCTAssertNotNil(idfv, "DeviceIDFV should not be nil")
    }

    func testDeviceType() {
        let deviceType = deviceData.deviceType
        XCTAssertNotNil(deviceType, "DeviceType should not be nil")
    }

    func testOperatingSystem() {
        let os = deviceData.operatingSystem
        XCTAssertNotNil(os, "OperatingSystem should not be nil")
        XCTAssertTrue(os!.contains("iOS"), "OperatingSystem should contain 'iOS'")
    }

    func testDeviceManufacturer() {
        XCTAssertEqual(deviceData.deviceManufacturer, kApple, "DeviceManufacturer should be 'Apple'")
    }

    func testGetNetworkCarrierName() {
        #if targetEnvironment(simulator)
        XCTAssertNil(deviceData.networkCarrierName, "NetworkCarrierName should be nil on simulator")
        #else
        XCTAssertNotNil(deviceData.networkCarrierName, "NetworkCarrierName should not be nil on a real device")
        #endif
    }
}
