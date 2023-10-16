//
//  BlueshiftAppdelegateTests.swift
//  BlueShift_iOS_SDK_Tests
//
//  Created by Ketan Shikhare on 11/10/23.
//

import XCTest
@testable import BlueShift_iOS_SDK

final class BlueshiftAppdelegateTests: XCTestCase {
    var sut: BlueShiftAppDelegate!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = BlueShiftAppDelegate()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testOpenDeepLinkInWebViewBrowser() throws {
        var url = URL(string: "https://www.blueshift.com?bsft_tgt=browser")
        if let url = url {
            let res = sut.openDeepLink(inWebViewBrowser: url, showOpenInBrowserButton: NSNumber(integerLiteral: 1))
            XCTAssertTrue(res, "successfully open url in browser")
        }
        
        url = URL(string: "blueshift://app/home")
        if let url = url {
            let res = sut.openCustomSchemeDeepLinks(url)
            XCTAssertFalse(res, "Failed to open url in browser")
        }
    }
}
