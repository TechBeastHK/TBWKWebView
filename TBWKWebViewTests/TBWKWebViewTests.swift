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
        XCTAssertEqual(0, self.webView.pendingRequests.count, "Pending requests not equal to zero: \(self.webView.pendingRequests.count)")
    }
    
    func testEnqueue() {
        self.ex = expectation(description: "")
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) {
            self.ex.fulfill()
            return .complete
        };
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }

    func testEnqueueWithDelegate() {
        self.ex = expectation(description: "")

        self.webView.navigationDelegate = self
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!), completionHandler:nil)
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.ex.fulfill()
    }

    func testLocalFile() {
        self.ex = expectation(description: "")

        let url = Bundle(for: TBWKWebViewTests.self).url(forResource: "redirectTest", withExtension: "html")
        self.webView.enqueue(URLRequest(url: url!)) {
            if let hasGoogle = self.webView.url?.host?.contains("google.com"), hasGoogle {
                self.ex.fulfill()
                return .complete
            } else {
                return .incomplete
            }
        }
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }

    func testConsecutiveEnqueue() {
        self.ex = expectation(description: "")
        var i = 0
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) {
            i += 1
            return .complete
        }
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.yahoo.com")!)) {
            XCTAssertEqual(1, i, "Google.com not loaded before Yahoo.com")
            self.ex.fulfill()
            return .complete
        };
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }
}
