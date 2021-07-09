//
//  OutletItemCell.swift
//  WaselDelivery
//
//  Created by Sunanda on 2/19/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class OutletItemCell: UITableViewCell {
    
    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemDescriptionLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var spicyImageView: UIImageView!
    @IBOutlet weak var nonVegLabel: UILabel!
    
    @IBOutlet weak var titleLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentLeadingConstraint: NSLayoutConstraint!
    
    weak var reloadDelegate: ReloadDelegate?
    weak var delegate: FoodItemCellDelegate?
    weak var customiseDelegate: CustomizeDelegate?
    weak var alertDelegate: RemoveItemAlertDelegate?
    
    var isCustomized = false
    var outletItem: OutletItem!
    
    class func nib() -> UINib {
        return UINib(nibName: "OutletItemCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "OutletItemCell"
    }
    
    deinit {
        delegate = nil
        customiseDelegate = nil
        alertDelegate = nil
    }
    
    func loadCellWithData(_ foodItem: OutletItem) {
        
        outletItem = foodItem
        
        if let imageUrl_ = outletItem.imageUrl {
            itemImageView.sd_setImage(with: URL(string: imageUrl_), placeholderImage: UIImage(named: "item_placeholder"))
        } else {
            itemImageView.image = UIImage(named: "item_placeholder")
        }
        
        if let name_ = outletItem.name {
            itemNameLabel.text = name_.trim()
        } else {
            itemNameLabel.text = ""
        }
        
        itemDescriptionLabel.text = outletItem.itemDescription ?? ""
        
        let priceText = String(format: "%.3f", foodItem.price ?? 0.0)
        costLabel.text = String(describing: priceText)
        
        if let isVeg_ = outletItem.isVegItem {
            nonVegLabel.backgroundColor = (isVeg_ == true) ? UIColor.themeColor() : UIColor.red
            nonVegLabel.isHidden = false
        } else {
            nonVegLabel.isHidden = true
        }
        if let category_ = outletItem.itemCategory, let hideImage_ = category_.hideImage {
            contentLeadingConstraint.constant = (hideImage_ == true) ? 0.0 : 97.0
            itemImageView.isHidden = hideImage_
        }
        titleLeftConstraint.constant = (nonVegLabel.isHidden == true) ? 0.0 : 18.0
        self.contentView.layoutIfNeeded()
        
        if let isSpicy_ = outletItem.isSpicy {
            spicyImageView.isHidden = !isSpicy_
        } else {
            spicyImageView.isHidden = true
        }
        
        updateOutletItemCartUI()
        
    }
    
    func incrementOutletItemCount() {
        
        guard Utilities.isWaselDeliveryOpen() else {
            return
        }
        
        guard Utilities.shared.getTotalItems() < 99 else {
            Utilities.showToastWithMessage("Items limited to 99.")
            return
        }
        
        if let customisationItems_ = outletItem.customisationItems, customisationItems_.count > 0, let customiseDelegate_ = customiseDelegate {
            customiseDelegate_.showCustomiseView(forItem: outletItem)
            return
        }
        
        outletItem.cartQuantity += 1
        updateOutletItemCartUI()
        Utilities.shared.updateCart(outletItem)
        sendCartActivityToUpshot(isItemAdded: true)
//        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
        if let delegate_ = delegate {
            delegate_.reloadView()
        }
        if let reloadDelegate_ = reloadDelegate {
            reloadDelegate_.reloadData()
        }
    }
    
    @IBAction func showImagePopUp(_ sender: Any) {
        if let customiseDelegate_ = customiseDelegate {
            customiseDelegate_.showImagePopUpView(forItem: outletItem)
        }
    }
    
    // MARK: - SupportMethods
    
    func updateOutletItemCartUI() {
        countLabel.isHidden = !(outletItem.cartQuantity > 0)
        countLabel.text = "\(outletItem.cartQuantity)"
    }
    
    func getItemCustomizedCount() -> Int {
        
        if let customisationItems_ = outletItem.customisationItems {
            
            let total = customisationItems_.reduce(0) {acc, category in
                
                if let items_ = category.items {
                    let quant = items_.reduce(0) {acc1, item in
                        return acc1 + item.quantity
                    }
                    return acc + quant
                } else {
                    return acc
                }
            }
            return total
        }
        return 0
    }
    
    func sendCartActivityToUpshot(isItemAdded: Bool) {
        var params: [String: Any] = [
            "Action": isItemAdded ? "Add" : "Remove",
            "CartID": Utilities.shared.cartId ?? ""
        ]
        if let aOutlet_ = Utilities.shared.currentOutlet {
            if let amenityId = aOutlet_.amenity?.id {
                params["CategoryName"] = aOutlet_.amenity?.name ?? ""
                params["CategoryID"] = amenityId
                
                params["StoreName"] = aOutlet_.name ?? ""
                params["StoreID"] = String(aOutlet_.id ?? 0)
                if let deliveryCharge_ = aOutlet_.deliveryCharge {
                    params["DeliveryCost"] = deliveryCharge_
                }
            }
        }
        if let outletItemId = outletItem.id {
            params["ItemName"] = outletItem.name ?? ""
            params["ItemID"] = String(outletItemId)
            params["ItemCost"] = outletItem.price ?? 0.0
            params["SubCategoryName"] = outletItem.itemCategory?.parent?.name ?? ""
            params["SubCategoryID"] = outletItem.itemCategory?.parent?.id ?? ""
        }
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CART_ACTIVITY_EVENT, params: params)
    }
    
}
