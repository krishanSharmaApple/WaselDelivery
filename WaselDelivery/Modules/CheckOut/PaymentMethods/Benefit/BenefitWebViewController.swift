//
//  BenefitWebViewController.swift
//  WaselDelivery
//
//  Created by Radu Ursache on 29/05/2019.
//  Copyright © 2019 [x]cube Labs. All rights reserved.
//

import UIKit

class BenefitWebViewController: UIViewController, UIWebViewDelegate {

    var didFinishPaymentHandler: (() -> ())?
    var didCancelPaymentHandler: (() -> ())?
    var didFailPaymentHandler: (() -> ())?
    var ignoreHud = false
    
    var paymentURL = ""
    
    @IBOutlet weak var webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webview.delegate = self
        self.webview.loadRequest(URLRequest(url: URL(string: self.paymentURL)!))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ignoreHud = true
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.didCancelPaymentHandler?()
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        if !ignoreHud {
            Utilities.showHUD(to: self.view, "Loading")
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if !ignoreHud {
            Utilities.hideHUD(from: self.view)
        }
        
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard let url = request.url?.absoluteString else {
            return true
        }
        
        print("started to load: ", url)
        
        if url.contains("approved.html") {
            self.didFinishPaymentHandler?()
        } else if url.contains("declined.html") {
            self.didFailPaymentHandler?()
        } else if url.contains("error.jsp") {
            self.didFailPaymentHandler?()
        }
        
        return true
    }
}
