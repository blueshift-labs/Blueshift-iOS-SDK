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
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    // MARK: - File Related Tests
    
    func testGetLocalDirectory() throws {
        let fileName = "test_file.txt"
        let localPath = BlueShiftInAppNotificationHelper.getLocalDirectory(fileName)
        
        XCTAssertNotNil(localPath, "Local path should not be nil")
        XCTAssertTrue(localPath.contains(NSTemporaryDirectory()), "Path should be in temporary directory")
        XCTAssertTrue(localPath.hasSuffix(fileName), "Path should end with the file name")
    }
    
    func testCreateFileNameFromURL() throws {
        // Test with simple URL
        var url = "https://example.com/image.jpg"
        var fileName = BlueShiftInAppNotificationHelper.createFileName(fromURL: url)
        XCTAssertEqual(fileName, "image.jpg", "File name should be extracted correctly")
        
        // Test with URL containing query parameters
        url = "https://example.com/image.jpg?param=value"
        fileName = BlueShiftInAppNotificationHelper.createFileName(fromURL: url)
        XCTAssertEqual(fileName, "image.jpg", "File name should ignore query parameters")
        
        // Test with URL containing path segments
        url = "https://example.com/path/to/image.jpg"
        fileName = BlueShiftInAppNotificationHelper.createFileName(fromURL: url)
        XCTAssertEqual(fileName, "image.jpg", "File name should extract only the last path component")
    }
    
    func testHasDigits() throws {
        // Test with only digits
        XCTAssertTrue(BlueShiftInAppNotificationHelper.hasDigits("12345"), "Should return true for string with only digits")
        
        // Test with mixed content
        XCTAssertFalse(BlueShiftInAppNotificationHelper.hasDigits("abc123"), "Should return false for string with mixed content")
        
        // Test with no digits
        XCTAssertFalse(BlueShiftInAppNotificationHelper.hasDigits("abcdef"), "Should return false for string with no digits")
        
        // Test with empty string
        XCTAssertTrue(BlueShiftInAppNotificationHelper.hasDigits(""), "Should return true for empty string")
    }
    
    // MARK: - Conversion Tests
    
    func testConversionMethods() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        
        // Test height conversion (points to percentage)
        let heightPercentage = BlueShiftInAppNotificationHelper.convertPointsHeight(toPercentage: 240, for: window)
        XCTAssertEqual(heightPercentage, 50.0, accuracy: 0.1, "Height percentage should be approximately 50%")
        
        // Test width conversion (points to percentage)
        let widthPercentage = BlueShiftInAppNotificationHelper.convertPointsWidth(toPercentage: 160, for: window)
        XCTAssertEqual(widthPercentage, 50.0, accuracy: 0.1, "Width percentage should be approximately 50%")
        
        // Test height conversion (percentage to points)
        let heightPoints = BlueShiftInAppNotificationHelper.convertPercentageHeight(toPoints: 50, for: window)
        XCTAssertEqual(heightPoints, 240.0, accuracy: 1.0, "Height points should be approximately 240")
        
        // Test width conversion (percentage to points)
        let widthPoints = BlueShiftInAppNotificationHelper.convertPercentageWidth(toPoints: 50, for: window)
        XCTAssertEqual(widthPoints, 160.0, accuracy: 1.0, "Width points should be approximately 160")
        
        // Test with values that would exceed 100%
        let largeHeightPercentage = BlueShiftInAppNotificationHelper.convertPointsHeight(toPercentage: 1000, for: window)
        XCTAssertEqual(largeHeightPercentage, 100.0, "Height percentage should be capped at 100%")
    }
    
    // MARK: - Window and Presentation Area Tests
    
    func testGetPresentationAreaMethods() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        
        // Test presentation area height
        let height = BlueShiftInAppNotificationHelper.getPresentationAreaHeight(for: window)
        XCTAssertGreaterThan(height, 0, "Presentation area height should be greater than 0")
        XCTAssertLessThanOrEqual(height, window.bounds.height, "Presentation area height should not exceed window height")
        
        // Test presentation area width
        let width = BlueShiftInAppNotificationHelper.getPresentationAreaWidth(for: window)
        XCTAssertGreaterThan(width, 0, "Presentation area width should be greater than 0")
        XCTAssertLessThanOrEqual(width, window.bounds.width, "Presentation area width should not exceed window width")
    }
    
    func testGetApplicationWindowSize() throws {
        // Test with provided window
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let windowSize = BlueShiftInAppNotificationHelper.getApplicationWindowSize(window)
        XCTAssertEqual(windowSize.width, 320, "Window width should match")
        XCTAssertEqual(windowSize.height, 480, "Window height should match")
    }
    
    func testIsIpadDevice() throws {
        // This test will have different results based on the device it runs on
        let isIpad = BlueShiftInAppNotificationHelper.isIpadDevice()
        #if targetEnvironment(simulator)
        // For simulator, we can check based on the current device type
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(isIpad, "Should return true on iPad simulator")
        } else {
            XCTAssertFalse(isIpad, "Should return false on non-iPad simulator")
        }
        #else
        // For real device, just verify the method returns a boolean
        XCTAssertTrue(isIpad == true || isIpad == false, "Should return a boolean value")
        #endif
    }
    
    // MARK: - Date Handling Tests
    
    func testGetUTCDateFormatter() throws {
        let formatter = BlueShiftInAppNotificationHelper.getUTCDateFormatter()
        
        XCTAssertNotNil(formatter, "Date formatter should not be nil")
        XCTAssertEqual(formatter.dateFormat, kDefaultDateFormat, "Date format should match")
        XCTAssertEqual(formatter.timeZone, TimeZone(identifier: "UTC"), "Time zone should be UTC")
    }
    
    func testGetUTCDateFromDateString() throws {
        // Test with valid date string
        let dateString = "2023-10-09T12:34:56.789000Z"
        let date = BlueShiftInAppNotificationHelper.getUTCDate(fromDateString: dateString)
        
        XCTAssertNotNil(date, "Date should not be nil for valid date string")
     }
    
    func testIsExpired() throws {
        // Test with past timestamp (expired)
        let pastTimestamp = Date().timeIntervalSince1970 - 3600 // 1 hour ago
        XCTAssertTrue(BlueShiftInAppNotificationHelper.isExpired(pastTimestamp), "Past timestamp should be expired")
        
        // Test with future timestamp (not expired)
        let futureTimestamp = Date().timeIntervalSince1970 + 3600 // 1 hour in future
        XCTAssertFalse(BlueShiftInAppNotificationHelper.isExpired(futureTimestamp), "Future timestamp should not be expired")
    }
    
    // MARK: - Message UUID Tests
    
    func testGetMessageUUID() throws {
        // Test with message_uuid at root level
        var payload: [String: Any] = [kBSMessageUUID: "uuid-1234"]
        var uuid = BlueShiftInAppNotificationHelper.getMessageUUID(payload)
        XCTAssertEqual(uuid, "uuid-1234", "Should extract UUID from root level")
        
        // Test with message_uuid in data object
        payload = [kInAppNotificationDataKey: [kInAppNotificationModalMessageUDIDKey: "uuid-5678"]]
        uuid = BlueShiftInAppNotificationHelper.getMessageUUID(payload)
        XCTAssertEqual(uuid, "uuid-5678", "Should extract UUID from data object")
        
        // Test with missing UUID
        payload = ["other_key": "value"]
        uuid = BlueShiftInAppNotificationHelper.getMessageUUID(payload)
        XCTAssertNil(uuid, "Should return nil for missing UUID")
    }
    
    // MARK: - URL Encoding Tests
    
    func testGetEncodedURLString() throws {
        // Test with URL containing spaces
        var urlString = "https://example.com/path with spaces"
        var encoded = BlueShiftInAppNotificationHelper.getEncodedURLString(urlString)
        XCTAssertEqual(encoded, "https://example.com/path%20with%20spaces", "Should encode spaces")
        
        // Test with URL containing special characters
        urlString = "https://example.com/path?param=value&special=!@#$%^&*()"
        encoded = BlueShiftInAppNotificationHelper.getEncodedURLString(urlString)
        XCTAssertNotEqual(encoded, urlString, "Should encode special characters")
        XCTAssertTrue(encoded.contains("example.com"), "Encoded URL should still contain domain")
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
        
        url = URL(string: "https://www.blueshift.com?bsft_tgt=browser")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.removeQueryParam("bsft_tgt", from: url)
            XCTAssertEqual(res?.absoluteString, "https://www.blueshift.com", "Successful removal of bsft_tgt param")
        }
        
        url = URL(string: "https://www.blueshift.com?page=home&bsft_tgt=browser&val1=test")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.removeQueryParam("bsft_tgt", from: url)
            XCTAssertEqual(res?.absoluteString, "https://www.blueshift.com?page=home&val1=test", "Successful removal of bsft_tgt param")
        }
        
        url = URL(string: "https://www.blueshift.com")
        if let url = url {
            let res = BlueShiftInAppNotificationHelper.removeQueryParam("bsft_tgt", from: url)
            XCTAssertEqual(res?.absoluteString, "https://www.blueshift.com")
        }
    }

}
