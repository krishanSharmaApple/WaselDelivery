//
//  OrderItemCell.swift
//  WaselDelivery
//
//  Created by sunanda on 12/5/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderItemCell: UITableViewCell {

    @IBOutlet weak var spicyImageView: UIImageView!
    @IBOutlet weak var foodTypeLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemDescriptionLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var itemImageView: UIImageView!

    var outletItem: OrderItem!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var itemImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var itemImageViewHeightConstraint: NSLayoutConstraint!

    class func cellIdentifier() -> String {
        return "OrderItemCell"
    }

    func loadItem(_ item: OrderItem!) {
        
        outletItem = item
        let orderItemDetails = outletItem.getOrderItemDetails()
        itemNameLabel.text = orderItemDetails.itemName
        quantityLabel.text = orderItemDetails.quantity
        itemPriceLabel.text = orderItemDetails.itemPrice
        itemDescriptionLabel.text = orderItemDetails.description
        
        foodTypeLabel.isHidden = orderItemDetails.hideFoodTypeLabel_
        foodTypeLabel.backgroundColor = (orderItemDetails.hideFoodTypeLabel_ == true) ? UIColor.themeColor() : UIColor.red
        
        spicyImageView.isHidden = orderItemDetails.hideSpicyImage

        let placeHolderImage = UIImage(named: "item_placeholder")
        if let imagesArray_ = outletItem.imageUrls, 0 < imagesArray_.count, let imageName_ = imagesArray_.first {
            let imageUrlStr_ = imageBaseUrl+imageName_
            self.itemImageView.sd_setImage(with: URL(string: imageUrlStr_), placeholderImage: placeHolderImage)
        } else {
            self.itemImageView.image = placeHolderImage
        }
        
        titleLabelLeadingConstraint.constant = (foodTypeLabel.isHidden == true) ? 0.0 : 20.0
        setNeedsLayout()
        layoutIfNeeded()
    }

}
