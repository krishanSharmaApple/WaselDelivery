//
//  PaymentCardDoubleInfoTableViewCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/12/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class PaymentCardDoubleInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var leftTitleLabel: UILabel!
    @IBOutlet weak var leftInfoTextField: UITextField!
    
    @IBOutlet weak var rightTitleLabel: UILabel!
    @IBOutlet weak var rightInfoTextField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
        
        leftInfoTextField.attributedPlaceholder = NSAttributedString(string: leftInfoTextField.placeholder != nil ? leftInfoTextField.placeholder ?? "" : "", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)])
        rightInfoTextField.attributedPlaceholder = NSAttributedString(string: rightInfoTextField.placeholder != nil ? rightInfoTextField.placeholder ?? "" : "", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)])
        rightInfoTextField.isSecureTextEntry = true
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "PaymentCardDoubleInfoTableViewCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "PaymentCardDoubleInfoTableViewCell"
    }
    
    func updateCardInfo(leftHeaderContent: String, andLeftPlaceHolder leftPlaceHolder: String,
                        rightHeaderContent: String, andRightPlaceHolder rightPlaceHolder: String) {
        leftTitleLabel.text = leftHeaderContent
        rightTitleLabel.text = rightHeaderContent
        leftInfoTextField.placeholder = leftPlaceHolder
        rightInfoTextField.placeholder = rightPlaceHolder
    }
    
}
