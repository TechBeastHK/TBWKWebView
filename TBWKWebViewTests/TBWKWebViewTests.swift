//
//  TBWKWebViewTests.swift
//  TBWKWebViewTests
//
//  Created by Charles on 16/2/2017.
//  Copyright © 2017 Tech Beast Limited. All rights reserved.
//

import XCTest
@testable import TBWKWebView

class TBWKWebViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let webView = TBWKWebView()
        let ex = expectation(description: "Expects completion handler to be called")
        webView.load(URLRequest(url: URL(string: "https://www.google.com")!)) {
            ex.fulfill()
        };
        waitForExpectations(timeout: 10) { (error) in
            print("Expectation error \(error)")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}