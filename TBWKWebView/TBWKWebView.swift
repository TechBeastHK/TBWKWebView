//
//  TBWKWebView.swift
//  TBWKWebView
//
//  Created by Charles on 16/2/2017.
//  Copyright © 2017 Tech Beast Limited. All rights reserved.
//

import UIKit
import WebKit

public typealias TBWKWebViewLoadCompletionBlock = (TBWKWebView, WKNavigation?, Error?) -> (TBWKWebViewCompletionType)

public enum TBWKWebViewCompletionType {
    case complete

    // Indicates that the loaded webpage may have additional JS that would lead to another navigation
    // And that the same completion handler should be called again in the next finish loading.
    case incomplete
}

open class TBWKWebView: WKWebView {

    public static let DidSpawnWebViewNotification = Notification.Name("TBWKWebView.DidSpawnWebViewNotification")
    public static let DidDeinitWebViewNotification = Notification.Name("TBWKWebView.DidDeinitWebViewNotification")
    public static let NewlySpawnedWebViewKey = "TBWKWebView.NewlySpawnedWebViewKey"

    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        setupDelegates()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder);
        setupDelegates()
    }

    private func setupDelegates() {
        // needed to trigger the setter once
        self.navigationDelegate = nil
        self.uiDelegate = nil
    }

    // Inherits the enqueued completion blocks and flags from another webView
    public convenience init(frame: CGRect, configuration: WKWebViewConfiguration, inheriting webView:TBWKWebView) {
        self.init(frame: frame, configuration: configuration)
        self.completionBlocks = webView.completionBlocks // Array is value type! So this is a copy
        self.performCallbackAcrossNewlyOpenedWebView = webView.performCallbackAcrossNewlyOpenedWebView
    }

    // When this is true, your app should listen for TBWKWebView.DidSpawnWebViewNotification in NotificationCenter.default
    // to hold onto the newly spawned web view (in notification.userInfo[TBWKWebView.NewlySpawnedWebViewKey]),
    // such as storing it in a strong variable, or displaying it (views are strongly held).
    // Very often, your original webView is no longer useful and you can set your original holding variable
    // to the new webView, effectively deallocating the original webView.
    // If you do not hold onto the newly spawned web view, it will be deallocated.
    // You can observe TBWKWebView.DidDeinitWebViewNotification to detect deallocation of each TBWKWebView.
    open var performCallbackAcrossNewlyOpenedWebView = false

    // NavigationDelegate
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

    // UIDelegate
    lazy private var internalUIDelegate: TBWKUIDelegate = {
        [unowned self] in
        return TBWKUIDelegate(webView: self)
    }()
    weak fileprivate var externalUIDelegate: WKUIDelegate?
    override weak open var uiDelegate: WKUIDelegate? {
        set {
            self.externalUIDelegate = newValue
            super.uiDelegate = internalUIDelegate
        }
        get {
            return self.externalUIDelegate
        }
    }

    open private(set) var completionBlocks = [(URLRequest?, TBWKWebViewLoadCompletionBlock?)]()
    private var currentNavigation: WKNavigation?
    private var currentExecutingBlock: TBWKWebViewLoadCompletionBlock?

    open func enqueue(_ request: URLRequest, completionHandler: TBWKWebViewLoadCompletionBlock? = nil) {
        completionBlocks.append((request, completionHandler))
        self.attemptFlush()
    }

    open func enqueue(block: @escaping (Void)->(Void)) {
        completionBlocks.append((nil, { (webView, navigation, error) in
            block()
            return .complete
        }))
        self.attemptFlush()
    }

    private func attemptFlush() {
        guard completionBlocks.count > 0 else { return }
        if !self.isLoading && self.currentExecutingBlock == nil {
            let (request, _) = completionBlocks.first!
            if let request = request {
                self.currentNavigation = self.load(request)
            } else {
                self.currentNavigation = nil
                self._webView(self, didNavigate: nil)
            }
        }
    }
    
    fileprivate func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self._webView(webView, didNavigate: navigation)
    }

    fileprivate func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self._webView(webView, didNavigate: navigation, withError: error)
    }

    private func _webView(_ webView: WKWebView, didNavigate navigation: WKNavigation!, withError error: Error? = nil) {
        if let (_, block) = completionBlocks.first {
            self.currentExecutingBlock = block
            let ret = block?(self, navigation, error)
            self.currentExecutingBlock = nil

            if ret == nil || ret! == .complete {
                completionBlocks.removeFirst()
                self.attemptFlush()
            }
        }
    }

    fileprivate func _webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let externalWebView = self.uiDelegate?.webView?(webView, createWebViewWith: configuration, for: navigationAction, windowFeatures: windowFeatures)
        guard self.performCallbackAcrossNewlyOpenedWebView else {
            return externalWebView
        }
        guard let ewv = (externalWebView ?? TBWKWebView(frame: CGRect.zero, configuration: configuration, inheriting: self)) as? TBWKWebView else {
            assertionFailure("Your WKUIDelegate must return a TBWKWebView if you enabled performCallbackAcrossNewlyOpenedWebView!")
            return externalWebView
        }

        NotificationCenter.default.post(Notification(name: TBWKWebView.DidSpawnWebViewNotification, object: self, userInfo: [TBWKWebView.NewlySpawnedWebViewKey: ewv]))

        return ewv
    }


    deinit {
        NotificationCenter.default.post(Notification(name: TBWKWebView.DidDeinitWebViewNotification, object: self))
    }
}

fileprivate class TBWKNavigationDelegate: NSObject, WKNavigationDelegate {
    unowned var webView: TBWKWebView
    
    init(webView: TBWKWebView) {
        self.webView = webView
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.externalNavigationDelegate?.webView?(webView, didFinish: navigation)
        self.webView.webView(webView, didFinish: navigation)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.webView.externalNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
        self.webView.webView(webView, didFail: navigation, withError: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webView.externalNavigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
        self.webView.webView(webView, didFail: navigation, withError: error) // Treat it the same way as didFail
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        // Forwards everything else to the external delegate.
        return self.webView.externalNavigationDelegate
    }

    override func responds(to aSelector: Selector!) -> Bool {
        // Tells WKWebView to call our delegate methods as if we have implemented it
        let myRet = super.responds(to: aSelector)
        return myRet ? myRet : self.webView.externalNavigationDelegate?.responds(to: aSelector) ?? false
    }
}

fileprivate class TBWKUIDelegate: NSObject, WKUIDelegate {
    unowned var webView: TBWKWebView

    init(webView: TBWKWebView) {
        self.webView = webView
        super.init()
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return self.webView._webView(webView, createWebViewWith: configuration, for: navigationAction, windowFeatures: windowFeatures)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        // Forwards everything else to the external delegate.
        return self.webView.externalUIDelegate
    }

    override func responds(to aSelector: Selector!) -> Bool {
        // Tells WKWebView to call our delegate methods as if we have implemented it
        let myRet = super.responds(to: aSelector)
        return myRet ? myRet : self.webView.externalUIDelegate?.responds(to: aSelector) ?? false
    }

}

