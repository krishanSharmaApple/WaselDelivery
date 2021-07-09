//
//  OrderCancelDetailsHeaderCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 03/01/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderCancelDetailsHeaderCell: UITableViewCell {
    
    @IBOutlet weak var orderIdLabel: UILabel!
    @IBOutlet weak var orderDateLabel: UILabel!
    @IBOutlet weak var itemsCountLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var totalTitleLabel: UILabel!
    @IBOutlet weak var bdImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
    }

    class func nib() -> UINib {
        return UINib(nibName: "OrderCancelDetailsHeaderCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "OrderCancelDetailsHeaderCell"
    }

// MARK: - User defined methods
    
    func loadOrderDetails(order_: Order) {
        
        func getTotalItems(_ items_: [OrderItem]) -> Int {
            if order_.orderType == .special { return order_.items?.count ?? 0 }
            return items_.reduce(0) { acc, item in return acc + (item.quantity ?? 0) }
        }

        if let id_ = order_.id {
            orderIdLabel.text = "OrderID-\(id_) "
        } else {
            orderIdLabel.text = ""
        }

        if let date_ = order_.orderCreatedDateTime {
            orderDateLabel.text = Utilities.getSystemDateString(date: date_, "dd MMM yyyy, hh:mm a")
        } else {
            orderDateLabel.text = ""
        }

        if let items_ = order_.items {
            itemsCountLabel.text = String(format: "%02d", getTotalItems(items_))
        } else {
            itemsCountLabel.text = ""
        }
        
        if order_.orderType == .special {
            totalTitleLabel.text = "Delivery Charge"
            if let deliveryCharge_ = order_.deliveryCharge, false == order_.isFleetOutLet {
                totalLabel.text = "\(String(format: "%.3f", deliveryCharge_))"
            } else {
                totalLabel.text = (true == order_.isFleetOutLet) ? "NA" : ""
                bdImageView.isHidden = true
            }
        } else {
            totalTitleLabel.text = "Grand Total"
            if let grandTotal_ = order_.grandTotal {
                totalLabel.text = "\(String(format: "%.3f", grandTotal_))"
                bdImageView.isHidden = false
            } else {
                totalLabel.text = (true == order_.isFleetOutLet) ? "NA" : ""
                bdImageView.isHidden = true
            }
        }
    }
    
}
