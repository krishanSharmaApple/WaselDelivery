//
//  OrderPendingCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 25/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderPendingCell: UITableViewCell {

    @IBOutlet weak var orderStageView: UIView!
    @IBOutlet weak var orderStatusLabel: UILabel!
    @IBOutlet var animationViewCollection: [UIView]!
    @IBOutlet var statusAnimationCollection: [UIView]!
    @IBOutlet weak var outletLabel: UILabel!
    @IBOutlet weak var locationlabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var orderIDLabel: UILabel!
    @IBOutlet var statusImageCollection: [UIImageView]!
    @IBOutlet var statusLabelCollection: [UILabel]!
    @IBOutlet weak var seperator: UIView!
    @IBOutlet weak var couponLabel: UILabel!

    @IBOutlet weak var aButton: HighlightButton!
    @IBOutlet weak var couponCodeBgViewHeightConstraint: NSLayoutConstraint!
    weak var delegate: OrderDelegate?
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var leftViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var lineViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var lineViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelReasonLabel: UILabel!
    @IBOutlet weak var cancelReasonLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var orderStageViewHeightConstraint: NSLayoutConstraint!

    var order: Order!
    var isDottedLineAdded: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
//        orderProgressView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(updateAnimation), name: NSNotification.Name(rawValue: UpdateStatusAnimationNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrderProgress), name: NSNotification.Name(rawValue: RefreshOrderNotification), object: nil)
        
        if false == isDottedLineAdded {
            isDottedLineAdded = true
            let shapeLayer = CAShapeLayer()
            let frameSize = aButton.frame.size
            let shapeRect = CGRect(x: 0.0, y: 0, width: frameSize.width, height: frameSize.height)
            shapeLayer.bounds = shapeRect
            shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = UIColor.unSelectedTextColor().cgColor
            shapeLayer.lineWidth = 1
            shapeLayer.lineJoin = .round
            shapeLayer.lineDashPattern = [6, 3]
            shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 6).cgPath
            couponLabel.layer.addSublayer(shapeLayer)
        }
    }

    class func cellIdentifier() -> String {
        return "OrderPendingCell"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(UpdateStatusAnimationNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(RefreshOrderNotification), object: nil)
    }
    
    func loadOrderDetails(_ order_: Order, shouldHideSeperator shouldHide: Bool, isFromDetailsScreen isDetailsScreen: Bool = false, shouldShowOrderStageView shouldShowOrderStage: Bool? = true) {
        
        order = order_
        if let id_ = order.id {
            orderIDLabel.text = "OrderID: OID\(id_)"
        } else {
            orderIDLabel.text = ""
        }
        
        if let date_ = order.orderCreatedDateTime {
            dateLabel.text = Utilities.getSystemDateString(date: date_, "dd MMM yyyy, hh:mm a")
        } else {
            dateLabel.text = ""
        }
        
//        if order!.orderType == .special {
////            totalTitleLabel.text = "Delivery Charge"
//            if let deliveryCharge_ = order.deliveryCharge, false == order.isFleetOutLet {
//                grandTotalLabel.text = "\(String(format: "%.3f", deliveryCharge_))"
//                bdImageView.isHidden = false
//            } else {
//                grandTotalLabel.text = "NA"
//                bdImageView.isHidden = true
//            }
//        } else {
////            totalTitleLabel.text = "Grand Total"
//            if let grandTotal_ = order.grandTotal {
//                grandTotalLabel.text = "\(String(format: "%.3f", grandTotal_))"
//                bdImageView.isHidden = false
//            } else {
//                grandTotalLabel.text = ""
//                bdImageView.isHidden = true
//            }
//        }
        
//        if let items_ = order.items {
//            totalItemsLabel.text = String(format: "%02d", getTotalItems(items_))
//        } else {
//            totalItemsLabel.text = ""
//        }
        
        var outletNameString = ""
        if order.orderType == .special {
            if let outlet_ = order.outlet, nil != outlet_.name {
                let outletName = Utilities.fetchOutletName(outlet_)
                outletNameString = outletName
            } else {
                outletNameString = ""
            }
//            outletNameString = ""
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
        
        if false == outletNameString.isEmpty && false == locationString.isEmpty {
            outletLabel.text = outletNameString
            locationlabel.text = locationString
        } else if false == outletNameString.isEmpty {
            outletLabel.text = outletNameString
            locationlabel.text = ""
        } else if false == locationString.isEmpty {
            locationlabel.text = locationString
            outletLabel.text = ""
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
//        seperator.isHidden = shouldHide
        seperator.isHidden = false

        updateProgress()
        updateProgressValues()
        
        if isDetailsScreen, false == shouldShowOrderStage {
            self.orderStageView.isHidden = true
            orderStageViewHeightConstraint.constant = 0.0
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
        
        if true == isDetailsScreen {
            // Displays applied promo code
            if let aCoupon = order.coupon, false == aCoupon.code?.isEmpty {
                couponLabel.isHidden = false
                couponCodeBgViewHeightConstraint.constant = 40.0
                couponLabel.text = aCoupon.code
            } else {
                couponLabel.isHidden = true
                couponCodeBgViewHeightConstraint.constant = 0.0
            }
        } else {
            couponLabel.isHidden = true
            couponCodeBgViewHeightConstraint.constant = 0.0
        }

//        let title_ = order.isOrderProcessing() ? (order.status == .pending) ? "Cancel Order" : "Support" : (order.status == .completed) ? "Repeat Order" : "Re-Order"
        let title_ = order.isOrderProcessing() ? (order.status == .pending) ? "Cancel Order" : "Support" :  "RE-ORDER"
        aButton.setTitle( title_, for: .normal)
        let aColor = order.isOrderProcessing() ? (order.status == .pending) ? UIColor.unSelectedColor() : UIColor.themeColor() : UIColor.themeColor()
        aButton.setTitleColor(aColor, for: .normal)
        aButton.layer.borderColor = aColor.cgColor
        
        if isDetailsScreen {
            let buttonEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            aButton.titleEdgeInsets = buttonEdgeInsets
            aButton.imageEdgeInsets = buttonEdgeInsets
            aButton.setImage(UIImage(named: ""), for: .normal)
        } else {
            aButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -50, bottom: 0, right: 0)
            aButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 85, bottom: 0, right: 0)
            aButton.setImage(UIImage(named: "reorder"), for: .normal)
        }

        // Hides Support button
        if order.isOrderProcessing() &&  order.status != .pending {
            aButton.isHidden = true
        } else {
            if true == isDetailsScreen {
                aButton.isHidden = false
            } else {
                aButton.isHidden = (order.status == .cancelled || order.status == .failed)
            }
        }
        
        if (order.status == .cancelled || order.status == .failed) && (true == isDetailsScreen) {
            if false == order.cancelReason?.isEmpty {
                cancelReasonLabel.text = order.cancelReason
                cancelReasonLabelBottomConstraint.constant = 15.0
            } else {
                cancelReasonLabel.text = ""
                cancelReasonLabelBottomConstraint.constant = 5.0
            }
        } else {
            cancelReasonLabel.text = ""
            cancelReasonLabelBottomConstraint.constant = 5.0
        }
    }
    
    private func getTotalItems(_ items_: [OrderItem]) -> Int {
        if let order_ = order, order_.orderType == .special { return order_.items?.count ?? 0 }
        return items_.reduce(0) { acc, item in return acc + (item.quantity ?? 0) }
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
    
    @objc private func updateOrderProgress(_ notification: Notification) {
        
        let userInfo = notification.userInfo
        if let order_ = userInfo?["order"] as? Order, order_.id == order.id {
            order.status = order_.status
            updateProgress()
        }
    }

    @IBAction func buttonAction(_ sender: Any) {
        
        if let delegate_ = delegate {
            delegate_.orderDelegate(order_: order)
        }
    }
    
    fileprivate func updateProgress() {
        
//        var value_ = CGFloat(OrderStatus.hashValueFrom(status: order.status ?? .pending)) / 3.0
//        if true == order.isFleetOutLet {
//            value_ = CGFloat((order.status == .pending) ? 0.5 : 1.0)
//        }
//        orderProgressView.progress = (order.isOrderProcessing() || order.status == .completed) ? value_ : 0.0
        
//        if order.status == .completed {
//            self.orderStatusImageView.image = #imageLiteral(resourceName: "greenTick")
//            self.orderStatusImageView.isHidden = false
//        } else if order.status == .cancelled || order.status == .failed {
//            self.orderStatusImageView.image = #imageLiteral(resourceName: "cancel")
//            self.orderStatusImageView.isHidden = false
//        } else {
//            self.orderStatusImageView.isHidden = true
//        }

    }

    fileprivate func updateProgressValues() {
        
//        orderProgressView.isHidden = !order.isOrderProcessing()
//        orderStatusView.isHidden = order.isOrderProcessing()
        
        self.orderStageView.isHidden = !order.isOrderProcessing()
        self.orderStatusLabel.isHidden = order.isOrderProcessing()
        self.orderStatusLabel.text = self.orderStatusLabel.isHidden ? "" : (self.order.status == .completed) ? "Order Delivered" : "Order Cancelled"
        self.orderStatusLabel.textColor = self.orderStatusLabel.isHidden ? UIColor.white : (self.order.status == .completed) ? UIColor.themeColor() : UIColor.orderCancelColor()
        
        if order.isOrderProcessing() {
            var hashValue = OrderStatus.hashValueFrom(status: order.status ?? .pending)
            if true == order.isFleetOutLet {
                hashValue = OrderStatus.hashValueForFleetType(status: order.status ?? .pending)
            }

            for (index, imageView) in statusImageCollection.enumerated() {
                imageView.image = (imageView.tag <= hashValue) ? UIImage(named: "selected") : nil
                statusAnimationCollection[index].isHidden =  (statusAnimationCollection[index].tag == hashValue + 1
                    ) ? false : true
            }
            for label in statusLabelCollection {
                label.font = (label.tag <= hashValue) ? UIFont.montserratRegularWithSize(14.0) : UIFont.montserratLightWithSize(14.0)
                label.textColor = (label.tag <= hashValue) ? .selectedTextColor() : .unSelectedTextColor()
            }
        }
        
//        orderStatusView.layer.borderColor = order.isOrderProcessing() ? UIColor.white.cgColor : (order.status == .completed) ? UIColor.themeColor().cgColor : UIColor.orderCancelColor().cgColor
//        statusImageView.image = order.isOrderProcessing() ? nil : (order.status == .completed) ? UIImage(named: "completed") : UIImage(named: "cancel")
        
//        let title_ = order.isOrderProcessing() ? (order.status == .pending) ? "Cancel Order" : "Support" : (order.status == .completed) ? "Repeat Order" : "Re-Order"
//        aButton.setTitle( title_, for: .normal)
//        let aColor = order.isOrderProcessing() ? (order.status == .pending) ? UIColor.unSelectedColor() : UIColor.themeColor() : UIColor.themeColor()
//        aButton.setTitleColor(aColor, for: .normal)
//        aButton.layer.borderColor = aColor.cgColor
        
//        //Hides Support button
//        if order.isOrderProcessing() &&  order.status != .pending {
//            aButton.isHidden = true
//        }
//        else {
//            aButton.isHidden = (order.status == .cancelled)
//        }
        
//        //Displays applied promo code
//        if let aCoupon = order.coupon, false == aCoupon.code?.isEmpty {
//            couponLabel.isHidden = false
//            couponCodeBgViewHeightConstraint.constant = 40.0
//            couponLabel.text = aCoupon.code
//        }
//        else {
//            couponLabel.isHidden = true
//            couponCodeBgViewHeightConstraint.constant = 0.0
//        }
    }
    
}

extension OrderPendingCell: AnimationDelegate {
    
    func animationDidFinished(finished: Bool) {
        if finished {
            UIView.animate(withDuration: 0.25, delay: 0.2, options: [.curveEaseIn], animations: {
                self.updateProgressValues()
            })
            
        }
    }
}
