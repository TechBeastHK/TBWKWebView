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

        let pref = WKPreferences()
        pref.javaScriptCanOpenWindowsAutomatically = true
        let conf = WKWebViewConfiguration()
        conf.preferences = pref
        self.webView = TBWKWebView(frame: CGRect.zero, configuration: conf)

        NotificationCenter.default.addObserver(forName: TBWKWebView.DidSpawnWebViewNotification, object: nil, queue: nil) { (notification) in
            self.webView = notification.userInfo![TBWKWebView.NewlySpawnedWebViewKey]! as! TBWKWebView
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        XCTAssertEqual(0, self.webView.completionBlocks.count, "Pending completionBlocks not equal to zero: \(self.webView.completionBlocks.count)")
    }
    
    func testEnqueue() {
        self.ex = expectation(description: "")
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) { (webView, navigation, error) in
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
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!))
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

    func testEnqueueBlock() {
        self.ex = expectation(description: "")
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) { (webView, navigation, error) in
            XCTAssertNil(error, "Unexpected navigation error")
            return .complete
        };
        self.webView.enqueue {
            self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com.hk")!), completionHandler: { (webView, navigation, error) -> (TBWKWebViewCompletionType) in
                self.ex.fulfill()
                return .complete
            })
        }
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }


    func testLocalFile() {
        self.ex = expectation(description: "")

        let url = Bundle(for: TBWKWebViewTests.self).url(forResource: "redirectTest", withExtension: "html")
        self.webView.enqueue(URLRequest(url: url!)) { (webView, navigation, error) in
            if self.webView.url?.host?.contains("google.com") ?? false {
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
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) { (webView, navigation, error) in
            i += 1
            return .complete
        }
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.yahoo.com")!)) { (webView, navigation, error) in
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
        self.webView.enqueue(URLRequest(url: URL(string: "https://www.veryverybaddomain.doesnotexistcom")!)) { (webView, navigation, error) in
            XCTAssertNotNil(error, "Expected domain resolve error")
            self.ex.fulfill()
            return .complete
        }
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }

    func testOpenWindow() {
        self.ex = expectation(description: "")
        let url = Bundle(for: TBWKWebViewTests.self).url(forResource: "openInNewWindowTest", withExtension: "html")!
        self.webView.performCallbackAcrossNewlyOpenedWebView = true
        self.webView.enqueue(URLRequest(url: url)) { (webView, navigation, error) in
            if webView.url!.absoluteString.contains("google.com") {
                self.ex.fulfill()
                return .complete
            }
            else {
                return .incomplete
            }
        }
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "Error: \(error)")
        }
    }

}
