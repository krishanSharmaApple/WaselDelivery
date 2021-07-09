//
//  CouponDetailCell.swift
//  WaselDelivery
//
//  Created by sunanda on 3/8/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class CouponDetailCell: UITableViewCell {

    weak var couponDelegate: CouponProtocol?
    var isDottedLineAdded: Bool = false
    
    @IBOutlet var applyButton: UIButton!
    @IBOutlet var couponView: UIView!
    @IBOutlet var couponLabel: UILabel!
    
    class func cellIdentifier() -> String {
        return "CouponDetailCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyButton.setTitle("", for: .selected)
        applyButton.setTitle("Apply Coupon Code", for: .normal)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if isDottedLineAdded == false {
            isDottedLineAdded = true
            let shapeLayer = CAShapeLayer()
            let frameSize = applyButton.frame.size
            let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
            shapeLayer.bounds = shapeRect
            shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = UIColor.selectedTextColor().cgColor
            shapeLayer.lineWidth = 1
            shapeLayer.lineJoin = .round
            shapeLayer.lineDashPattern = [6, 3]
            shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 6).cgPath
            applyButton.layer.addSublayer(shapeLayer)
        }
    }
    
    func loadCellWithCoupon(coupon: Coupon?) {
        if let coupon_ = coupon {
            couponView.isHidden = false
            couponLabel.text = coupon_.code ?? ""
            applyButton.isSelected = true
            applyButton.backgroundColor = UIColor(red: (249.0/255.0), green: (249.0/255.0), blue: (249.0/255.0), alpha: 1.0)
        } else {
            couponView.isHidden = true
            applyButton.isSelected = false
            applyButton.backgroundColor = .white
        }
    }
    
    @IBAction func applyButtonAction(_ sender: Any) {
        if let couponDelegate_ = couponDelegate {
            couponDelegate_.couponAction(state: applyButton.isSelected)
        }
    }

}
