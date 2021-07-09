//
//  OrderItem.swift
//  WaselDelivery
//
//  Created by sunanda on 12/5/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct OrderItem: Unboxable {
    
    let id: Int?
    let itemId: Int?
    let name: String?
    let price: Double?
    let isVeg: Bool?
    let isSpicy: Bool?
    let description: String?
    var customItems: [OrderCustomItem]?
    var quantity: Int?
    var imageUrls: [String]?

    init(unboxer: Unboxer) throws {
        
        self.id = try? unboxer.unbox(key: "id")
        self.itemId = try? unboxer.unbox(key: "itemId")
        self.name = try? unboxer.unbox(key: "name")
        self.price = try? unboxer.unbox(key: "price")
        self.isVeg = try? unboxer.unbox(key: "isVeg")
        self.isSpicy = try? unboxer.unbox(key: "isSpicy")
        self.quantity = try? unboxer.unbox(key: "quantity")
        self.description = try? unboxer.unbox(key: "description")
        self.customItems = try? unboxer.unbox(key: "customItems")
        self.imageUrls = try? unboxer.unbox(key: "imageUrls")
    }
    
    func getOrderItemDetails() -> (itemName: String, quantity: String, itemPrice: String, description: String, hideFoodTypeLabel_: Bool, hideSpicyImage: Bool) {
        let itemName_ = name ?? ""
        let quantity_ = "\(quantity ?? 0)"

        var itemPrice_ = ""
        if price != nil {
            itemPrice_ = String(format: "%.3f", getTotalCost())
        }
        let description_ = (0 < customItems?.count ?? 0) ? getCustomizationText() : (description ?? "")
        var hideFoodTypeLabel_ = true
        if isVeg != nil {
            hideFoodTypeLabel_ = false
        }
        let hideSpicyImage_ = !(isSpicy ?? false)
        return (itemName_, quantity_, itemPrice_, description_, hideFoodTypeLabel_, hideSpicyImage_)
    }
    
    private func getTotalCost() -> Double {
        
        var total_: Double = 0.0
        let price_: Double = (self.price ?? 0.0) * Double(quantity ?? Int(0))
        let customisationcost = getCustomizationCost()
        total_ = price_ + customisationcost
        return total_
    }
    
    private func getCustomizationCost() -> Double {
        if let customisationItems_ = customItems, customisationItems_.count > 0 {
            let quantity_ = Double(quantity ?? Int(0))
            return quantity_ * customisationItems_.compactMap { $0 }.reduce(0.0) { acc, item in
                return acc + (item.price ?? 0.0) * Double(item.quantity ?? Int(0))
            }
        }
        return 0.0
    }
    
    private func getCustomizationText() -> String {
        var customizationString = ""
        if let customItems_ = customItems {
            _ = customItems_.map({ (orderCustomItem) -> OrderCustomItem in
                if let name_ = orderCustomItem.name, let quantity_ = orderCustomItem.quantity, quantity_ > 0 {
                    customizationString += customizationString == "" ? "" : ", "
                    customizationString.append("\(name_) x \(quantity_)")
                }
                return orderCustomItem
            })
        }
        return customizationString
    }

}
