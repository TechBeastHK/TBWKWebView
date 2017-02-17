# TBWKWebView
TBWKWebView is a WKWebView subclass which supports a completion block callback, enqueuing multiple URLRequest and executing them one by one. This is particularly useful for implementing crawler-like functionality from within an iOS app.

# Installation
Copy `TBWKWebView.swift` to your project, or use the entire `TBWKWebView.framework`.

# Usage
```
self.webView = TBWKWebView()

self.webView.enqueue(URLRequest(url: URL(string: "https://www.google.com")!)) { (navigation, error) in
    // The webpage has either been fully loaded (didFinish)
    // or has not been loaded at all (didFail, didFailProvisionalNavigation)

    // Check error == nil and handle the rest
    
    // Check self.webView.url and see if it has arrived at a page that you expected
    // If you are done, return .complete to let the webView process the next enqueued URLRequest
    return .complete

    // If you are not yet done (e.g. you are waiting for the loaded JS to perform another navigation)
    // you can return .incomplete and the webView will call the very same callback next time
    // it encounter didFinish, didFail or didFailProvisionalNavigation delegate calls.
    //return .incomplete
};

// You can enqueue multiple URLRequest - they will be sequentially loaded.

self.webView.enqueue(URLRequest(url: URL(string: "https://some.page.to.visit.after.visiting.google.com")!), completionHandler:nil) 
```
Take a look at the unit tests as well.
