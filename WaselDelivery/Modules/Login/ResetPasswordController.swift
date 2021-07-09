//
//  ResetPasswordController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 09/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class ResetPasswordController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var confirmPasswordField: BottomBorderField!
    @IBOutlet weak var passwordField: BottomBorderField!
    var mobileNumber: String?
    var disposableBag = DisposeBag()

// MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addNavigationView()
        navigationView?.titleLabel.text = "Reset Password"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.RESET_PASSWORD_SCREEN)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - IBAction
    
    @IBAction func save(_ sender: Any) {
        view.endEditing(true)
        
        guard let password_ = passwordField.text, password_.count > 0 else {
            Utilities.showToastWithMessage("Please enter a password.")
            return
        }
        
        guard let confirmPassword_ = confirmPasswordField.text, confirmPassword_.count > 0 else {
            Utilities.showToastWithMessage("Please enter confirmation password.")
            return
        }
        
        guard password_.count >= 6 || confirmPassword_.count >= 6  else {
            Utilities.showToastWithMessage("Password must be at least 6 characters in long.")
            return
        }
        guard password_ == confirmPassword_ else {
            Utilities.showToastWithMessage("Password and Confirm Password must match.")
            return
        }

        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        guard let mobileNumber_ = mobileNumber else {
            Utilities.showToastWithMessage("Please choose moile number.")
            return
        }
        
        view.endEditing(true)

        Utilities.showHUD(to: view, "Updating...")
        ApiManager.shared.apiService.savePassword(["mobile": "\(mobileNumber_)", "password": password_])
            .subscribe(onNext: { [weak self](isSuccess) in
                Utilities.hideHUD(from: self?.view)
                if isSuccess {
                    let params = ["Status": "Success"]
                    UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.FORGOT_PASSWORD_EVENT, params: params)
                    
                    Utilities.showToastWithMessage("Your password has been changed successfully.")
                    if let tabBarController = (self?.navigationController?.presentingViewController as? UINavigationController)?.viewControllers.first as? TabBarController, 2 == tabBarController.selectedIndex {
                        _ = self?.navigationController?.popToRootViewController(animated: true)
                    } else {
                        if let aViewController = self?.navigationController?.viewControllers[1] {
                            _ = self?.navigationController?.popToViewController(aViewController, animated: true)
                        }
                    }
                } else {
                    let params = ["Status": "Fail"]
                    UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.FORGOT_PASSWORD_EVENT, params: params)
                }
            }, onError: { [weak self](error) in
                let params = ["Status": "Fail"]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.FORGOT_PASSWORD_EVENT, params: params)
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
    
// MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        
        if let text_ = textField.text, text_.count == 0 {
            let charactesAllowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
            let isValidCharacter = (charactesAllowed.contains(string)) ? true : false
            return isValidCharacter
        }
        let isSpace = (string == " ") ? true : false
        return !isSpace && newLength <= MaxPasswordCharacters
    }
    
}
