//
//  CouponCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 24/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CouponCell: UITableViewCell {

    @IBOutlet weak var couponTitle: UILabel!
    @IBOutlet weak var useCodeLabel: UILabel!
    @IBOutlet weak var couponLabel: UILabel!
    @IBOutlet weak var applyButton: UIButton!
    
    weak var delegate: CouponCellDelegate?
    var isDottedLineAdded: Bool = false
    var coupon: Coupon!
    var isOfferType = false
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        // add dotted border
        let shapeLayer = CAShapeLayer()
        let frameSize = applyButton.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = (isOfferType == true) ? UIColor.unSelectedTextColor().cgColor : (coupon.isSelected == true) ? UIColor.themeColor().cgColor : UIColor.unSelectedTextColor().cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineJoin = .round
        shapeLayer.lineDashPattern = [6, 3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 6).cgPath
        applyButton.layer.addSublayer(shapeLayer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyButton.isExclusiveTouch = true
        self.isExclusiveTouch = true
    }

    class func nib() -> UINib {
        return UINib(nibName: "CouponCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "CouponCell"
    }
    
    func loadCellWithCoupon(_ coupon: Coupon) {
        self.coupon = coupon
        couponTitle.text = coupon.name
        couponLabel.text = coupon.code
        if isOfferType == true {
            if self.coupon.isSelected == true {
                useCodeLabel.text = "Copied"
                useCodeLabel.textColor = UIColor.selectedTextColor()
            } else {
                useCodeLabel.text = "Copy code"
                useCodeLabel.textColor = UIColor.unSelectedTextColor()
            }
        } else {
            setNeedsDisplay()
        }
    }
    
    @IBAction func applyCoupon(_ sender: Any) {
        
        self.coupon.isSelected = !self.coupon.isSelected
        if isOfferType == true {
            UIPasteboard.general.string = (self.coupon.isSelected == true) ? self.coupon.code ?? "" : ""
        }
        
        if let delegate_ = delegate {
            delegate_.selectedCoupon(cell: self)
        }
    }
}

protocol CouponCellDelegate: class {
    func selectedCoupon(cell: CouponCell)
}
