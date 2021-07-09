//
//  ManageProfileController.swift
//  WaselDelivery
//
//  Created by Amarnath on 04/12/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import BugfenderSDK
import Upshot

class ManageProfileController: BaseViewController, MobileVerificationDelegate {
    @IBOutlet weak var signInButton: HighlightButton!
    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var versionLabel: UILabel!

    private lazy var refreshControl: UIRefreshControl = {
        var refresh = UIRefreshControl()
        refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.refreshProfile(_:)), for: .valueChanged)
        return refresh
    }()

    var disposableBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        addNavigationView()
        self.navigationView?.titleLabel.text = "Manage Profile"
        self.navigationView?.backButton.isHidden = true
        view.isExclusiveTouch = true
        profileTableView.isExclusiveTouch = true
        self.profileTableView.addSubview(refreshControl)
        self.versionLabel.text = version()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        signInButton.isSelected = Utilities.isUserLoggedIn()
        signInButton.setTitle(signInButton.isSelected ? "Sign out" :"Sign in", for: .normal)//not doing this in xib as button title is not maintaining when button is highlighted
        profileTableView.reloadData()
        Utilities.removeTransparentView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.MANAGE_PROFILE_SCREEN)
    }
    
    func navigateHome() {
        self.tabBarController?.selectedIndex = 0
    }

// MARK: - IBActions
    
    func version() -> String {
        guard let infoDict = Bundle.main.infoDictionary else { return "" }
        guard let version = infoDict["CFBundleShortVersionString"] as? String else { return "" }
        guard let build = infoDict["CFBundleVersion"] as? String else { return "" }
        return "v\(version).\(build)"
    }
    
    @IBAction func editProfile(_ sender: UIButton) {
        let editProfileVC = EditProfileController.instantiateFromStoryBoard(.profile)
        let navC = UINavigationController(rootViewController: editProfileVC)
        navC.isNavigationBarHidden = true
        navigationController?.present(navC, animated: true, completion: nil)
    }
    
    @IBAction func signButtonAction(_ sender: UIButton) {
        if sender.isSelected {
            guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            if let user_ = Utilities.shared.user, let id_ = user_.id, let deviceToken_ = appdelegate.deviceToken {
                var requestObj: [String: Any] = [IdKey: id_ as AnyObject]
                let item: [String: AnyObject] = ["deviceToken": deviceToken_ as AnyObject]
                requestObj["device"] = item as AnyObject?
                logoutUser(requestObj as [String: AnyObject])
            } else {
                logOut()
                return
            }
        } else {
            let loginVC = LoginViewController.instantiateFromStoryBoard(.login)
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let navController = appDelegate?.window?.rootViewController as? UINavigationController
            loginVC.isFromManageProfile = true
            loginVC.mobileVerificationDelegate = self
            navController?.pushViewController(loginVC, animated: true)
        }
    }
    
// MARK: - API Methods
    
    private func logoutUser(_ reqObj: [String: AnyObject]) {
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        Utilities.showHUD(to: self.view, "")
        ApiManager.shared.apiService.logout(reqObj)
            .subscribe(onNext: { [weak self](isSuccess) in
                Utilities.hideHUD(from: self?.view)
                if isSuccess {
                    self?.logOut()
                }
                }, onError: { [weak self](error) in
                    Utilities.hideHUD(from: self?.view)
                    if let error_ = error as? ResponseError {
                        if error_.getStatusCodeFromError() == .accessTokenExpire {
                            
                        } else {
                            Utilities.showToastWithMessage(error_.description())
                        }
                    } else {
                        Utilities.showToastWithMessage(error.localizedDescription)
                    }
            }).disposed(by: disposableBag)
    }
    
    @objc func refreshProfile(_ sender: Any?) {
        guard Utilities.shared.isNetworkReachable() else {
            endRefreshing()
            showNoInternetMessage()
            return
        }
        guard Utilities.isUserLoggedIn() else {
            endRefreshing()
            return
        }
        getUserProfile(isSilentCall: true).subscribe(onNext: { (_) in
            self.endRefreshing()
            self.profileTableView.reloadData()
        }, onError: { (error) in
            if let error_ = error as? ResponseError {
                Utilities.showToastWithMessage(error_.description())
            } else {
                Utilities.showToastWithMessage(error.localizedDescription)
            }
        }).disposed(by: disposableBag)
        
    }

    private func endRefreshing() {
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
    }
    
// MARK: - Support Methods
    
    fileprivate func logOut() {
        Utilities.logoutUser()
        self.signInButton.isSelected = !self.signInButton.isSelected
        self.signInButton.setTitle(self.signInButton.isSelected ? "Sign out" :"Sign in", for: .normal)
        self.profileTableView.reloadData()
        
        let userInfo = BKUserInfo.init()
        let externalId = BKExternalId.init()
        externalId.appuID = ""
        userInfo.externalId = externalId
        
        var infoDict =  [String: Any]()
        infoDict["IsGuestUser"] = "Yes"
        userInfo.others = infoDict

        userInfo.build(completionBlock: nil)
    }
}

extension ManageProfileController: UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Utilities.isUserLoggedIn() ? 8 : 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return (indexPath.row == 0 && Utilities.isUserLoggedIn()) ? 210.0 : 80.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if Utilities.isUserLoggedIn() {
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileViewCell.cellIdentifier(), for: indexPath) as? ProfileViewCell else {
                    return UITableViewCell()
                }
                cell.selectionStyle = .none
                cell.loadCellData()
                return cell
            }
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ManageProfileCell.cellIdentifier(), for: indexPath) as? ManageProfileCell else {
                return UITableViewCell()
            }
            if let profileCellType = ProfileCellType(rawValue: indexPath.row) {
                cell.loadCellWithType(type: profileCellType)
            }
            return cell
            
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ManageProfileCell.cellIdentifier(), for: indexPath) as? ManageProfileCell else {
                return UITableViewCell()
            }
            if let profileCellType = ProfileCellType(rawValue: indexPath.row + 3) {
                cell.loadCellWithType(type: profileCellType)
            }
            return cell
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let userExist = (Utilities.getUser() != nil) ? true : false
        var vc: UIViewController?
        switch indexPath.row {
        case 0:
            if userExist == true {
                break
            }
            vc = OffersController.instantiateFromStoryBoard(.profile)
        case 1:
            if userExist == true {
                vc = ManageAddressController.instantiateFromStoryBoard(.profile)
                break
            }
            vc = WaselController.instantiateFromStoryBoard(.profile)
            if let vc_ = vc as? WaselController {
                vc_.isContactPage = true
            }
        case 2:
            if userExist == true {
                vc = PayTabsCardsViewController.instantiateFromStoryBoard(.profile)
                break
            }
            vc = HelpController.instantiateFromStoryBoard(.profile)
        case 3:
            if userExist == true {
                vc = OffersController.instantiateFromStoryBoard(.profile)
                break
            }
            vc = WaselController.instantiateFromStoryBoard(.profile)
        case 4:
            if userExist == true {
                vc = WaselController.instantiateFromStoryBoard(.profile)
                if let vc_ = vc as? WaselController {
                    vc_.isContactPage = true
                }
                break
            }
            vc = LegalController.instantiateFromStoryBoard(.profile)
        case 5:
            if userExist == true {
                vc = HelpController.instantiateFromStoryBoard(.profile)
                break
            }
            vc = LegalController.instantiateFromStoryBoard(.profile)
        case 6: vc = WaselController.instantiateFromStoryBoard(.profile)
        default: vc = LegalController.instantiateFromStoryBoard(.profile)
        }
        if let vc_ = vc {
            navigationController?.pushViewController(vc_, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
