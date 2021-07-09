//
//  DriverTipCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 15/2/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class DriverTipView: UIView {

    @IBOutlet weak var tipAmountLabel: UILabel!
    @IBOutlet weak var tipCollectionView: UICollectionView!
    @IBOutlet weak var tipView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
        tipView.isHidden = true
    }

    class func nib() -> UINib {
        return UINib(nibName: "DriverTipCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "DriverTipCell"
    }
    
    func updateTipAmount(tip: Tip) {
        tipView.isHidden = tip.amount > 0 ? false : true
        let amount = tip.amount.getDinams()
        tipAmountLabel.text = amount > 0 ? "\(String(format: "%.3f", amount))" : ""
        tipCollectionView.reloadData()
    }
    
}
