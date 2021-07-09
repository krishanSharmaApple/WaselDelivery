//
//  DepartmentCell.swift
//  WaselDelivery
//
//  Created by sunanda on 11/3/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class DepartmentCell: UICollectionViewCell {

    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var departmentImage: UIImageView!
    
    class func nib() -> UINib {
        return UINib(nibName: "DepartmentCell", bundle: Bundle.main)
    }

    class func cellIdentifier() -> String {
        return "DepartmentCell"
    }
    
    func loadCellTitle(identity: Amenity) {
        
        departmentLabel.text = identity.name ?? ""
        if isSelected {
            let imageName = identity.imageName ?? "miscellaneous"
            var aImage = UIImage(named: imageName + "_active")
            if nil == aImage {
                aImage = UIImage(named: "miscellaneous" + "_active")
            }
            departmentImage.image = aImage
            departmentLabel.textColor = UIColor.themeColor()
            departmentLabel.font = UIFont.montserratRegularWithSize(14.0)
        } else {
            let imageName = identity.imageName ?? "miscellaneous"
            var aImage = UIImage(named: imageName)
            if nil == aImage {
                aImage = UIImage(named: "miscellaneous")
            }
            departmentImage.image = aImage
            departmentLabel.textColor = .unSelectedTextColor()
            departmentLabel.font = UIFont.montserratRegularWithSize(14.0)
        }
    }
    
}
