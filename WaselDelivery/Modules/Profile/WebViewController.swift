//
//  WebViewController.swift
//  WaselDelivery
//
//  Created by sunanda on 1/20/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: BaseViewController, WKUIDelegate, WKNavigationDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!
    var navTitle: String = ""
    var url: String?
    private var wkWebView: WKWebView!
    let tosString = "Terms Of Service"

    override func viewDidLoad() {
        super.viewDidLoad()
        addNavigationView()
        self.navigationView?.titleLabel.text = navTitle
        let isIphoneX = Utilities.shared.isIphoneX()
        let navigationHeight_: CGFloat = (true == isIphoneX) ? 88.0 : 64.0
        wkWebView = WKWebView(frame: CGRect(x: 0.0, y: navigationHeight_, width: ScreenWidth, height: ScreenHeight - navigationHeight_ - ((true == isIphoneX) ? 30.0 : 0.0)), configuration: WKWebViewConfiguration())
        wkWebView.uiDelegate = self
        wkWebView.navigationDelegate = self
        view.addSubview(wkWebView)
        view.bringSubviewToFront(activityIndicator)
        if Utilities.shared.isNetworkReachable() {
            loadWebView()
        } else {
            showNoInternetMessage()
        }
        navigationHeightConstraint.constant = navigationHeight_
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if tosString == navTitle {
            UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.TERMSOFSERVICES_SCREEN)
        } else {
            UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.PRIVACY_POLICY_SCREEN)
        }
    }

    private func loadWebView() {
        if let url_ = url {
            let aUrl_ = URL(string: url_) ?? URL(fileURLWithPath: "")
            let request = URLRequest(url: aUrl_)
            wkWebView.load(request)
            activityIndicator.startAnimating()
        }
    }

// MARK: - UIWebViewDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url_ = navigationAction.request.url, (url_.relativeString.hasPrefix("http") || url_.relativeString.hasPrefix("https") || url_.relativeString.hasPrefix("mailto")), navigationAction.navigationType == .linkActivated {
            UIApplication.shared.openURL(url_)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }
    
}
