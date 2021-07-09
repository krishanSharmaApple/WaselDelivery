//
//  OrderHistoryPendingCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 20/03/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderHistoryPendingCell: UITableViewCell {

    @IBOutlet weak var orderStageView: UIView!
    @IBOutlet var animationViewCollection: [UIView]!
    @IBOutlet var statusAnimationCollection: [UIView]!
    @IBOutlet weak var outletLabel: UILabel!
    @IBOutlet var statusImageCollection: [UIImageView]!
    @IBOutlet var statusLabelCollection: [UILabel]!

    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var leftViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var lineViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var lineViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var sideArrowImageView: UIImageView!
    
    weak var delegate: OrderDelegate?
    var order: Order!
    
    class func cellIdentifier() -> String {
        return "OrderHistoryPendingCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateAnimation), name: NSNotification.Name(rawValue: UpdateStatusAnimationNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(UpdateStatusAnimationNotification), object: nil)
    }
    
    func loadOrderDetails(_ order_: Order, shouldHideSeperator shouldHide: Bool, isFromDetailsScreen isDetailsScreen: Bool = false) {
        
        sideArrowImageView.isHidden = isDetailsScreen
        order = order_
        
        var outletNameString = ""
        if false == isDetailsScreen {
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
            
            var locationString = ""
            if let outlet_ = order.outlet, let address_ = outlet_.address, let location_ = address_.location, order?.orderType == .normal {
                locationString = location_
            } else {
                if let pickUpLocation_ = order?.pickUpLocation {
                    locationString = pickUpLocation_
                } else {
                    locationString = ""
                }
            }
            
            if outletNameString.isEmpty {
                if !locationString.isEmpty {
                    outletLabel.text = locationString
                } else {
                    outletLabel.text = outletNameString
                }
            } else {
                outletLabel.text = outletNameString
            }

        } else {
            outletLabel.text = outletNameString
        }
        
        if let status_ = order.status {
            var hashValue = OrderStatus.hashValueFrom(status: status_)
            if true == order.isFleetOutLet {
                hashValue = OrderStatus.hashValueForFleetType(status: status_)
            }
            for (index, imageView) in statusImageCollection.enumerated() {
                imageView.image = (imageView.tag <= hashValue) ? UIImage(named: "selected") : nil
                statusAnimationCollection[index].isHidden =  (statusAnimationCollection[index].tag == hashValue + 1
                    ) ? false : true
            }
            for label in statusLabelCollection {
                label.font = (label.tag <= hashValue) ? UIFont.montserratSemiBoldWithSize(14.0) : UIFont.montserratRegularWithSize(14.0)
                label.textColor = (label.tag <= hashValue) ? .white : .unSelectedTextColor()
                
                if 1 == label.tag {
                    label.text = (true == order.isFleetOutLet) ? "Placed" : "Confirmed"
                } else if 2 == label.tag { //PickUp(Middle label)
                    label.isHidden = (true == order.isFleetOutLet) ? true : false
                    label.text = "Pick Up"
                } else if 3 == label.tag {
                    label.text = (true == order.isFleetOutLet) ? "Confirmed" : "Delivered"
                }
            }
        }

        if true == order.isFleetOutLet {
            middleView.isHidden = true
            
            leftViewLeadingConstraint.constant = 65.0
            rightViewTrailingConstraint.constant = 65.0
            
            lineViewLeadingConstraint.constant = 75.0
            lineViewTrailingConstraint.constant = 76.0
        } else {
            middleView.isHidden = false
            
            leftViewLeadingConstraint.constant = 47.0
            rightViewTrailingConstraint.constant = 47.0
            
            lineViewLeadingConstraint.constant = 57.0
            lineViewTrailingConstraint.constant = 56.0
        }
    }
    
    @objc private func updateAnimation() {
        
        if true == order.isFleetOutLet {
            if order?.status == .pending {
                let aView = animationViewCollection[2]
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                    aView.alpha = (aView.alpha == 1.0) ? 0.0 : 1.0
                }, completion: nil)
            }
            return
        }
        
        if let orderStatus = order?.status {
            let hashValue = OrderStatus.hashValueFrom(status: orderStatus)
            if 0 ... 2 ~= hashValue {
                let aView = animationViewCollection[hashValue]
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                    aView.alpha = (aView.alpha == 1.0) ? 0.0 : 1.0
                }, completion: nil)
            }
        }
    }

    @IBAction func buttonAction(_ sender: Any) {
        
        if let delegate_ = delegate {
            delegate_.orderDelegate(order_: order)
        }
    }
        
}
