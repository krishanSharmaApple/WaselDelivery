//
//  HelpController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/20/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class HelpController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    var support: Support?
    @IBOutlet weak var helpTableView: UITableView!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        Utilities.shouldHideTabCenterView(tabBarController, true)
        addNavigationView()
        self.navigationView?.titleLabel.text = "Help & Support"
        navigationView?.backButton.isHidden = false
        navigationView?.editButton.isHidden = true
        getSupportDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.HELP_SUPPORT_SCREEN)
    }
    
    override func navigateBack(_ sender: Any?) {
        Utilities.shouldHideTabCenterView(tabBarController, false)
        super.navigateBack(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - API Methods
    
    func getSupportDetails() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        Utilities.showHUD(to: self.view, "Confirming...")
        
        _ = ApiManager.shared.apiService.getHelpAndSupportDetails().subscribe(
            onNext: { [weak self](support_) in
                Utilities.hideHUD(from: self?.view)
                self?.support = support_
                self?.helpTableView.reloadData()
        }, onError: { [weak self](error) in
            Utilities.hideHUD(from: self?.view)
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                    
                } else {
                    Utilities.showToastWithMessage(error_.description())
                }
            }
        })
    }
    
// MARK: - UITAbleVeiwDelegate&Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if support != nil {
            return 2
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HelpCell.cellIdentifier(), for: indexPath) as? HelpCell else {
            return UITableViewCell()
        }
        if let support_ = support {
            cell.loadCell(support_, index: indexPath.row)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            if let support_ = support, let mobile = support_.mobile, let url = URL(string: "tel://\(mobile)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        } else {
            if let support_ = support, let email_ = support_.email, let url = URL(string: "mailto:\(email_)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
}

class HelpCell: UITableViewCell {
    
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    class func cellIdentifier() -> String {
        return "HelpCell"
    }
    
    func loadCell(_ help: Support, index: Int) {
        
        contentImageView.image = (index == 0) ? UIImage(named: "mobile") : UIImage(named: "email")
        titleLabel.text = (index == 0) ? "Contact Number" : "Email ID"
        var contentText = ""
        if let mobile_ = help.mobile, index == 0 {
            contentText = mobile_
        }
        if let email_ = help.email, index == 1 {
            contentText = email_
        }
        contentLabel.text = contentText
    }

}
