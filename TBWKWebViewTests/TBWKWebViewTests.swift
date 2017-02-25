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
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) { (navigation, error) in
            XCTAssertNil(error, "Unexpected navigation error")
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
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!), completionHandler: nil)
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }
    // Test that internally implemented delegate calls get forwarded to the external delegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.ex.fulfill()
    }
    // Test that internally unimplemented delegate calls get forwarded to the external delegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }


    func testLocalFile() {
        self.ex = expectation(description: "")

        let url = Bundle(for: TBWKWebViewTests.self).url(forResource: "redirectTest", withExtension: "html")
        self.webView.enqueue(URLRequest(url: url!)) { (navigation, error) in
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
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) { (navigation, error) in
            i += 1
            return .complete
        }
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.yahoo.com")!)) { (navigation, error) in
            XCTAssertEqual(1, i, "Google.com not loaded before Yahoo.com")
            self.ex.fulfill()
            return .complete
        };
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }

    func testFail() {
        self.ex = expectation(description: "")
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.veryverybaddomain.doesnotexistcom")!)) { (navigation, error) in
            XCTAssertNotNil(error, "Expected domain resolve error")
            self.ex.fulfill()
            return .complete
        }
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }

}
