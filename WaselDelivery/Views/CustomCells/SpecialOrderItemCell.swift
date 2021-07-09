//
//  SpecialOrderItemCell.swift
//  WaselDelivery
//
//  Created by sunanda on 12/8/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class SpecialOrderItemCell: UITableViewCell {

    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var productImageView: UIImageView!
    
    class func cellIdentifier() -> String {
        return "SpecialOrderItemCell"
    }
    
    func loadItem(_ item: OrderItem) {
        
        let placeHolderImage = UIImage(named: "item_placeholder")
        if let name_ = item.name {
            itemTitleLabel.text = name_
        }
        if let imagesArray_ = item.imageUrls, 0 < imagesArray_.count, let imageName_ = imagesArray_.first {
            let imageUrlStr_ = imageBaseUrl+imageName_
            self.productImageView.sd_setImage(with: URL(string: imageUrlStr_), placeholderImage: placeHolderImage)
        } else {
            self.productImageView.image = placeHolderImage
        }
    }
    
}
