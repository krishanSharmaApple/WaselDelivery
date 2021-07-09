//
//  OrderCancelReasonsCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 03/01/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderCancelReasonsCell: UITableViewCell {
    
    @IBOutlet weak var reasonLabel: UILabel!
    @IBOutlet weak var dropDownImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.isExclusiveTouch = true
        reasonLabel.numberOfLines = 0
    }

    class func nib() -> UINib {
        return UINib(nibName: "OrderCancelReasonsCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "OrderCancelReasonsCell"
    }

// MARK: - User defined methods
    
    func loadCancelReasons(orderCancelReason_: OrderCancelReason?, shouldShowArrowImageView: Bool, isReasonAvailable: Bool) {
        if let reasonMessage = orderCancelReason_?.reason {
            reasonLabel.text = reasonMessage
        } else {
            reasonLabel.text = "Select"
        }
        let aImageName = (true == isReasonAvailable) ? "collapsMenu" : "dropDown"
        dropDownImageView.image = UIImage.init(named: aImageName)
        dropDownImageView.isHidden = !shouldShowArrowImageView
    }
    
}
