//
//  OrderChargeCell.swift
//  WaselDelivery
//
//  Created by sunanda on 12/5/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderChargeCell: UITableViewCell {
    
    @IBOutlet weak var minusLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deliveryChargeLabel: UILabel!
    @IBOutlet weak var bdImageView: UIImageView!
    var chargeType: ChargeType!
        
    class func cellIdentifier() -> String {
        return "OrderChargeCell"
    }
    
    func loadPrice(price: Double, order: Order? = nil, handleFeeType: String = "") {
        
        minusLabel.isHidden = true
        guard let chargeType_ = chargeType else {
            return
        }
        switch chargeType_ {
        case .delivery:
            titleLabel.text = "Delivery Charge"
            titleLabel.font = UIFont.montserratLightWithSize(15.0)
            titleLabel.alpha = 0.5
            
            if let order_ = order, true == order_.isFleetOutLet {
//                deliveryChargeLabel.text = "NA"
//                bdImageView.isHidden = true
                deliveryChargeLabel.text = String(format: "%.3f", price)
                bdImageView.isHidden = false
            } else {
                bdImageView.isHidden = false
                deliveryChargeLabel.text = String(format: "%.3f", price)
            }
        case .discount:
            titleLabel.text = "Discount"
            titleLabel.font = UIFont.montserratLightWithSize(15.0)
            titleLabel.alpha = 0.5
            minusLabel.isHidden = false
            deliveryChargeLabel.text = String(format: "%.3f", price)
            
        case .grandTotal:
            titleLabel.text = "Total"
            titleLabel.font = UIFont.montserratLightWithSize(20.0)
            titleLabel.alpha = 1.0
            deliveryChargeLabel.text = String(format: "%.3f", price)
            
        case .subTotal:
            titleLabel.text = "Subtotal"
            titleLabel.font = UIFont.montserratLightWithSize(15.0)
            titleLabel.alpha = 0.5
            deliveryChargeLabel.text = String(format: "%.3f", price)

        case .tip:
            titleLabel.text = "Tip"
            titleLabel.font = UIFont.montserratLightWithSize(15.0)
            titleLabel.alpha = 0.5
            
            if let order_ = order {
                if let tipAmount_ = order_.tipAmount, 0 < tipAmount_ {
                    bdImageView.isHidden = false
                    deliveryChargeLabel.text = String(format: "%.3f", tipAmount_)
                } else {
                    deliveryChargeLabel.text = "0.0"
                    bdImageView.isHidden = true
                }
            } else {
                deliveryChargeLabel.text = "0.0"
                bdImageView.isHidden = true
            }

        case .handlingFee:
            titleLabel.text = "Handling Fee"
            if handleFeeType == "PERCENTAGE" {
                deliveryChargeLabel.text = String(format: "%.2f%% of Order Charge", price)
                bdImageView.isHidden = true
                deliveryChargeLabel.font = deliveryChargeLabel.font.withSize(11)
            } else {
                deliveryChargeLabel.text = String(format: "%.3f", price)
                bdImageView.isHidden = false
                deliveryChargeLabel.font = deliveryChargeLabel.font.withSize(15)
            }
            titleLabel.font = UIFont.montserratLightWithSize(15.0)
            titleLabel.alpha = 0.5
        }
    }
}
