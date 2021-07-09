//
//  OutletItem.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 30/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

// parent - cart quantity -
//  -> cartItems - actual cart
// parent exists in Utilities cart and parent contains multiple items with different customizations

class OutletItem: Unboxable, Copyable {
    
    let id: Int?
    let name: String?
    var price: Double?
    let itemDescription: String?
    var imageUrl: String?
    var isVegItem: Bool?
    var isSpicy: Bool?
    let isActive: Bool?
    let isDeleted: Bool?
    let isRecommended: Bool?
    let itemCategory: ItemCategory?
    var customisationItems: [CustomizeCategory]?
    var cartQuantity: Int = 0
    var parent: OutletItem?
    var cartItems: [OutletItem]?
    var cartIndex = 0
    var instructions = ""

    required init(instance: OutletItem) {
        self.id = instance.id
        self.name = instance.name
        self.price = instance.price
        self.itemDescription = instance.itemDescription
        self.imageUrl = instance.imageUrl
        self.isVegItem = instance.isVegItem
        self.isSpicy = instance.isSpicy
        self.isActive = instance.isActive
        self.isDeleted = instance.isDeleted
        self.isRecommended = instance.isRecommended
        self.itemCategory = instance.itemCategory
        if let items = instance.customisationItems {
            self.customisationItems = items.map { $0.copy() }
        }
        self.cartQuantity = instance.cartQuantity
        self.cartIndex = instance.cartIndex
        self.parent = instance.parent
        self.instructions = instance.instructions
    }

    required init(unboxer: Unboxer) throws {
        
        self.id = try? unboxer.unbox(key: "id")
        self.name = try? unboxer.unbox(key: "name")
        self.price = try? unboxer.unbox(key: "price")
        self.itemDescription = try? unboxer.unbox(key: "description")
        self.imageUrl = try? unboxer.unbox(key: "imageUrl")
        if self.imageUrl != nil {
            self.imageUrl = imageBaseUrl+(self.imageUrl ?? "")
        }
        self.isActive = try? unboxer.unbox(key: "active")
        self.isDeleted = try? unboxer.unbox(key: "delete")
        self.isRecommended = try? unboxer.unbox(key: "recommend")
        self.itemCategory = try? unboxer.unbox(key: "itemCategory")
        getCustomizationItems(items: try? unboxer.unbox(key: "customizationItems"))
        let customFieldArray: [[String: AnyObject]]? = try? unboxer.unbox(key: "outletItemCustomFields")
        if let customFieldArray_ = customFieldArray {
            setOutletItemCustomFields(customFieldArray_)
        }
        self.parent = try? unboxer.unbox(key: "parent")
    }

    private func setOutletItemCustomFields(_ customFields: [[String: AnyObject]]) {
        
        for customField_ in customFields {
            if let field_ = customField_["field"] as? [String: AnyObject] {
                if let field = field_["field"] as? String, field == OutletItemCustomFieldType.cuisineType.rawValue {
                    if let value = customField_["value"] {
                        self.isVegItem = value as? Bool
                    }
                } else if let field = field_["field"] as? String, field == OutletItemCustomFieldType.spicy.rawValue {
                    if let value = customField_["value"] {
                        self.isSpicy = value as? Bool
                    }
                }
            }
        }
    }
    
    func getCustomizationItems(items: [[String: AnyObject]]?) {
        
        if let items_ = items {
            var customize = [CustomizeCategory]()
            
            // collecting category id's
            let categoryIDs = items_.map { (($0 as [String: Any])["category"] as? [String: AnyObject])?["id"]  as? Int }.compactMap { $0 }.reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
            
            for id_ in categoryIDs {
                // for each category collecting sub-category items
                let categoryItems = items_.filter { (($0 as [String: Any])["category"] as? [String: AnyObject])?["id"]  as? Int == id_ }
                var subCategories = [CustomizeItem]()
                for categoryItem_ in categoryItems {
                    subCategories.append(CustomizeItem(categoryItem_ as [String: AnyObject]))
                }
                let item = categoryItems[0]
                if let category = item["category"] as? [String: AnyObject] {
                    customize.append(CustomizeCategory(category, subCategories))
                }
            }
            customisationItems = customize
            sortCustomizationItems()
        }
    }
    
    func sortCustomizationItems() {
        
        if var customizationItems_ = customisationItems {
            var radioArray = customizationItems_.filter { $0.categoryMode == .anyOne }
            radioArray = radioArray.sorted { $0.name ?? "" < $1.name ?? "" }
            
            var otherArray = customizationItems_.filter { $0.categoryMode != .anyOne }
            otherArray = otherArray.sorted { $0.name ?? "" < $1.name ?? "" }
            
            customizationItems_.removeAll()
            customizationItems_.append(contentsOf: radioArray)
            customizationItems_.append(contentsOf: otherArray)
            customisationItems?.removeAll()
            customisationItems = customizationItems_
        }
    }
    
    func customizedItems() -> CustomisedItem? {
        
        if let categories_ = self.customisationItems, categories_.count > 0 {
            
            let items_  = categories_.map { $0.items }.compactMap { $0 }.flatMap { $0 }
            var customisedItem = CustomisedItem(index: self.cartIndex, customisedItems: nil)
            _ = items_.filter { $0.quantity > 0 }.map({ (customizeItem) -> CustomizeItem in
                if nil != customisedItem.customisedItems {
                    customisedItem.customisedItems?.append(CustomisedTuple(id: customizeItem.id ?? 0, quantity: customizeItem.quantity))
                } else {
                    customisedItem.customisedItems = [CustomisedTuple(id: customizeItem.id ?? 0, quantity: customizeItem.quantity)]
                }
                return customizeItem
            })
            if nil != customisedItem.customisedItems {
                return customisedItem
            } else {
                customisedItem.customisedItems = [CustomisedTuple(id: -1, quantity: -1)]
                return customisedItem
            }
        }
        return nil
    }
    
    func getCustomizationCost() -> Double {
        
        guard let customisationItems_ = customisationItems else { return 0.0 }
        let items = customisationItems_.compactMap { $0.items }.flatMap({ $0 })
        let price = items.reduce(0.0) {acc, item in
            if item.isCheck || item.isRadioSelectionEnabled {
                return acc + Double(item.price ?? 0.0)
            }
            return acc + Double((item.price ?? 0.0) * Double(item.quantity))
        }
        return price
    }
    
    func getItemCost() -> Double {
        let quantity = Double(cartQuantity)
        let singleItemCost = getCustomizationCost() + (self.price ?? 0.0)
        return (quantity * singleItemCost)
    }

    func getCustomizationText() -> String {
        
        var customizationString = ""
        if let c_ = self.customisationItems {
            _ = c_.map({ (customizeCategory) -> CustomizeCategory in
                if let cI_ = customizeCategory.items {
                    _ = cI_.map({ (customizeItem) -> CustomizeItem in
                        if let name_ = customizeItem.name, customizeItem.quantity > 0 {
                            customizationString += customizationString == "" ? "" : ", "
                            customizationString.append("\(name_) x \(customizeItem.quantity )")
                        }
                        return customizeItem
                    })
                }
                return customizeCategory
            })
        }
        return customizationString
    }
    
    func getCostOutletItemDetailsDataForCell(withImage shouldRepeatOrder: Bool) -> (imageUrl: String, name: String, description: String, price: String, isVeg: Bool, isSpicy: Bool, hideCategoryImage: Bool) {
        
        let imageUrl_ = imageUrl ?? ""
        let name_ = name?.trim() ?? ""
        let description_ = (0 < customisationItems?.count ?? 0) ? getCustomizationText() : (itemDescription ?? "")
        let price_ = String(format: "%.3f", price ?? 0.0)
        let isVeg_ = !(isVegItem ?? false)
        let isSpicy_ = !(isSpicy ?? false)
        var hideCategoryImage_ = false
        
        if let category_ = itemCategory, let hideImage_ = category_.hideImage {
            hideCategoryImage_ = hideImage_
        }
        return (imageUrl_, name_, description_, price_, isVeg_, isSpicy_, hideCategoryImage_)
    }

}
