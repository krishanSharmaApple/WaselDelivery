//
//  FoodItemCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import SDWebImage

class FoodItemCell: UITableViewCell {

    @IBOutlet weak var instructionsTextField: UITextField!
    @IBOutlet weak var decButton: UIButton!
    @IBOutlet weak var incButton: UIButton!
    @IBOutlet weak var decrementButton: UIButton!
    @IBOutlet weak var incrementButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemDescriptionLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var spicyImageView: UIImageView!
    @IBOutlet weak var nonVegLabel: UILabel!
    
    @IBOutlet weak var titleLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var countView: UIView!

    weak var reloadDelegate: ReloadDelegate?
    weak var delegate: FoodItemCellDelegate?
    weak var customiseDelegate: CustomizeDelegate?
    weak var alertDelegate: RemoveItemAlertDelegate?
    var isCustomized = false
    var outletItem: OutletItem!
    
    class func nib() -> UINib {
        return UINib(nibName: "FoodItemCell", bundle: nil)
    }

    class func cellIdentifier() -> String {
        return "FoodItemCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        incButton.isExclusiveTouch = true
        decButton.isExclusiveTouch = true
    }
    
    deinit {
        delegate = nil
        customiseDelegate = nil
        alertDelegate = nil
    }
    
    func loadCellWithData(_ foodItem: OutletItem, withImage shouldRepeatOrder: Bool) {
        outletItem = foodItem
        let costOutletItemDetails = outletItem.getCostOutletItemDetailsDataForCell(withImage: shouldRepeatOrder)
        if true == costOutletItemDetails.imageUrl.isEmpty {
            itemImageView.image = UIImage(named: "item_placeholder")
        } else {
            itemImageView.sd_setImage(with: URL(string: costOutletItemDetails.imageUrl), placeholderImage: UIImage(named: "item_placeholder"))
        }
        itemNameLabel.text = costOutletItemDetails.name
        itemDescriptionLabel.text = costOutletItemDetails.description
        costLabel.text = String(describing: costOutletItemDetails.price)
        if let isVeg = foodItem.isVegItem {
            nonVegLabel.backgroundColor = isVeg ? .themeColor() : .red
            nonVegLabel.isHidden = false
        } else {
            nonVegLabel.isHidden = true
        }
        contentLeadingConstraint.constant = (costOutletItemDetails.hideCategoryImage == true) ? 0.0 : 97.0
        itemImageView.isHidden = costOutletItemDetails.hideCategoryImage
        titleLeftConstraint.constant = (nonVegLabel.isHidden == true) ? 0.0 : 18.0
        self.contentView.layoutIfNeeded()
        spicyImageView.isHidden = costOutletItemDetails.isSpicy
        updateOutletItemCartUI()
    }
    
    @IBAction func incrementOutletItemCount(_ sender: Any) {
        
        guard Utilities.shared.getTotalItems() < 99 else {
            Utilities.showToastWithMessage("Items limited to 99.")
            return
        }

        incButton.isUserInteractionEnabled = false

        outletItem.cartQuantity += 1
        if let parent_ = outletItem.parent {
            parent_.cartQuantity += 1
        }
        updateOutletItemCartUI()
        Utilities.shared.updateCart(outletItem)
        sendCartActivityToUpshot(isItemAdded: true)
        incButton.isUserInteractionEnabled = true
        if let delegate_ = delegate {
            delegate_.reloadView()
        }
        if let reloadDelegate_ = reloadDelegate {
            reloadDelegate_.reloadData()
        }
    }
    
    @IBAction func decrementOutletItemCount(_ sender: Any) {
        
        var count = outletItem.cartQuantity
        count -= 1
        if let alertDelegate_ = alertDelegate, count == 0 {
            alertDelegate_.showRemoveItemAlert(outletItem)
        } else {
            decButton.isUserInteractionEnabled = false
            
            outletItem.cartQuantity = count
            if let parent_ = outletItem.parent {
                parent_.cartQuantity -= 1 //decrementing count for parent
                if nil != parent_.cartItems, count == 0 {
                    if let index = parent_.cartItems?.index(where: { $0 === outletItem }) {
                        parent_.cartItems?.remove(at: index) //removing from parent cartitems
                    }
                }
            }// repeating above 6 lines code in CartViewController need to change
            Utilities.shared.updateCart(outletItem)
            
            sendCartActivityToUpshot(isItemAdded: false)
            decButton.isUserInteractionEnabled = true
            updateOutletItemCartUI()
            if let delegate_ = delegate {
                delegate_.reloadView()
            }
            if let reloadDelegate_ = reloadDelegate {
                reloadDelegate_.reloadData()
            }
        }
    }
    
    @IBAction func customiseItem(_ sender: Any) {
        if let customisationItems_ = outletItem.customisationItems, customisationItems_.count > 0, let customiseDelegate_ = customiseDelegate {
            customiseDelegate_.showCustomiseView(forItem: outletItem)
        }
    }
    
    @IBAction func showImagePopUp(_ sender: Any) {
        if let customiseDelegate_ = customiseDelegate {
            customiseDelegate_.showImagePopUpView(forItem: outletItem)
        }
    }
    
// MARK: - SupportMethods
    
    func updateOutletItemCartUI() {
        countLabel.text = "\(outletItem.cartQuantity)"
        self.updateOutletItemButtonsUI()
        countLabel.text = "\(outletItem.cartQuantity)"
    }
    
    func updateOutletItemButtonsUI() {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        if false == isAppOpen {
            incrementButton.isEnabled = false
            decrementButton.isEnabled = false
            incrementButton.layer.borderColor = UIColor.lightGray.cgColor
            decrementButton.layer.borderColor = UIColor.lightGray.cgColor
        } else {
            incrementButton.isEnabled = true
            incrementButton.layer.borderColor = UIColor.black.cgColor
            decrementButton.layer.borderColor = (outletItem.cartQuantity > 0) ? UIColor.black.cgColor : UIColor.lightGray.cgColor
            decButton.isEnabled = (outletItem.cartQuantity > 0) ? true : false
            decrementButton.isEnabled = (outletItem.cartQuantity > 0) ? true : false
        }
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

extension FoodItemCell: UITextFieldDelegate {
    
// MARK: UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= MaxCharacters
    }
}

protocol CustomizeDelegate: class {
    func showCustomiseView(forItem item: OutletItem)
    func showImagePopUpView(forItem item: OutletItem)
}

protocol FoodItemCellDelegate: class {
    func reloadView()
}

protocol RemoveItemAlertDelegate: class {
    func showRemoveItemAlert(_ outletItem: OutletItem)
}
