//
//  TBWKWebView.swift
//  TBWKWebView
//
//  Created by Charles on 16/2/2017.
//  Copyright © 2017 Tech Beast Limited. All rights reserved.
//

import UIKit
import WebKit

public typealias TBWKWebViewLoadCompletionBlock = (WKNavigation, Error?) -> (TBWKWebViewCompletionType)

public enum TBWKWebViewCompletionType {
    case complete

    // Indicates that the loaded webpage may have additional JS that would lead to another navigation
    // And that the same completion handler should be called again in the next finish loading.
    case incomplete
}

open class TBWKWebView: WKWebView {

    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        self.navigationDelegate = nil // setup internalNavigationDelegate
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.navigationDelegate = nil // setup internalNavigationDelegate
    }

    lazy private var internalNavigationDelegate: TBWKNavigationDelegate = {
        [unowned self] in
        return TBWKNavigationDelegate(webView: self)
    }()

    weak fileprivate var externalNavigationDelegate: WKNavigationDelegate?
    override weak open var navigationDelegate: WKNavigationDelegate? {
        set {
            self.externalNavigationDelegate = newValue
            super.navigationDelegate = internalNavigationDelegate
        }
        get {
            return self.externalNavigationDelegate
        }
    }

    open var pendingRequests: [URLRequest] {
        get {
            return self.completionBlocks.map { $0.0 }
        }
    }

    private var completionBlocks = [(URLRequest, TBWKWebViewLoadCompletionBlock?)]()
    private var currentNavigation: WKNavigation?

    open func enqueue(_ request: URLRequest, completionHandler: TBWKWebViewLoadCompletionBlock? = nil) {
        completionBlocks.append((request, completionHandler))
        self.attemptFlush()
    }

    private func attemptFlush() {
        guard completionBlocks.count > 0 else { return }
        if !self.isLoading {
            let (request, _) = completionBlocks.first!
            self.currentNavigation = self.load(request)
        }
    }
    
    fileprivate func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self._webView(webView, didFail: navigation)
    }

    fileprivate func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self._webView(webView, didFail: navigation, withError: error)
    }

    private func _webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error? = nil) {
        if let (_, block) = completionBlocks.first {
            let ret = block?(navigation, error)

            if ret == nil || ret! == .complete {
                completionBlocks.removeFirst()
                self.attemptFlush()
            }
        }
    }

    deinit {
        print("deinit TBWKWebView: \(self)")
    }
}

fileprivate class TBWKNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var webView: TBWKWebView?
    
    init(webView: TBWKWebView) {
        self.webView = webView
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView?.externalNavigationDelegate?.webView?(webView, didFinish: navigation)
        self.webView?.webView(webView, didFinish: navigation)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.webView?.externalNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
        self.webView?.webView(webView, didFail: navigation, withError: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webView?.externalNavigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
        self.webView?.webView(webView, didFail: navigation, withError: error) // Treat it the same way as didFail
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        // Forwards everything else to the external delegate.
        return self.webView?.externalNavigationDelegate
    }

    override func responds(to aSelector: Selector!) -> Bool {
        // Tells WKWebView to call our delegate methods as if we have implemented it
        let myRet = super.responds(to: aSelector)
        return myRet ? myRet : self.webView?.externalNavigationDelegate?.responds(to: aSelector) ?? false
    }
}
