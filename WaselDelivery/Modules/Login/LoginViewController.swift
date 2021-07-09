//
//  LoginViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 07/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import Upshot
import AuthenticationServices

class LoginViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet var buttonCollection: [UIButton]!
    @IBOutlet weak var mobileField: BottomBorderField!
    @IBOutlet weak var passwordField: BottomBorderField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var socialContainer: UIView!
    @IBOutlet weak var socialStackContainer: UIStackView!
    @IBOutlet weak var dividerContainer: UIView!
    @IBOutlet weak var toolBar: UIToolbar!

    fileprivate var disposableBag = DisposeBag()
    var isFromManageProfile = false
    var isFromCheckout = false
    weak var mobileVerificationDelegate: MobileVerificationDelegate?

// MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        self.navigationView?.titleLabel.text = "Sign in"
        mobileField.inputAccessoryView = toolBar
        passwordField.inputAccessoryView = toolBar
        if #available(iOS 13.0, *) {
            setupAppleLoginView()
        }

        for button in buttonCollection {
            button.isExclusiveTouch = true
        }
        self.view.isExclusiveTouch = true

        if isFromManageProfile || isFromCheckout {
            dividerContainer.isHidden = false
            socialContainer.isHidden = false
            registerButton.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        }
    }
    
    @available(iOS 13.0, *)
    func setupAppleLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton()
        authorizationButton.addTarget(self, action: #selector(loginWithApple), for: .touchUpInside)
        self.socialStackContainer.addArrangedSubview(authorizationButton)
    }

    override func navigateBack(_ sender: Any?) {
        if isFromCheckout {
            navigationController?.dismiss(animated: true, completion: nil)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        passwordField.text = ""
        Utilities.removeTransparentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.LOGIN_SCREEN)
    }
    
// MARK: - Support Methods
    
    fileprivate func takeUserToHome() {
        let storyboard = Utilities.getStoryBoard(forName: .main)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        if isFromManageProfile == true {
            _ = navigationController?.popToRootViewController(animated: true)
        } else if isFromCheckout == true {
            navigationController?.dismiss(animated: true, completion: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: ProceedToCheckOutNotification), object: nil)
            })
        } else {
            if Utilities.getUserLocation() != nil {
                if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController {
                    let navController = UINavigationController(rootViewController: tabBarController)
                    navController.navigationBar.isHidden = true
                    if let window_ = appDelegate.window {
                        window_.rootViewController = navController
                        window_.makeKeyAndVisible()
                    }
                }
            } else {
                let locationController = storyboard.instantiateViewController(withIdentifier: "LocationViewController")
                if let window_ = appDelegate.window {
                    window_.rootViewController = locationController
                    window_.makeKeyAndVisible()
                }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: RefreshOrderHistoryNotification), object: nil, userInfo: nil)
    }
    
    fileprivate func validateUserWithMobileAndEmail(_ user: User, accountType: AccountType) {
        let registration = Registration()
        registration.name = user.name
        registration.id = user.id
        registration.imageUrl = user.imageUrl
        registration.email = user.email
        registration.accountType = accountType
        
        let storyBoard = Utilities.getStoryBoard(forName: .login)
        if let mobileVC = storyBoard.instantiateViewController(withIdentifier: "MobileNumberController") as? MobileNumberController {
            mobileVC.registration = registration
            mobileVC.isFromCheckout = isFromCheckout
            mobileVC.isFromManageProfile = isFromManageProfile
            mobileVC.mobileVerificationDelegate = mobileVerificationDelegate
            navigationController?.pushViewController(mobileVC, animated: true)
        }
    }
    
// MARK: - Service Calls
    
    func showMobileVerifivationScreen(with user: User, andAccountType accountType: AccountType) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        var requestParams: [String: Any] = [
            "uid": user.id as Any,
            "token": user.token as Any,
            "accountType": accountType.rawValue as Any
        ]
        
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
                var infoDict =  [String: Any]()
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
                infoDict["IsGuestUser"] = "No"
                infoDict["SignInBy"] = accountType.getAccountTypeString()

                userInfo.others = infoDict
                userInfo.build(completionBlock: nil)
                
                self?.takeUserToHome()
            } else {
                self?.validateUserWithMobileAndEmail(user, accountType: accountType)
            }
        }, onError: { [weak self] error in
            self?.showError(error)
            let params = ["Status": "Fail", "SignInThrough": accountType.getAccountTypeString()]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SIGNIN_EVENT, params: params)
        }).disposed(by: disposableBag)
    }

// MARK: - IBActions

    @IBAction func dismissKeyBoard(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func login(_ sender: Any) {
        
//        if isFromCheckout && false == Utilities.isWaselDeliveryOpen() {
//            return
//        }

        let mobile = mobileField.text?.trim() ?? ""
        guard mobile.count != 0 else {
            Utilities.showToastWithMessage("Please enter a mobile number.")
            return
        }
        guard passwordField.text?.count != 0 else {
            Utilities.showToastWithMessage("Please enter a password.")
            return
        }
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        view.endEditing(true)
        Utilities.showHUD(to: view, "Logging In...")
        var requestParams: [String: AnyObject] = ["mobile": mobile as AnyObject,
                                                "password": passwordField.text as AnyObject]
        
        guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if let deviceToken_ = appdelegate.deviceToken {
            requestParams[IsAndroidKey] = false as AnyObject
            requestParams[DeviceTokenKey] = deviceToken_ as AnyObject
        }
        ApiManager.shared.apiService.loginUser(requestParams).subscribe(onNext: { [weak self](user) in
            let userInfo = BKUserInfo.init()
            var infoDict =  [String: Any]()
            if let email = user.email {
                userInfo.email = email
            }
            
            if let userName = user.name {
                userInfo.userName = userName
            }
            if let mobileNumber = user.mobile {
                userInfo.phone = mobileNumber
            }
            if let userId = user.id {
                infoDict["UserId"] = userId
                let externalId = BKExternalId.init()
                externalId.appuID = userId
                userInfo.externalId = externalId
            }
            infoDict["IsGuestUser"] = "No"
            infoDict["SignInBy"] = "SignUp"
            Utilities.hideHUD(from: self?.view)
            
            let params = ["Status": "Success", "SignInThrough": "SignUp"]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SIGNIN_EVENT, params: params)
            
            userInfo.others = infoDict
            userInfo.build(completionBlock: nil)
            
            self?.takeUserToHome()
        }, onError: { [weak self](error) in
            let params = ["Status": "Fail", "SignInThrough": "SignUp"]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SIGNIN_EVENT, params: params)
            self?.showError(error)
        }).disposed(by: disposableBag)
    }
    
    @IBAction func forgotPassword(_ sender: Any) {
        
        let storyBoard = Utilities.getStoryBoard(forName: .login)
        if let mobileVC = storyBoard.instantiateViewController(withIdentifier: "MobileNumberController") as? MobileNumberController {
            mobileVC.isFromForgotPassword = true
            self.navigationController?.pushViewController(mobileVC, animated: true)
        }
    }
    
    @IBAction func register(_ sender: Any) {
//        if isFromCheckout && false == Utilities.isWaselDeliveryOpen() {
//            return
//        }
        let registerVC = RegisterViewController.instantiateFromStoryBoard(.login)
        registerVC.isFromCheckout = isFromCheckout
        registerVC.isFromManageProfile = isFromManageProfile
        registerVC.mobileVerificationDelegate = mobileVerificationDelegate
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
// MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == mobileField {
            if Utilities.isStringContainsAlphaAndSpecialCharacters(string) == true {
                return false
            }
        }

        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        
        if textField == mobileField {
            return newLength <= MaxMobileNumberCharacters
        } else {
            return newLength <= MaxPasswordCharacters
        }
    }
    
    @IBAction func loginWithGoogle(_ sender: Any) {
//        if isFromCheckout && false == Utilities.isWaselDeliveryOpen() {
//            return
//        }
        Utilities.showHUD(to: view, "LoggingIn...")
        GoogleAPIClient.shared.delegate = self
        GoogleAPIClient.shared.authenticateUsingGoogle()
    }
    
    @IBAction func loginWithFacebook(_ sender: Any) {
//        if isFromCheckout && false == Utilities.isWaselDeliveryOpen() {
//            return
//        }
        Utilities.showHUD(to: view, "LoggingIn...")
        FacebookAPIClient.shared.delegate = self
        FacebookAPIClient.shared.authenticateIn(self)
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

extension LoginViewController: GoogleAPIClientDelegate, FacebookAPIClientDelegate {

// MARK: - Facebook Login delegates
    
    func facebookClient(_ client: FacebookAPIClient, didSignInFor user: User) {
        Utilities.hideHUD(from: self.view)
        showMobileVerifivationScreen(with: user, andAccountType: .facebook)
    }
    
    func facebookClient(_ client: FacebookAPIClient, didFailedWithError error: Error) {
        Utilities.hideHUD(from: self.view)
        Utilities.showToastWithMessage(error.localizedDescription)
    }
    
// MARK: - Google Login Delegates -
    
    func googleClient(_ client: GoogleAPIClient!, didSignInFor user: User!, withError error: Error!) {
        
        Utilities.hideHUD(from: self.view)
        guard error == nil else {
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
extension LoginViewController: AppleAuthAPIClientDelegate {
    
    func appleAuthClient(_ client: AppleAuthAPIClient, didSignInFor user: User) {
        Utilities.hideHUD(from: self.view)
        showMobileVerifivationScreen(with: user, andAccountType: .apple)
    }
    
    func appleAuthClient(_ client: AppleAuthAPIClient, didFailedWithError error: Error) {
        Utilities.hideHUD(from: self.view)
        Utilities.showToastWithMessage(error.localizedDescription)
    }
}
