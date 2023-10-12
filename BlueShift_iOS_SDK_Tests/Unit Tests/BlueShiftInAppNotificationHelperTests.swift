//
//  BlueShiftInAppNotificationHelper.swift
//  BlueShift_iOS_SDK_Tests
//
//  Created by Ketan Shikhare on 09/10/23.
//

import XCTest
@testable import BlueShift_iOS_SDK

final class BlueShiftInAppNotificationHelperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }

    func testValidOpenInWebURL() throws {
        var url = URL(string: "https://www.blueshift.com?bsft_tgt=browser")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isOpen(inWebURL: url)
            XCTAssertTrue(res, "The url is valid")
        }
        
        url = URL(string: "https://www.blueshift.com?page=home&bsft_tgt=browser")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isOpen(inWebURL: url)
            XCTAssertTrue(res, "The url is valid")
        }
    }
    
    func testInValidOpenInWebURL() throws {
        var url = URL(string: "https://www.blueshift.com")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isOpen(inWebURL: url)
            XCTAssertFalse(res, "The url is invalid")
        }
        
        url = URL(string: "https://www.blueshift.com?page=home")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isOpen(inWebURL: url)
            XCTAssertFalse(res, "The url is invalid")
        }
    }
    
    func testValidWebURL() throws {
        var url = URL(string: "https://www.blueshift.com")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isValidWebURL(url)
            XCTAssertTrue(res, "The url is valid web url")
        }
        
        url = URL(string: "http://www.blueshift.com")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isValidWebURL(url)
            XCTAssertTrue(res, "The url is valid web url")
        }
    }
    
    func testInvalidWebURL() throws {
        var url = URL(string: "blueshiftreads://home")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isValidWebURL(url)
            XCTAssertFalse(res, "The url is valid web url")
        }
        
        url = URL(string: "//app/home")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.isValidWebURL(url)
            XCTAssertFalse(res, "The url is valid web url")
        }
    }
    
    func testRemoveQueryParam() throws {
        var url = URL(string: "https://www.blueshift.com?page=home&bsft_tgt=browser")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.removeQueryParam("bsft_tgt", from: url)
            XCTAssertEqual(res?.absoluteString, "https://www.blueshift.com?page=home", "Successful removal of bsft_tgt param")
        }
        
        url = URL(string: "https://www.blueshift.com?page=home&bsft_tgt=browser")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.removeQueryParam("page", from: url)
            XCTAssertEqual(res?.absoluteString, "https://www.blueshift.com?bsft_tgt=browser", "Successful removal of page param")
        }
        
        url = URL(string: "https://www.blueshift.com?page=home&bsft_tgt=browser")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.removeQueryParam("openIn", from: url)
            XCTAssertEqual(res?.absoluteString, "https://www.blueshift.com?page=home&bsft_tgt=browser", "Successful removal of page param")
        }
    }

}
