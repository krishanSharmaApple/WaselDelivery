//
//  SaveAddressController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift

class SaveAddressController: BaseViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressTableView: UITableView!
    var address: Address?
    
    private var disposableBag = DisposeBag()
    private var showNotification: Any!
    private var hideNotification: Any!
    fileprivate var rowCount = 4
    fileprivate var currentTextFieldTag: Int?
    var isFromProfile = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        self.navigationView?.titleLabel.text = "Save Address"
        addressTableView.register(TextFieldCell.nib(), forCellReuseIdentifier: TextFieldCell.cellIdentifier())
        addressTableView.estimatedRowHeight = 65.0
        addressTableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // keyboard notifications
        showNotification = registerForKeyboardDidShowNotification(tableBottomConstraint, 0, shouldUseTabHeight: false, usingBlock: { _ in
            DispatchQueue.main.async(execute: {
                if let currentTextFieldTag_ = self.currentTextFieldTag, currentTextFieldTag_ == self.rowCount - 1 {
                    self.addressTableView.scrollToRow(at: IndexPath(row: currentTextFieldTag_, section: 0), at: .bottom, animated: true)
                }
            })
        })
        hideNotification = registerForKeyboardWillHideNotification(tableBottomConstraint)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        NotificationCenter.default.removeObserver(showNotification)
        NotificationCenter.default.removeObserver(hideNotification)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.SAVE_ADDRESS_SCREEN)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
// MARK: - IBActions
    
    @IBAction func saveAddress(_ sender: Any) {
        
        view.endEditing(true)

        /*guard let doorNumber_ = address?.doorNumber, doorNumber_.count > 0 else {
            Utilities.showToastWithMessage("Please enter flat number.")
            return
        }

        guard let landmark_ = address?.landmark, landmark_.count > 0 else {
            Utilities.showToastWithMessage("Please enter landmark.")
            return
        }*/

        guard let addressType_ = address?.addressType, addressType_.count > 0 else {
            Utilities.showToastWithMessage("Please select Address Type.")
            return
        }
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        guard let address_ = address else {
            Utilities.showToastWithMessage("Please enter all the fields.")
            return
        }
        
        Utilities.showHUD(to: self.view, "")
        ApiManager.shared.apiService.addUserAddress(address_).subscribe(onNext: { [weak self](_) in
            
            Utilities.hideHUD(from: self?.view)
            let viewControllers = self?.navigationController?.viewControllers
            if let vcs = viewControllers {
                if self?.isFromProfile == true {
                    _ = self?.navigationController?.popToViewController(vcs[1], animated: true)
                } else {
                    if let confirmVC = vcs[vcs.count - 3] as? ConfirmOrderController, let add_ = self?.address {
                        confirmVC.addNewAddress(with: add_)
                        _ = self?.navigationController?.popToViewController(confirmVC, animated: true)
                    }
                }
            }
        }, onError: { [weak self](error) in
            
            Utilities.hideHUD(from: self?.view)
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                    
                } else {
                    self?.showServerAlert(messsage: error_.description())
                }
            } else {
                Utilities.showToastWithMessage(error.localizedDescription)
            }
        }).disposed(by: disposableBag)
    }
    
// MARK: - IBActions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case SaveAddressCellType.address.rawValue:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressDescriptionCell.cellIdentifier()) as? AddressDescriptionCell else {
                return UITableViewCell()
            }
            var text = address?.location ?? ""
            if let land = address?.landmark {
                text.append(", \(land)")
            }
            if let door = address?.doorNumber {
                text.append(", \(door)")
            }
            cell.addressLabel.text = text
            return cell

        case SaveAddressCellType.flatNumber.rawValue:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.cellIdentifier()) as? TextFieldCell else {
                return UITableViewCell()
            }
            cell.textField.delegate = self
            cell.textField.tag = indexPath.row
            cell.loadCell(withText: address?.doorNumber ?? "", placeholder: "Flat No/House No/Apt No")
            return cell

        case SaveAddressCellType.landMark.rawValue:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.cellIdentifier()) as? TextFieldCell else {
                return UITableViewCell()
            }
            cell.textField.delegate = self
            cell.textField.tag = indexPath.row
            cell.loadCell(withText: address?.landmark ?? "", placeholder: "Landmark")
            return cell

        case SaveAddressCellType.addressType.rawValue:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressTypeCell.cellIdentifier()) as? AddressTypeCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            return cell
            
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.cellIdentifier()) as? TextFieldCell else {
                return UITableViewCell()
            }
            cell.textField.delegate = self
            cell.textField.tag = indexPath.row
            cell.loadCell(withText: "", placeholder: "e.g. Friend's Home")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            navigateBack(nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        currentTextFieldTag = textField.tag
        self.addressTableView.scrollToRow(at: IndexPath(row: textField.tag, section: 0), at: .none, animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
//        if nil == textField.textInputMode?.primaryLanguage || textField.textInputMode?.primaryLanguage == "emoji" {
//            return false
//        }
        if false == string.canBeConverted(to: .ascii) {
            return false
        }
        
        if string == "#" {
            return false
        }
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 45
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == SaveAddressCellType.flatNumber.rawValue {
            address?.doorNumber = textField.text?.trim()
        } else if textField.tag == SaveAddressCellType.landMark.rawValue {
            address?.landmark = textField.text?.trim()
        } else if textField.tag == rowCount - 1 {
            let aText = textField.text ?? ""
            address?.addressType = aText.count > 0 ? aText : ""
        }
    }
}

extension SaveAddressController: AddressTypeCellDelegate {
    
    func addressTypeCell(cell: AddressTypeCell, didSelectAddressType type: String) {
        
        address?.addressType = type
        if type != AddressType.home.rawValue && type != AddressType.office.rawValue {
            if rowCount == 5 {
                return
            }
            rowCount = 5
            let index = IndexPath(row: rowCount - 1, section: 0)
            addressTableView.beginUpdates()
            addressTableView.insertRows(at: [index], with: .automatic)
            addressTableView.endUpdates()
            if let currentCell = addressTableView.cellForRow(at: index) as? TextFieldCell {
                currentCell.textField.becomeFirstResponder()
            }
        } else {
            if rowCount == 5 {
                rowCount = 4
                addressTableView.beginUpdates()
                addressTableView.deleteRows(at: [IndexPath(row: rowCount, section: 0)], with: .fade)
                addressTableView.endUpdates()
                addressTableView.reloadData()
            }
        }
    }
}
