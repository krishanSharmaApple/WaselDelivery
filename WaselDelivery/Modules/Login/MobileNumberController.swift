//
//  MobileNumberController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 07/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

struct CountryCode: Equatable, Hashable {
    
    var name: String = ""
    var code: String = ""
    
    var hashValue: Int {
        return name.hashValue ^ code.hashValue
    }
    
    static func == (lhs: CountryCode, rhs: CountryCode) -> Bool {
        return lhs.name == rhs.name && lhs.code == rhs.code
    }

}

class MobileNumberController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var countryCodeTableView: UITableView!
    @IBOutlet weak var countryCodesView: UIView!
    @IBOutlet weak var passwordLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var passwordHeaderLabel: UILabel!
    @IBOutlet weak var mobileNumberField: UITextField!
    @IBOutlet weak var phoneView: UIView!
    @IBOutlet weak var countryCodeLabel: UILabel!

    fileprivate var disposableBag = DisposeBag()
    fileprivate var shouldShowEmailField = false
    var isFromForgotPassword = false
    var registration: Registration?
    var isFromManageProfile = false
    var isFromCheckout = false
    var mobileVerificationDelegate: MobileVerificationDelegate?
    var selectedCode: CountryCode?
    
    var countryCodes: [CountryCode]?
    var currentList = [CountryCode]()
    
// MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        self.view.layoutIfNeeded()
        passwordLeadingConstraint.constant = (ScreenWidth - 260) / 2
        if isFromForgotPassword == false {
            if let registration_ = registration, let email_ = registration_.email, email_.count > 0 {
                mobileNumberField.becomeFirstResponder()
            } else {
                shouldShowEmailField = true
                passwordLeadingConstraint.constant = 0.0
            }
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()            
        }
        
        if shouldShowEmailField == true {
            emailView.isHidden = false
            passwordHeaderLabel.isHidden = true
        }
        getCountryCodes()
        countryCodeLabel.text = selectedCode?.code
        countryCodeTableView.estimatedRowHeight = 44.0
        countryCodeTableView.rowHeight = UITableView.automaticDimension
        countryCodeTableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.ENTER_MOBILE_NUMBER_SCREEN)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
        
// MARK: - IBActions

    @IBAction func proceed(_ sender: Any) {

        view.endEditing(true)
        
        var email = registration?.email ?? ""
        
        if shouldShowEmailField == true {
            if let email_ = registration?.email, email_.trim().count > 0 {
                guard Utilities.isValidEmail(testStr: email_) == true else {
                    Utilities.showToastWithMessage("Please enter valid email.")
                    return
                }
                registration?.email = email_
                email = email_
            } else {
                Utilities.showToastWithMessage("Please enter an email address.")
                return
            }
        }
        
        guard let mobile = mobileNumberField.text, mobile.trim().count > 0 else {
            Utilities.showToastWithMessage("Please enter mobile number.")
            return
        }
        
        guard let selectedCode_ = selectedCode else {
            Utilities.showToastWithMessage("Please select country code.")
            return
        }

        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        Utilities.showHUD(to: view, nil)
        
        if isFromForgotPassword {
            callGenerateOTPService(countryCode: selectedCode_, mobile: mobile, isNewUser: !isFromForgotPassword)
        } else {
            callValidateUserService(countryCode: selectedCode_, mobile: mobile, email: email)
        }
    }
    
    @IBAction func showCountryCodes(_ sender: Any) {
        
        if nil == countryCodes {
            getCountryCodes()
            showCountryCodePopUp()
            return
        }
        showCountryCodePopUp()
    }

    @IBAction func filter(_ sender: UITextField) {
        
        guard let countryCodes_ = countryCodes else {
            return
        }
        if let text_ = sender.text, text_.trim().count > 0 {
            let filtered = countryCodes_.filter { $0.name.localizedCaseInsensitiveContains(text_) }
            currentList = filtered
        } else {
            currentList = countryCodes_
        }
        countryCodeTableView.reloadData()
    }
    
    @IBAction func updateCountryCode(_ sender: Any) {
        
        searchField.text = ""
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: {
            self.countryCodesView.alpha = 0.0
        })
        countryCodesView.removeFromSuperview()
        view.addSubview(countryCodesView)
        countryCodeLabel.text = selectedCode?.code
    }
    
// MARK: - Support Methods
    
    fileprivate func callGenerateOTPService(countryCode: CountryCode, mobile: String, isNewUser: Bool) {
        
        Utilities.showHUD(to: view, "")
        ApiManager.shared.apiService.generateOTP(["countryCode": countryCode.code as AnyObject, "mobile": mobile as AnyObject, "isNewUser": isNewUser as AnyObject ]).subscribe(onNext: { [weak self](_) in
            Utilities.hideHUD(from: self?.view)
            Utilities.showToastWithMessage("OTP has been sent to your mobile number.")
            let storyBoard = Utilities.getStoryBoard(forName: .login)
            if let mobileVC = storyBoard.instantiateViewController(withIdentifier: "MobileVeificationController") as? MobileVeificationController {
                mobileVC.mobileNumber = mobile
                mobileVC.countryCode = countryCode
                self?.registration?.countryCode = countryCode
                mobileVC.registration = self?.registration
                mobileVC.isFromForgotPassword = self?.isFromForgotPassword ?? false
                mobileVC.isFromCheckout = self?.isFromCheckout ?? false
                mobileVC.isFromManageProfile = self?.isFromManageProfile ?? false
                mobileVC.mobileVerificationDelegate = self?.mobileVerificationDelegate
                self?.navigationController?.pushViewController(mobileVC, animated: true)
            }
            }, onError: { [weak self](error) in
                self?.showError(error)
        }).disposed(by: disposableBag)
    }
    
    fileprivate func callValidateUserService(countryCode: CountryCode, mobile: String, email: String) {
        ApiManager.shared.apiService.validateUser(["mobile": mobile, "email": email]).subscribe(onNext: { [weak self] (response) in
            Utilities.hideHUD(from: self?.view)
            self?.getUserConfirmationOnSync(response: response, countryCode: countryCode, enteredMobileNumber: mobile, enteredEmail: email)
        }, onError: { [weak self] (error) in
            self?.showError(error)
        }).disposed(by: disposableBag)
    }
    
    fileprivate func getUserConfirmationOnSync(response: [String: AnyObject], countryCode: CountryCode, enteredMobileNumber: String, enteredEmail: String) {
        if let message_ = response["message"] as? String, let flag_ = response["flag"] as? Int {
            if flag_ == 1 {
                callGenerateOTPService(countryCode: countryCode, mobile: enteredMobileNumber, isNewUser: true)
            } else {
                let mobile_ = response["mobile"] as? Int64 ?? 0
                let email_ = response["email"] as? String ?? ""
                let mobileString = "\(mobile_)"
                
                let popupVC = PopupViewController()
                let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: message_, buttonText: "Cancel", cancelButtonText: "Proceed")
                responder.addCancelAction({
                    DispatchQueue.main.async(execute: {
                        
                        self.registration?.email = flag_ == 4 ? enteredEmail : email_
                        self.registration?.mobile = flag_ == 4 ? enteredMobileNumber : mobileString
                        self.emailTextField.text = self.registration?.email
                        self.mobileNumberField.text = self.registration?.mobile
                        self.registration?.shouldSync = true
                        self.callGenerateOTPService(countryCode: countryCode, mobile: self.registration?.mobile ?? "", isNewUser: false)
                    })
                })
            }
        } else {
            Utilities.hideHUD(from: view)
            Utilities.showToastWithMessage("Invalid response")
        }
    }
    
    private func getCountryCodes() {
        if let path = Bundle.main.path(forResource: "CountryCode", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
            var codes = [CountryCode]()
            for (key, value) in dict {
                codes.append(CountryCode(name: key, code: value))
            }
            countryCodes = codes
            let selectedCodes = codes.filter { $0.code == "+973" }.compactMap { $0 }
            if let selectedCode_ = selectedCodes.first {
                selectedCode = selectedCode_
            }
            countryCodes = countryCodes?.filter { $0.code == "+973" } // OTP available only in Bahrain
            countryCodes = countryCodes?.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    private func showCountryCodePopUp() {
        countryCodesView.frame.size = CGSize(width: ScreenWidth, height: ScreenHeight)
        if true == Utilities.shared.isIphoneX() {
            let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
            var aFrame = countryCodesView.frame
            aFrame.origin.y = statusBarHeight
            aFrame.size.height = ScreenHeight - statusBarHeight
            countryCodesView.frame = aFrame
        }
        if let countryCodes_ = countryCodes {
            currentList = countryCodes_
        }
        view.endEditing(true)
        view.addSubview(countryCodesView)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: {
            self.countryCodesView.alpha = 1.0
        })
        countryCodeTableView.reloadData()
    }
    
// MARK: - Textfield Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == mobileNumberField {
            if Utilities.isStringContainsAlphaAndSpecialCharacters(string) == true {
                return false
            }
        }

        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        if textField == mobileNumberField {
            return newLength <= MaxMobileNumberCharacters
        } else {
            return newLength <= MaxEmailCharacters
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == emailTextField {
            registration?.email = textField.text
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension MobileNumberController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let country = currentList[indexPath.row]
        cell.textLabel?.text = "\(country.name) (\(country.code))"
        cell.textLabel?.font = .montserratLightWithSize(16.0)
        if let selectedCode_ = selectedCode {
            cell.textLabel?.textColor = (selectedCode_ == country) ? .themeColor() : .selectedTextColor()
        } else {
            cell.textLabel?.textColor = .selectedTextColor()
        }
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textAlignment = .left
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCode = currentList[indexPath.row]
        searchField.resignFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)
        countryCodeTableView.reloadData()
    }
}
