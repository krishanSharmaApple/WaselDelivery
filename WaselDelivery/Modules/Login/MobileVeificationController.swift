//
//  MobileVeificationController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 07/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import IQKeyboardManagerSwift
import Upshot

class MobileVeificationController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var dummyField: UITextField!
    @IBOutlet var labelCollection: [UILabel]!
    @IBOutlet weak var addCardBgView: UIView!
    @IBOutlet weak var skipButton: UIButton!

    @IBOutlet weak var scrollBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var skipButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var dummyFieldBottomConstraint: NSLayoutConstraint!
    var mobileNumber: String = ""
    var countryCode: CountryCode?
    
    fileprivate var disposeObj: Disposable?
    var disposableBag = DisposeBag()
    var isFromForgotPassword: Bool = false
    var registration: Registration?
    
    var isFromManageProfile = false
    var isFromCheckout = false
    var mobileVerificationDelegate:  MobileVerificationDelegate?

// MARK: - ViewLifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        
        for label in labelCollection {
            label.layer.borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0).cgColor
        }

        // keyboard notifications
        _ = registerForKeyboardDidShowNotification(scrollBottomConstraint, shouldUseTabHeight: false)
        _ = registerForKeyboardWillHideNotification(scrollBottomConstraint)
        
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.size.width, height: 355.0)
        
        registration?.mobile = mobileNumber
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshKeyboardEvents), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        skipButtonBottomConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 10.0 : 30.0
        skipButton.clipsToBounds = true
        skipButton.layer.cornerRadius = 4.0
        skipButton.layer.borderWidth = 1.0
        skipButton.layer.borderColor =  UIColor(red: (241.0/255.0), green: (241.0/255.0), blue: (241.0/255.0), alpha: 1.0).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = false
        if true == self.addCardBgView.isHidden {
            dummyField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.enable = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.MOBILENUMBER_VERIFICATION_SCREEN)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - IBActions
    
    @IBAction func resendOTP(_ sender: Any) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        var codeString = ""
        if isFromForgotPassword == false {
            if let reg_ = registration, let code_ = reg_.countryCode {
                codeString = code_.code
            }
        } else {
            if let code_ = countryCode {
                codeString = code_.code
            }
        }
        
        dummyField.resignFirstResponder()
        Utilities.showHUD(to: view, nil)
        var newUserValue = false//isFromForgotPassword ? false : !(registration?.shouldSync ?? true)//can optimise but not touching as per current circumstances
        if isFromForgotPassword {
            newUserValue = false
        } else {
            if let reg_ = registration {
                newUserValue = !reg_.shouldSync
            }
        }
        ApiManager.shared.apiService.generateOTP(["countryCode": codeString as AnyObject, "mobile": mobileNumber as AnyObject, "isNewUser": newUserValue  as AnyObject ]).subscribe(onNext: { [weak self](_) in
            Utilities.hideHUD(from: self?.view)
            self?.dummyField.becomeFirstResponder()
            Utilities.showToastWithMessage("OTP has been sent to your mobile number.", position: .middle)
        }, onError: { [weak self](error) in
            self?.dummyField.becomeFirstResponder()
            Utilities.hideHUD(from: self?.view)
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                    
                } else {
                    Utilities.showToastWithMessage(error_.description(), position: .middle)
                }
            } else {
                Utilities.showToastWithMessage(error.localizedDescription, position: .middle)
            }
        }).disposed(by: disposableBag)
    }
    
    @IBAction func proceed(_ sender: Any) {
        
        let count = dummyField.text?.count
        guard count == 4 else {
            Utilities.showToastWithMessage("Please enter valid verification code number.", position: .middle)
            return
        }
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        var codeString = ""
        if isFromForgotPassword == false {
            if let reg_ = registration, let code_ = reg_.countryCode {
                codeString = code_.code
            }
        } else {
            if let code_ = countryCode {
                codeString = code_.code
            }
        }
        
        let userInfo = BKUserInfo.init()
        let infoDict = ["UserCountry": codeString]
        userInfo.others = infoDict
        userInfo.build(completionBlock: nil)
        
        dummyField.resignFirstResponder()
        Utilities.showHUD(to: view, nil)
        var loginType = "Login"
        if nil != registration {
            loginType = "Register"
        }

        disposeObj = ApiManager.shared.apiService.verifyOTP(["countryCode": codeString as AnyObject, "mobile": mobileNumber as AnyObject, "otp": dummyField.text as AnyObject ])
            .subscribe(onNext: { [weak self](isSuccess) in
            Utilities.hideHUD(from: self?.view)
            if isSuccess {
                let params = ["State": (nil != Utilities.shared.user) ? "Login" : loginType, "Status": "Success"]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.OTPSTATUS_EVENT, params: params)

//                self?.clearOTP()
                if self?.isFromForgotPassword == true {
                    let resetVC = ResetPasswordController.instantiateFromStoryBoard(.login)
                    resetVC.mobileNumber = self?.mobileNumber
                    self?.navigationController?.pushViewController(resetVC, animated: true)
                } else {
                    if self?.registration?.shouldSync == true {
                        self?.syncUser()
                    } else {
                        self?.registerUser()
                    }
                }
            } else {
                let params = ["State": (nil != Utilities.shared.user) ? "Login" : loginType, "Status": "Fail"]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.OTPSTATUS_EVENT, params: params)

                self?.dummyField.becomeFirstResponder()
                self?.clearOTP()
                Utilities.showToastWithMessage("Please enter valid verification code number.", position: .middle)
            }
        }, onError: { [weak self](error) in
            let params = ["State": (nil != Utilities.shared.user) ? "Login" : loginType, "Status": "Fail"]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.OTPSTATUS_EVENT, params: params)

            self?.dummyField.becomeFirstResponder()
            self?.clearOTP()
            self?.showError(error)
        })
        disposeObj?.disposed(by: disposableBag)
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        self.addCardBgView.isHidden = true
        dummyFieldBottomConstraint.constant = 33.0
        self.navigateToNextScreen()
    }
    
    @IBAction func addCardButtonAction(_ sender: Any) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: NSLocalizedString("For verification purpose a refundable amount of .100 fils may be charged on your credit card.", comment: ""), buttonText: "NO", cancelButtonText: "YES")
        responder.addCancelAction({
            self.dummyField.resignFirstResponder()
            /*self.initiatePayTabsSDK(isBenefitPay: false, tokenString: "", customerPassword: "", isTokenization: true, order_: nil, isDefaultCard: true, shouldAddNewCard: false, grandTotal: 0.300) { (isTransactionCompleted) in
                self.addCardBgView.isHidden = isTransactionCompleted
                self.dummyFieldBottomConstraint.constant = 0.0
                if true == isTransactionCompleted {
                    Utilities.showToastWithMessage("Card has been added successfully", position: .middle)
                    self.navigateToNextScreen()
                }
            }
            self.view.addSubview(self.initialSetupViewController.view)
            self.addChild(self.initialSetupViewController)
            self.initialSetupViewController.didMove(toParent: self)*/
            self.addMasterCardFlow { (cards) in
                let addedCard = cards.count > 0
                self.addCardBgView.isHidden = addedCard
                self.dummyFieldBottomConstraint.constant = 0.0
                if addedCard {
                    Utilities.showToastWithMessage("Card has been added successfully", position: .middle)
                    self.navigateToNextScreen()
                }
            }
        })
    }
    
// MARK: - API Methods -
    
    func clearOTP() {
        self.dummyField.text = ""
        for label in labelCollection {
            label.text = "-"
        }
    }
    
    fileprivate func syncUser() {
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        guard let registration_ = registration else {
            return
        }
        Utilities.showHUD(to: nil, "Syncying...")
        var requestParams: [String: AnyObject] = ["mobile": registration_.mobile as AnyObject]
        switch registration_.accountType {
        case .wasel: requestParams["password"] = registration_.password as AnyObject
        case .facebook: requestParams["fid"] = registration_.id as AnyObject
        case .google: requestParams["gid"] = registration_.id as AnyObject
        case .apple: requestParams["aid"] = registration_.id as AnyObject
        }
        guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if let deviceToken_ = appdelegate.deviceToken {
            requestParams[IsAndroidKey] = false as AnyObject
            requestParams[DeviceTokenKey] = deviceToken_ as AnyObject
        }
        disposeObj = ApiManager.shared.apiService.syncUser(requestParams).subscribe(onNext: { [weak self](_) in
            Utilities.hideHUD(from: self?.view)
            self?.proceed()
        }, onError: { [weak self](error) in
            self?.showError(error)
        })
        disposeObj?.disposed(by: disposableBag)
    }
    
    fileprivate func registerUser() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        guard let registration_ = registration else {
            return
        }
        Utilities.showHUD(to: view, "Registering...")
        ApiManager.shared.apiService.registerUser(registration_).subscribe(onNext: { [weak self](_) in
            Utilities.hideHUD(from: self?.view)
            self?.proceed()
            
            let signUpType = self?.registration?.accountType.getAccountTypeString() ?? "SignUp"
            let params = ["RegisterThrough": signUpType, "Status": "Success"]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.REGISTER_EVENT, params: params)
        }, onError: { [weak self](error) in
            let signUpType = self?.registration?.accountType.getAccountTypeString() ?? "Fail"
            let params = ["RegisterThrough": signUpType, "Status": "Success"]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.REGISTER_EVENT, params: params)

            Utilities.hideHUD(from: self?.view)
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                    
                } else {
                    Utilities.showToastWithMessage(error_.description(), position: .middle)
                }
            } else {
                Utilities.showToastWithMessage(error.localizedDescription, position: .middle)
            }
        }).disposed(by: disposableBag)
    }
    
    private func proceed() {
        
        if let currentUser = Utilities.shared.user {
            let userInfo = BKUserInfo.init()
            var infoDict =  [String: Any]()

            if let email = currentUser.email {
                userInfo.email = email
            }
            
            if let userName = currentUser.name {
                userInfo.userName = userName
            }
            if let mobileNumber = currentUser.mobile {
                userInfo.phone = mobileNumber
            }
            if let userId = currentUser.id {
                infoDict["UserId"] = userId                
                if let email = currentUser.email {
                    userInfo.email = email
                }
                
                if let userName = currentUser.name {
                    userInfo.userName = userName
                }
                if let mobileNumber = currentUser.mobile {
                    userInfo.phone = mobileNumber
                }
                if let userId = currentUser.id {
                    infoDict["UserId"] = userId
                    let externalId = BKExternalId.init()
                    externalId.appuID = userId
                    userInfo.externalId = externalId
                }
                infoDict["IsGuestUser"] = "No"
                infoDict["SignInBy"] = currentUser.accountType?.getAccountTypeString()
                
                userInfo.others = infoDict
                userInfo.build(completionBlock: nil)
            }
            userInfo.others = infoDict
            userInfo.build(completionBlock: nil)
        }

        navigateToNextScreen()

//        addCardBgView.isHidden = false
//        dummyFieldBottomConstraint.constant = 0.0
    }
    
    func navigateToNextScreen() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if isFromManageProfile == true {
            _ = navigationController?.popToRootViewController(animated: true)
            mobileVerificationDelegate?.navigateHome()
        } else if isFromCheckout == true {
            navigationController?.dismiss(animated: true, completion: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: ProceedToCheckOutNotification), object: nil)
            })
        } else {
            if Utilities.getUserLocation() == nil {
                let locationVC = LocationViewController.instantiateFromStoryBoard(.main)
                navigationController?.pushViewController(locationVC, animated: true)
            } else {
                let tabBarController = TabBarController.instantiateFromStoryBoard(.main)
                let navController = UINavigationController(rootViewController: tabBarController)
                navController.isNavigationBarHidden = true
                appDelegate.window?.rootViewController = navController
                appDelegate.window?.makeKeyAndVisible()
            }
        }
    }
    
// MARK: - UITextFieldDelegate -
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        var finalText = (text as NSString).replacingCharacters(in: range, with: string)
        guard finalText.count <= 4 else { return false }

        while finalText.count < 4 {
            finalText += "-"
        }

        for (index, char) in finalText.enumerated() {
            labelCollection[index].text = "\(char)"
        }

        return true
    }
    
// MARK: - Keyboard handle events
    
    @objc func refreshKeyboardEvents() {
        // Enabling the keyboard coming to foreground
        if true == self.addCardBgView.isHidden {
            dummyField.becomeFirstResponder()
        }
    }
    
}

protocol MobileVerificationDelegate: class {
    func navigateHome()
}
