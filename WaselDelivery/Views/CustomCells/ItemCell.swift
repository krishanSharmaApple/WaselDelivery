//
//  ItemCell.swift
//  WaselDelivery
//
//  Created by sunanda on 3/1/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class ItemCell: UICollectionViewCell {

    @IBOutlet weak var customizationLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var incrementButton: UIButton!
    @IBOutlet weak var decrementButton: UIButton!
    
    weak var reloadDelegate: ReloadDelegate?
    weak var alertDelegate: RemoveItemAlertDelegate?
    var outletItem: OutletItem!
    
    class func nib() -> UINib {
        return UINib(nibName: "ItemCell", bundle: nil)
    }

    class func cellIdentifier() -> String {
        return "ItemCell"
    }
    
// MARK: Support Methods
    
    @IBAction func incrementItem(_ sender: Any) {
        guard Utilities.shared.getTotalItems() < 99 else {
            Utilities.showToastWithMessage("Items limited to 99.")
            return
        }
        
        outletItem.cartQuantity += 1
        if let parent_ = outletItem.parent {
            parent_.cartQuantity += 1
        }
        Utilities.shared.updateCart(outletItem)
        if let reloadDelegate_ = reloadDelegate {
            reloadDelegate_.reloadData()
        }
    }
    
    @IBAction func derementItem(_ sender: Any) {
        
        var count = outletItem.cartQuantity
        count -= 1
        
        if let alertDelegate_ = alertDelegate, count == 0 {
            alertDelegate_.showRemoveItemAlert(outletItem)
        } else {
            outletItem.cartQuantity = count
            if let parent_ = outletItem.parent {
                parent_.cartQuantity -= 1 //decrementing count for parent
                if nil != parent_.cartItems, count == 0 {
                    if let index = parent_.cartItems?.index(where: { $0 === outletItem }) {
                        parent_.cartItems?.remove(at: index) //removing from parent cartitems
                    }
                }// repeating above 6 lines code in CartViewController need to change
            } else {
                outletItem.instructions = ""
            }
            Utilities.shared.updateCart(outletItem)
            if let reloadDelegate_ = reloadDelegate {
                reloadDelegate_.reloadData()
            }
        }
    }
    
    func loadItemAtIndex(item: OutletItem) {
        
        self.outletItem = item
        updateUI()
    }
    
    func updateUI() {
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
            decrementButton.isEnabled = (outletItem.cartQuantity > 0) ? true : false
        }
        countLabel.text = "\(outletItem.cartQuantity)"
        setCustomizationText()
        setPrice()
    }
    
    func setCustomizationText() {
        
        var customizationString = ""
        if let c_ = outletItem.customisationItems {
            _ = c_.map({ (customizeCategory) -> CustomizeCategory in
                if let cI_ = customizeCategory.items {
                    _ = cI_.map({ (customizeItem) -> CustomizeItem in
                        if let name_ = customizeItem.name, customizeItem.quantity > 0 {
                            customizationString.append("\(name_) x \(customizeItem.quantity )")
                        }
                        return customizeItem
                    })
                }
                return customizeCategory
            })
        }
        customizationLabel.text = customizationString
    }
    
    func setPrice() {
        let priceText = String(format: "%.3f", getTotalCost())
        priceLabel.text = String(describing: priceText)
    }
    
    func getTotalCost() -> Double {
        let price = getCustomizationCost() + (outletItem.price ?? 0.0 * Double(outletItem.cartQuantity))
        return price
    }
    
    func getCustomizationCost() -> Double {
        if let customisationItems_ = outletItem.customisationItems, customisationItems_.count > 0 {
            let customisationItems = customisationItems_.compactMap { $0.items }.flatMap { $0 }
            return Double(outletItem.cartQuantity) * customisationItems.reduce(0.0) { acc, item in
                return acc + (item.price ?? 0.0) * Double(item.quantity)
            }
        } else {
            return 0.000
        }
    }

}
