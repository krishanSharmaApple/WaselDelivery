//
//  SocialLoginController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 03/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import RxSwift
import Upshot
import AuthenticationServices

class SocialLoginController: BaseViewController {
    
    @IBOutlet var buttonCollection: [UIButton]!
    @IBOutlet weak var loginContainerView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var topViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var socialStackContainer: UIStackView!
    var disposableBag = DisposeBag()
    
    // MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in buttonCollection {
            button.isExclusiveTouch = true
            if button.tag == 10 || button.tag == 20 || button.tag == 30 {//sign in, register, skip
                button.layer.borderWidth = 0.0
//              button.layer.borderColor = UIColor(red: 0.12, green: 0.28, blue: 0.16, alpha: 1.0).cgColor
            }
        }
        view.isExclusiveTouch = true
        
        if #available(iOS 13.0, *) {
            setupAppleLoginView()
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.5, options: [.curveEaseIn], animations: {
            
            self.loginContainerView.alpha = 1.0
        }, completion: nil)
        topViewConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 24.0 : 0.0
    }
    
    @available(iOS 13.0, *)
    func setupAppleLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton()
        authorizationButton.addTarget(self, action: #selector(loginWithApple), for: .touchUpInside)
        self.socialStackContainer.addArrangedSubview(authorizationButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IBActions
    
    @IBAction func skipLogin(_ sender: Any) {
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SKIP_EVENT)
        
        if Utilities.getUserLocation() != nil {
            showTabController()
        } else {
            let storyBoard = Utilities.getStoryBoard(forName: .main)
            let locationVC = storyBoard.instantiateViewController(withIdentifier: "LocationViewController")
            self.navigationController?.pushViewController(locationVC, animated: true)
        }
        
        let userInfo = BKUserInfo.init()
        let infoDict = ["IsGuestUser": "Yes"]
        userInfo.others = infoDict
        userInfo.build(completionBlock: nil)
    }
    
    @IBAction func login(_ sender: Any) {
        let storyBoard = Utilities.getStoryBoard(forName: .login)
        let loginVC = storyBoard.instantiateViewController(withIdentifier: "LoginViewController")
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    @IBAction func register(_ sender: Any) {
        let storyBoard = Utilities.getStoryBoard(forName: .login)
        let registerVC = storyBoard.instantiateViewController(withIdentifier: "RegisterViewController")
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @IBAction func loginWithGoogle(_ sender: Any) {
        Utilities.showHUD(to: view, "LoggingIn...")
        GoogleAPIClient.shared.delegate = self
        GoogleAPIClient.shared.authenticateUsingGoogle()
    }
    
    @IBAction func loginWithFacebook(_ sender: Any) {
        Utilities.showHUD(to: view, "LoggingIn...")
        FacebookAPIClient.shared.delegate = self
        FacebookAPIClient.shared.authenticateIn(self)
    }
    
    func showMobileVerifivationScreen(with user: User, andAccountType accountType: AccountType) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        var requestParams: [String: Any] = ["uid": user.id as AnyObject,
                                            "token": user.token as AnyObject,
                                            "accountType": accountType.rawValue as AnyObject]
        guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if let deviceToken_ = appdelegate.deviceToken {
            requestParams["device"] = [IsAndroidKey: false,
                                       DeviceTokenKey: deviceToken_]
        }
        
        Utilities.showHUD(to: view, "Logging In..")
        ApiManager.shared.apiService.checkUserExistance(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](responseUser) in
            
            Utilities.hideHUD(from: self?.view)
            if responseUser.id != nil {
                
                let params = ["Status": "Success", "SignInThrough": accountType.getAccountTypeString()]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SIGNIN_EVENT, params: params)
                
                let userInfo = BKUserInfo.init()
                var infoDict = ["IsGuestUser": "No", "SignInBy": accountType.getAccountTypeString()]
                //                userInfo.others = infoDict
                //                userInfo.build(completionBlock: nil)
                
                if let email = responseUser.email {
                    userInfo.email = email
                }
                
                if let userName = responseUser.name {
                    userInfo.userName = userName
                }
                if let mobileNumber = responseUser.mobile {
                    userInfo.phone = mobileNumber
                }
                if let userId = responseUser.id {
                    infoDict["UserId"] = userId
                    let externalId = BKExternalId.init()
                    externalId.appuID = userId
                    userInfo.externalId = externalId
                }
                userInfo.others = infoDict
                userInfo.build(completionBlock: nil)
                
                let storyboard = Utilities.getStoryBoard(forName: .main)
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                if Utilities.getUserLocation() != nil {
                    self?.showTabController()
                } else {
                    let locationController = storyboard.instantiateViewController(withIdentifier: "LocationViewController")
                    appDelegate.window?.rootViewController = locationController
                    appDelegate.window?.makeKeyAndVisible()
                }
                
            } else {
                let registration = Registration()
                registration.name = user.name
                registration.id = user.id
                registration.imageUrl = user.imageUrl
                registration.email = user.email
                registration.accountType = accountType
                
                let storyBoard = Utilities.getStoryBoard(forName: .login)
                if let mobileVC = storyBoard.instantiateViewController(withIdentifier: "MobileNumberController") as? MobileNumberController {
                    mobileVC.registration = registration
                    self?.navigationController?.pushViewController(mobileVC, animated: true)
                }
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
    
    private func showTabController() {
        
        let storyboard = Utilities.getStoryBoard(forName: .main)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController {
            let navController = UINavigationController(rootViewController: tabBarController)
            navController.isNavigationBarHidden = true
            appDelegate.window?.rootViewController = navController
            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    @objc func loginWithApple(_ sender: Any) {
        Utilities.showHUD(to: view, "LoggingIn...")
        if #available(iOS 13.0, *) {
            AppleAuthAPIClient.shared.delegate = self
            AppleAuthAPIClient.shared.authenticateIn(self)
        } else {
            Utilities.showToastWithMessage("Not availabale for older iOS version.")
        }
    }
    
}

extension SocialLoginController: GoogleAPIClientDelegate, FacebookAPIClientDelegate {
    
    // MARK: - Facebook Login delegates
    
    func facebookClient(_ client: FacebookAPIClient, didSignInFor user: User) {
        Utilities.hideHUD(from: self.view)
        Utilities.log(user as AnyObject, type: .info)
        showMobileVerifivationScreen(with: user, andAccountType: .facebook)
    }
    
    func facebookClient(_ client: FacebookAPIClient, didFailedWithError error: Error) {
        let params = ["Status": "Fail", "SignInThrough": "Facebook"]
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SIGNIN_EVENT, params: params)
        Utilities.hideHUD(from: self.view)
        Utilities.showToastWithMessage(error.localizedDescription)
    }
    
    // MARK: - Google Login Delegates -
    
    func googleClient(_ client: GoogleAPIClient!, didSignInFor user: User!, withError error: Error!) {
        
        Utilities.hideHUD(from: self.view)
        guard error == nil else {
            let params = ["Status": "Fail", "SignInThrough": "GooglePlus"]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SIGNIN_EVENT, params: params)
            Utilities.showToastWithMessage(error.localizedDescription)
            return
        }
        showMobileVerifivationScreen(with: user, andAccountType: .google)
    }
    
    func googleClient(_ client: GoogleAPIClient!, didDisconnectWithError error: Error!) {
        Utilities.hideHUD(from: self.view)
        Utilities.showToastWithMessage(error.localizedDescription)
    }
    
    func googleClient(_ client: GoogleAPIClient!, present viewController: UIViewController!) {
        Utilities.hideHUD(from: self.view)
        present(viewController, animated: true, completion: nil)
    }
    
    func googleClient(_ client: GoogleAPIClient!, dismiss viewController: UIViewController!) {
        Utilities.hideHUD(from: self.view)
        dismiss(animated: true, completion: nil)
    }
}

@available(iOS 13.0, *)
extension SocialLoginController: AppleAuthAPIClientDelegate {
    
    func appleAuthClient(_ client: AppleAuthAPIClient, didSignInFor user: User) {
        Utilities.hideHUD(from: self.view)
        showMobileVerifivationScreen(with: user, andAccountType: .apple)
    }
    
    func appleAuthClient(_ client: AppleAuthAPIClient, didFailedWithError error: Error) {
        Utilities.hideHUD(from: self.view)
        Utilities.showToastWithMessage(error.localizedDescription)
    }
}

