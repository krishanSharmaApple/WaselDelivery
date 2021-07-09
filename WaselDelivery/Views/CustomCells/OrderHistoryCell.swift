//
//  OrderHistoryCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 25/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderHistoryCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var grandTotalLabel: UILabel!
    @IBOutlet weak var outletLabel: UILabel!
    @IBOutlet weak var repeatOrderButton: UIButton!
    
    var order: Order!
    weak var delegate: OrderHistoryDelegate?
//    weak var delegate: OrderDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        repeatOrderButton.layer.borderWidth = 1.0
        repeatOrderButton.layer.borderColor = UIColor.themeColor().cgColor
    }

    class func cellIdentifier() -> String {
        return "OrderHistoryCell"
    }
    
    func loadOrderDetails(order_: Order) {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        repeatOrderButton.isEnabled = isAppOpen

        order = order_
        if let date_ = order.orderCreatedDateTime {
            dateLabel.text = Utilities.getSystemDateString(date: date_, "dd MMM yyyy, hh:mm a")
        } else {
            dateLabel.text = ""
        }
        
        if order?.orderType == .special {
            if let deliveryCharge_ = order.deliveryCharge {
                let attText = formAttStringForText(text: "Order Total: ", amount: deliveryCharge_, font: .montserratRegularWithSize(14.0), fontColor: UIColor.unSelectedTextColor())
                grandTotalLabel.attributedText = attText
            } else {
                grandTotalLabel.attributedText = NSAttributedString(string: "")
            }
        } else {
            if let grandTotal_ = order.grandTotal {
                let attText = formAttStringForText(text: "Order Total: ", amount: grandTotal_, font: .montserratRegularWithSize(14.0), fontColor: UIColor.unSelectedTextColor())
                grandTotalLabel.attributedText = attText
            } else {
                grandTotalLabel.attributedText = NSAttributedString(string: "")
            }
        }
        
        var outletNameString = ""
        if order.orderType == .special {
            if let outlet_ = order.outlet, let address_ = outlet_.address, let location_ = address_.location, order?.orderType == .normal {
                outletNameString = location_
            } else {
                if let pickUpLocation_ = order?.pickUpLocation {
                    outletNameString = pickUpLocation_
                } else {
                    outletNameString = ""
                }
            }
        } else {
            if order.orderType == .special {
                if let outlet_ = order.outlet, nil != outlet_.name {
                    let outletName = Utilities.fetchOutletName(outlet_)
                    outletNameString = outletName
                } else {
                    outletNameString = ""
                }
            } else {
                if let outlet_ = order.outlet, nil != outlet_.name {
                    let outletName = Utilities.fetchOutletName(outlet_)
                    outletNameString = outletName
                } else {
                    outletNameString = ""
                }
            }
        }
        outletLabel.text = outletNameString
    }
    
    private func getTotalItems(_ items_: [OrderItem]) -> Int {
        
        if let order_ = order, order_.orderType == .special { return order_.items?.count ?? 0 }
        return items_.reduce(0) { acc, item in return acc + (item.quantity ?? 0) }
    }
    
    fileprivate func formAttStringForText(text: String, amount: Double, font: UIFont, fontColor: UIColor) -> NSMutableAttributedString {
        
        let contentString = NSMutableAttributedString(string: "\(text)")
        let myString = NSMutableAttributedString(string: "")
        myString.append(contentString)
        let bdString = NSMutableAttributedString(string: "BD")
        myString.append(bdString)

        let priceNumber = Double(amount)
        let priceText = String(format: "%.3f", priceNumber)
        let priceString = NSAttributedString(string: " \(priceText)")
        myString.append(priceString)
        
        let contentRange = NSRange(location: 0, length: contentString.length)
        myString.addAttribute(NSAttributedString.Key.foregroundColor, value: fontColor, range: contentRange)
        myString.addAttribute(NSAttributedString.Key.font, value: font, range: contentRange)

        let bdRange = NSRange(location: contentString.length, length: bdString.length)
        let aColor = UIColor(red: (74.0/255.0), green: (74.0/255.0), blue: (74.0/255.0), alpha: 1.0)
        myString.addAttribute(NSAttributedString.Key.foregroundColor, value: aColor, range: bdRange)
        myString.addAttribute(NSAttributedString.Key.font, value: UIFont.montserratMediumWithSize(14.0), range: bdRange)

        myString.addAttribute(NSAttributedString.Key.foregroundColor, value: fontColor, range: NSRange(location: contentString.length + bdString.length, length: myString.length - (contentString.length + bdString.length)))
        myString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: contentString.length + bdString.length, length: myString.length - (contentString.length + bdString.length)))
        return myString
    }
    
    @IBAction func repeatOrder(_ sender: Any) {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        if false == isAppOpen {
            return
        }

        if let delegate_ = delegate, true == Utilities.isWaselDeliveryOpen() {
            delegate_.repeatOrder(order_: order)
        }
        
        // Remove above code and uncomment the below code for Repeate order
//        if let delegate_ = delegate {
//            delegate_.orderDelegate(order_: order)
//        }
    }
}

protocol OrderHistoryDelegate: class {
    func repeatOrder(order_: Order)
}

protocol OrderDelegate: class {
    func orderDelegate(order_: Order)
}
