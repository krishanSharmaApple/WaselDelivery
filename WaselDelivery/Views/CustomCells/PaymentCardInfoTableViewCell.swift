//
//  PaymentCardInfoTableViewCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/12/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class PaymentCardInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoTextField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
        
        infoTextField.attributedPlaceholder = NSAttributedString(string: infoTextField.placeholder != nil ? infoTextField.placeholder ?? "" : "", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)])
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "PaymentCardInfoTableViewCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "PaymentCardInfoTableViewCell"
    }
    
    func updateCardInfo(headerContent: String, andPlaceHolder placeHolder: String) {
        titleLabel.text = headerContent
        infoTextField.placeholder = placeHolder
    }

    func loadCell(withText text: String, placeholder placeholderText: String, isSecured secured: Bool = false, keyboardType type: UIKeyboardType = .default) {
        
        infoTextField.keyboardType = type
        infoTextField.isSecureTextEntry = secured
        
        if text.count != 0 {
            infoTextField.text = text
        }
        if placeholderText.count != 0 {
            infoTextField.placeholder = placeholderText
        }
    }
    
}
