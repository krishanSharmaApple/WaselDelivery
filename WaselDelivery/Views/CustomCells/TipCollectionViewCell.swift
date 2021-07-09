//
//  TipCollectionViewCell.swift
//  WaselDelivery
//
//  Created by ramchandra on 10/12/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class TipCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var tipLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
    }

    class func nib() -> UINib {
        return UINib(nibName: "TipCollectionViewCell", bundle: nil)
    }

    class func cellIdentifier() -> String {
        return "TipCollectionViewCell"
    }

    func updateTip(tip: Tip, isSelected: Bool) {
        if tip.amount > 0 {
            let isFills = tip.amount > 999 ? false : true
            let fils = tip.amount
            let dinams = tip.amount.getDinams()
            if isFills {
                tipLabel.text = "\(fils) Fils"
            } else {
                tipLabel.text = "\(String(format: "%.3f", dinams))" + " BD"
            }
        } else {
            tipLabel.text = "Others"
        }
        let selectionColor: UIColor = isSelected ? .themeColor() : .appBlack()
        self.layer.borderColor = selectionColor.cgColor
        tipLabel.textColor = selectionColor
    }

}
