//
//  WaselController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/20/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class WaselController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var socialTableView: UITableView!
    @IBOutlet weak var socialTableHieghtConstraint: NSLayoutConstraint!
    @IBOutlet weak var aboutUsHeadingLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var aboutUsLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var aboutUsLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!
    var isContactPage: Bool? = false
    var isPaymentFlow: Bool = false
    var paymentUrl: String?
    
    var order_: Order?
    weak var benefitPaymentDelegate: BenefitPaymentDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        Utilities.shouldHideTabCenterView(tabBarController, true)
        addNavigationView()
        navigationView?.backButton.isHidden = false
        navigationView?.editButton.isHidden = true
        if isPaymentFlow {
            socialTableHieghtConstraint.constant = 0.0
            aboutUsHeadingLabelHeightConstraint.constant = 0.0
            aboutUsLabelTopConstraint.constant = 0.0
            aboutUsLabelBottomConstraint.constant = 0.0
            self.navigationView?.titleLabel.text = NSLocalizedString("Benefit", comment: "")
        } else {
            if true == isContactPage {
                socialTableHieghtConstraint.constant = 0.0
                aboutUsHeadingLabelHeightConstraint.constant = 0.0
                self.navigationView?.titleLabel.text = NSLocalizedString("Get in Touch", comment: "")
            } else {
                socialTableHieghtConstraint.constant =  219.0
                aboutUsHeadingLabelHeightConstraint.constant = 14.0
                self.navigationView?.titleLabel.text = NSLocalizedString("About Wasel", comment: "")
            }
        }
        
        if isPaymentFlow {
            self.webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
            self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        }
        
        if Utilities.shared.isNetworkReachable() {
            loadRequest()
        } else {
            showNoInternetMessage()
        }
     }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if true == isContactPage {
            UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.GETIN_TOUCH_SCREEN)
        } else {
            UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.ABOUT_WASEL_SCREEN)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func navigateBack(_ sender: Any?) {
        Utilities.shouldHideTabCenterView(tabBarController, false)
        super.navigateBack(nil)
    }

    private func loadRequest() {
        
        var urlString = baseUrl+"/public/about"
        if true == isContactPage {
            urlString = "https://www.waseldelivery.com/beavendor.html"
        }
        
        if isPaymentFlow {
            urlString = paymentUrl ?? ""
        }
        
        let url_ = URL(string: urlString) ?? URL(fileURLWithPath: "")
        let request = URLRequest(url: url_)
        webView.loadRequest(request)
        activityIndicator.startAnimating()
    }

// MARK: - UIWebViewDelegate
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if let urlString_ = request.url?.absoluteString, urlString_.contains(baseUrl + "/api/v1/paytabs/benefitPayCallBack?is_sucess=") {
            let paymentStatus_ = urlString_.components(separatedBy: "benefitPayCallBack?is_sucess=").last
            debugPrint(paymentStatus_ ?? "")
            if paymentStatus_?.lowercased() == "true" {
                if let aOrder_ = self.order_ {
                    self.benefitPaymentDelegate?.updateBenefitPayTransactionStatus(order_: aOrder_)
                }
            }
            self.navigateBack(nil)
            return false
        }
        return true
    }

// MARK: - UITAbleVeiwDelegate&Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (true == isContactPage) ? 0 : 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WaselSocialCell.cellIdentifier(), for: indexPath) as? WaselSocialCell else {
            return UITableViewCell()
        }
        cell.loadCell(type: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            let fbUrl: URL = URL(string: "fb://profile/100014860331175") ?? URL(fileURLWithPath: "")
            let fbWebUrl: URL = URL(string: "https://m.facebook.com/people/Wasel-Delivery/100014860331175") ?? URL(fileURLWithPath: "")
            openSocialNetworkFor(url: fbUrl, webURL: fbWebUrl)
        case 1:
            let tweeterURL = URL(string: "twitter://user?screen_name=wasel_delivery")
            let tweeterWebURL = URL(string: "https://twitter.com/wasel_delivery")
            openSocialNetworkFor(url: tweeterURL, webURL: tweeterWebURL)
        default:
            let tweeterURL = URL(string: "instagram://user?username=waseldelivery")
            let tweeterWebURL = URL(string: "https://www.instagram.com/waseldelivery/?hl=en")
            openSocialNetworkFor(url: tweeterURL, webURL: tweeterWebURL)
        }
    }
    
    private func openSocialNetworkFor(url: URL!, webURL: URL!) {
        if UIApplication.shared.canOpenURL(url as URL) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url as URL)
            }
        } else {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(webURL as URL, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(webURL as URL)
            }
        }
    }
    
}

class WaselSocialCell: UITableViewCell {
    
    @IBOutlet weak var socialImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    class func cellIdentifier() -> String {
        return "WaselSocialCell"
    }

    func loadCell(type: Int) {
        
        switch type + 1 {
        case 1:
            socialImageView.image = UIImage(named: "facebook")
            titleLabel.text = "Facebook"
        case 2:
            socialImageView.image = UIImage(named: "twitter")
            titleLabel.text = "Twitter"
        default:
            socialImageView.image = UIImage(named: "instagram")
            titleLabel.text = "Instagram"
        }
    }
}

protocol BenefitPaymentDelegate: class {
    func updateBenefitPayTransactionStatus(order_: Order)
}
