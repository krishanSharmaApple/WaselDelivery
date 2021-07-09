//
//  PaymentModeTableViewCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 9/25/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class PaymentModeTableViewCell: UITableViewCell {

    @IBOutlet weak var paymentTitleLabel: UILabel!
    @IBOutlet weak var paymentSubTitleLabel: UILabel!
    @IBOutlet weak var paymentSelectionStatusImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "PaymentModeTableViewCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "PaymentModeTableViewCell"
    }
    
    func loadCellWithContent(isSelectedMode: Bool, paymentMode: PaymentMode?, aOutlet_: Outlet? = nil) {
        let userDefaults = UserDefaults.standard
        if let paymentMode_ = paymentMode {
            var paymentTitleString = "Cash"
            var paymentSubTitleString = "Pay our delivery agent directly"
            if paymentMode_ == .cashOrCard {
                paymentTitleString = "Cash"
                if nil == aOutlet_ {
                    let cashOrCardDesc = userDefaults.value(forKey: cashOrCardDescription) as? String
                    paymentSubTitleString = cashOrCardDesc ?? "Pay our delivery agent directly"
                } else {
                    paymentSubTitleString = aOutlet_?.cashOrCardDescription ?? "Pay our delivery agent directly"
                }
            } else if paymentMode_ == .creditCard {
                paymentTitleString = "Credit Card"
                if nil == aOutlet_ {
                    let creditCardPaymentDesc = userDefaults.value(forKey: creditCardPaymentDescription) as? String
                    paymentSubTitleString = creditCardPaymentDesc ?? "Pay using Credit Card"
                } else {
                    paymentSubTitleString = aOutlet_?.creditCardPaymentDescription ?? "Pay using Credit Card"
                }
            } else if paymentMode_ == .benfit {
                paymentTitleString = "Benefit"
                if nil == aOutlet_ {
                    let benfitPayDescr = userDefaults.value(forKey: benfitPayDescription) as? String
                    paymentSubTitleString = benfitPayDescr ?? "Pay using debit card"
                } else {
                    paymentSubTitleString = aOutlet_?.benfitPayDescription ?? "Pay using debit card"
                }
            } else if paymentMode_ == .masterCard {
                paymentTitleString = "MasterCard"
                if nil == aOutlet_ {
                    let masterCardDescr = userDefaults.value(forKey: masterCardDescription) as? String
                    paymentSubTitleString = "Pay using MasterCard"//masterCardDescr ?? "Pay using debit card"
                } else {
                    paymentSubTitleString = "Pay using MasterCard"//aOutlet_?.masterCardDescription ?? "Pay using debit card"
                }
            }
            paymentTitleLabel.text = paymentTitleString
            paymentSubTitleLabel.text = paymentSubTitleString
        }
        paymentTitleLabel.textColor = (true == isSelectedMode) ? UIColor.themeColor() : UIColor.unSelectedColor()
        paymentSubTitleLabel.textColor = (true == isSelectedMode) ? .selectedTextColor() : UIColor.selectedColor()
        paymentSubTitleLabel.alpha = (true == isSelectedMode) ? 1.0 : 0.5
        paymentSelectionStatusImageView.image = UIImage.init(named: isSelectedMode ? "selected" : "notSelected")
    }
    
}
