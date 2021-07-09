//
//  RegisterViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 07/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import Toaster

enum RegistrationField: Int {
    case name
    case password
    case retypePassword
    case email
}

class RegisterViewController: BaseViewController {
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewTopViewConstraint: NSLayoutConstraint!

    fileprivate var registration = Registration()
    fileprivate var currentRow = -1
    private var disposableBag = DisposeBag()
    var isFromManageProfile = false
    var isFromCheckout = false
    var mobileVerificationDelegate: MobileVerificationDelegate?

// MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        navigationView?.titleLabel.text = "Register"
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width, height: 20.0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0))
        tableView.register(TextFieldCell.nib(), forCellReuseIdentifier: TextFieldCell.cellIdentifier())
        
        // keyboard notifications
        _ = registerForKeyboardDidShowNotification(tableBottomConstraint, shouldUseTabHeight: false)
        _ = registerForKeyboardWillHideNotification(tableBottomConstraint)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewTopViewConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.REGISTRATION_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.REGISTRATION_SCREEN_TAG)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - IBActions
    
    @objc func proceed(_ sender: Any) {
        
        view.endEditing(true)
        if isValidData() {
            let storyBoard = Utilities.getStoryBoard(forName: .login)
            if let mobileVC = storyBoard.instantiateViewController(withIdentifier: "MobileNumberController") as? MobileNumberController {
                let signUpType = registration.accountType.getAccountTypeString()
                let params = ["RegisterThrough": signUpType]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.TAPONREGISTER_EVENT, params: params)

                mobileVC.registration = registration
                mobileVC.isFromCheckout = self.isFromCheckout
                mobileVC.isFromManageProfile = self.isFromManageProfile
                mobileVC.mobileVerificationDelegate = self.mobileVerificationDelegate
                self.navigationController?.pushViewController(mobileVC, animated: true)
            }
        }
    }
    
    @IBAction func segmentAction(_ sender: UISegmentedControl) {
        
        let index = sender.selectedSegmentIndex == 0 ? currentRow - 1 : currentRow + 1
        
        if let cell_ = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TextFieldCell {
            cell_.textField.becomeFirstResponder()
        } else {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
            currentRow = index
        }
    }
    
// MARK: - PrivateMethods
    
    fileprivate func isValidData() -> Bool {
        
        if let name_ = registration.name, name_.trim().count > 0 {
            registration.name = name_
        } else {
            showToastWithMessage("Please enter name.")
            return false
        }
        
        if let password_ = registration.password, password_.count > 0 {
            registration.password = password_
        } else {
            showToastWithMessage("Please enter a password.")
            return false
        }

        if let retypePassword_ = registration.retypePassword, retypePassword_.count > 0 {
            registration.retypePassword = retypePassword_
        } else {
            showToastWithMessage("Please retype password.")
            return false
        }

        guard registration.password?.count ?? 0 >= MinPasswordCharacters || registration.retypePassword?.count ?? 0 >= MinPasswordCharacters  else {
            showToastWithMessage("Password must be at least 6 characters in long.")
            return false
        }

        guard registration.password == registration.retypePassword else {
            showToastWithMessage("Password and Retype password should be same.")
            return false
        }
        
        if let email_ = registration.email, email_.trim().count > 0 {
            guard Utilities.isValidEmail(testStr: email_) == true else {
                showToastWithMessage("Please enter valid email.")
                return false
            }
            registration.email = email_
        } else {
            showToastWithMessage("Please enter an email address.")
            return false
        }

        return true
    }
    
    fileprivate func showToastWithMessage(_ message: String) {
        
        Toast(text: message).show()
    }
    
    fileprivate func relaodSegment() {
        if currentRow == 0 {
            segmentControl.setEnabled(false, forSegmentAt: 0)
            segmentControl.setEnabled(true, forSegmentAt: 1)
        } else if currentRow == RegistrationField.email.rawValue {
            segmentControl.setEnabled(false, forSegmentAt: 1)
            segmentControl.setEnabled(true, forSegmentAt: 0)
        } else {
            segmentControl.setEnabled(true, forSegmentAt: 0)
            segmentControl.setEnabled(true, forSegmentAt: 1)
        }
    }
}

extension RegisterViewController: UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 63.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row <= RegistrationField.email.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.cellIdentifier()) as? TextFieldCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.textField.keyboardType = .asciiCapable
            cell.textField.delegate = self
            cell.textField.tag = indexPath.row
            cell.textField.inputAccessoryView = toolBar
            
            switch indexPath.row {
                
            case RegistrationField.name.rawValue:
                cell.loadCell(withText: "", placeholder: "Name")
            case RegistrationField.password.rawValue:
                cell.loadCell(withText: "", placeholder: "Password (min 6 char)", isSecured: true)
            case RegistrationField.retypePassword.rawValue:
                cell.loadCell(withText: "", placeholder: "Retype Password", isSecured: true)
            case RegistrationField.email.rawValue:
                cell.loadCell(withText: "", placeholder: "Email ID", keyboardType: .emailAddress)
            default:
                cell.loadCell(withText: "", placeholder: "")
            }
            return cell
            
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProceedCell.cellIdentifier()) as? ProceedCell else {
                return UITableViewCell()
            }
            cell.proceedButton.addTarget(self, action: #selector(self.proceed(_:)), for: .touchUpInside)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        if currentRow == indexPath.row {
            if let cell_ = cell as? TextFieldCell {
                cell_.textField.becomeFirstResponder()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentRow = textField.tag
        tableView.scrollToRow(at: IndexPath(row: textField.tag, section: 0), at: .none, animated: true)
        relaodSegment()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        
        switch textField.tag {
            
        case RegistrationField.name.rawValue:
            return Utilities.shared.isValidCharacterForName(textField: textField, string: string, forLength: newLength)
        case RegistrationField.password.rawValue,
             RegistrationField.retypePassword.rawValue:
            return isValidCharacterForPassword(textField: textField, string: string, forLength: newLength)
        case RegistrationField.email.rawValue:
            return isValidCharacterForEmail(textField: textField, string: string, forLength: newLength)
        default:
            break
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        switch textField.tag {
            
        case RegistrationField.name.rawValue:
            registration.name = textField.text?.capitalized
        case RegistrationField.password.rawValue:
            registration.password = textField.text
        case RegistrationField.retypePassword.rawValue:
            registration.retypePassword = textField.text
        case RegistrationField.email.rawValue:
            registration.email = textField.text
        default:
            break
        }
    }
    
// Validation Methods
    
    func isValidCharacterForPassword(textField: UITextField, string: String, forLength: Int) -> Bool {
//        if let text_ = textField.text, text_.count == 0 {
        if string.length > 0 {
            let charactesAllowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@%./\\!#$/^?:.()/[/]{}/~/-/,/_"
            let isValidCharacter = (charactesAllowed.contains(string)) ? true : false
            return isValidCharacter
        } 
        let isSpace = (string == " ") ? true : false
        return !isSpace && forLength <= MaxPasswordCharacters
    }
    
    func isValidCharacterForEmail(textField: UITextField, string: String, forLength: Int) -> Bool {
        return forLength <= MaxEmailCharacters
    }
}

class ProceedCell: UITableViewCell {
    
    @IBOutlet weak var proceedButton: UIButton!
        
    class func nib() -> UINib {
        return UINib(nibName: "ProceedCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "ProceedCell"
    }
    
}
