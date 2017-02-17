//
//  TBWKWebView.swift
//  TBWKWebView
//
//  Created by Charles on 16/2/2017.
//  Copyright © 2017 Tech Beast Limited. All rights reserved.
//

import UIKit
import WebKit

public typealias TBWKWebViewLoadCompletionBlock = (Void)->(TBWKWebViewCompletionType)

public enum TBWKWebViewCompletionType {
    case Complete

    // Indicates that the loaded webpage may have additional JS that would lead to another navigation
    // And that the same completion handler should be called again in the next finish loading.
    case Incomplete
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

    lazy var internalNavigationDelegate: TBWKNavigationDelegate = {
        [unowned self] in
        return TBWKNavigationDelegate(webView: self)
    }()

    weak var externalNavigationDelegate: WKNavigationDelegate?
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

    open func enqueue(_ request: URLRequest, completionHandler: TBWKWebViewLoadCompletionBlock?) {
        completionBlocks.append((request, completionHandler))
        self.attemptFlush()
    }

    func attemptFlush() {
        guard completionBlocks.count > 0 else { return }
        if !self.isLoading {
            let (request, _) = completionBlocks.first!
            self.currentNavigation = self.load(request)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let (_, block) = completionBlocks.first!
        let ret = block?()

        if ret == nil || ret! == .Complete {
            completionBlocks.removeFirst()
        }
    }
}

class TBWKNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var webView: TBWKWebView?
    
    init(webView: TBWKWebView) {
        self.webView = webView
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView?.externalNavigationDelegate?.webView?(webView, didFinish: navigation)
        self.webView?.webView(webView, didFinish: navigation)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        // Forwards everything else to the external delegate.
        return self.webView?.externalNavigationDelegate
    }
}
