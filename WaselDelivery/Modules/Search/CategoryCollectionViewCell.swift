//
//  CategoryCollectionViewCell.swift
//  WaselDelivery
//
//  Created by Karthik on 28/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var categoryImageView: UIImageView!
    @IBOutlet weak var leftBorderViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBorderViewHeightConstraint: NSLayoutConstraint!

    class func cellIdentifier() -> String {
        return "CategoryCollectionViewCell"
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "CategoryCollectionViewCell", bundle: Bundle.main)
    }
    
    func configureCell(_ amenity: Amenity?, isFirstRow: Bool? = false, isFirstColumn: Bool? = false) {
        if let amenity_ = amenity {
            self.categoryImageView.image = UIImage(named: amenity_.imageName ?? "" + "_active")
            self.categoryNameLabel.text = amenity_.name ?? ""
        } else {
            self.categoryImageView.image = nil
            self.categoryNameLabel.text = ""
        }
        
        if true == isFirstRow {
            topBorderViewHeightConstraint.constant = 1.0
        } else {
            topBorderViewHeightConstraint.constant = 0.0
        }
        
        if true == isFirstColumn {
            leftBorderViewWidthConstraint.constant = 1.0
        } else {
            leftBorderViewWidthConstraint.constant = 0.0
        }
    }
}
