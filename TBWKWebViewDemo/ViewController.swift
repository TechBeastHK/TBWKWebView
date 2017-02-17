//
//  ViewController.swift
//  TBWKWebViewDemo
//
//  Created by Charles on 16/2/2017.
//  Copyright © 2017 Tech Beast Limited. All rights reserved.
//

import UIKit
import TBWKWebView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let webView = TBWKWebView()
        webView.frame = CGRect(x: 20, y: 20, width: 200, height: 500)
        self.view.addSubview(webView)

        let request = URLRequest(url: URL(string: "https://jigsaw.w3.org/HTTP/300/301.html")!)
        webView.load(request) { (Void) -> (Void) in
            print("loaded! %@", webView.url!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

