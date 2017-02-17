//
//  TBWKWebViewTests.swift
//  TBWKWebViewTests
//
//  Created by Charles on 16/2/2017.
//  Copyright © 2017 Tech Beast Limited. All rights reserved.
//

import XCTest
import WebKit
@testable import TBWKWebView

class TBWKWebViewTests: XCTestCase, WKNavigationDelegate {
    var webView: TBWKWebView!
    var ex: XCTestExpectation!

    override func setUp() {
        super.setUp()

        self.webView = TBWKWebView()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEnqueue() {
        self.ex = expectation(description: "")
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) {
            self.ex.fulfill()
            return .Complete
        };
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertEqual(0, self.webView.pendingRequests.count, "Pending requests not equal to zero: \(self.webView.pendingRequests.count)")
        }
    }

    func testEnqueueWithDelegate() {
        self.ex = expectation(description: "")

        self.webView.navigationDelegate = self
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!), completionHandler:nil)
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertEqual(0, self.webView.pendingRequests.count, "Pending requests not equal to zero: \(self.webView.pendingRequests.count)")
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.ex.fulfill()
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
