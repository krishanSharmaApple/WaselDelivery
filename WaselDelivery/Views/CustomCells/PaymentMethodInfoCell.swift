//
//  PaymentMethodInfoCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 29/1/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class PaymentMethodInfoCell: UITableViewCell {

    @IBOutlet weak var titleInfoLabel: UILabel!
    @IBOutlet weak var subTitleInfoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        subTitleInfoLabel.adjustsFontSizeToFitWidth = true
    }

    class func cellIdentifier() -> String {
        return "PaymentMethodInfoCell"
    }

    func updatePaymentMethodInformation(paymentType: String) {
        titleInfoLabel.text = "Payment Method"
        subTitleInfoLabel.text = paymentType
        subTitleInfoLabel.textColor = .themeColor()
    }
    
    func updateSceduledInformation(scheduledTime: String) {
        titleInfoLabel.text = "Scheduled Time"
        subTitleInfoLabel.text = scheduledTime
        subTitleInfoLabel.textColor = .selectedTextColor()
    }

}
