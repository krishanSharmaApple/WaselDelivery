//
//  MenuTitleCell.swift
//  WeselDeliverySample
//
//  Created by sunanda on 9/16/16.
//  Copyright © 2016 purpletalk. All rights reserved.
//

import UIKit

class MenuTitleCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    class func nib() -> UINib {
        return UINib(nibName: "MenuTitleCell", bundle: Bundle.main)
    }

    class func cellIdentifier() -> String {
        return "MenuTitleCell"
    }

    func loadCell(_ title: String) {
        
        titleLabel.text = title
        if isSelected {
            titleLabel.textColor = .black
            titleLabel.font = UIFont.montserratSemiBoldWithSize(16.0)
        } else {
            titleLabel.textColor = UIColor.lightGray
            titleLabel.font = UIFont.montserratLightWithSize(14.0)
        }
    }
}
