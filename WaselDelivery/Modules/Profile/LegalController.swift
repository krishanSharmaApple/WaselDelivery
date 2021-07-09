//
//  LegalController.swift
//  WaselDelivery
//
//  Created by sunanda on 1/20/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class LegalController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var legalTableView: UITableView!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        addNavigationView()
        self.navigationView?.titleLabel.text = "Legal"
        Utilities.shouldHideTabCenterView(tabBarController, true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
    }
    
    override func navigateBack(_ sender: Any?) {
        Utilities.shouldHideTabCenterView(tabBarController, false)
        super.navigateBack(nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.LEGAL_SCREEN)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - UITAbleVeiwDelegate&Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LegalCell.cellIdentifier(), for: indexPath) as? LegalCell else {
            return UITableViewCell()
        }
        cell.loadCell(index: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let waselVC = WebViewController.instantiateFromStoryBoard(.profile)
        if indexPath.row == 0 {
            waselVC.navTitle = "Terms Of Service"
            waselVC.url = baseUrl+"/public/terms"
        } else {
            waselVC.navTitle = "Privacy Policy"
            waselVC.url = baseUrl+"/public/privacy"
        }
        navigationController?.pushViewController(waselVC, animated: true)
    }
}

class LegalCell: UITableViewCell {
    
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    class func cellIdentifier() -> String {
        return "LegalCell"
    }
    
    func loadCell(index: Int) {
        
        switch index {
        case 0 :
            titleLabel.text = "Terms Of Service"
            titleImage.image = UIImage(named: "termsOfService")
        default:
            titleLabel.text = "Privacy Policy"
            titleImage.image = UIImage(named: "privacyPolicy")
        }
    }
}
