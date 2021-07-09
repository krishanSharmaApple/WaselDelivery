//
//  CustomizeItem.swift
//  WaselDelivery
//
//  Created by sunanda on 11/25/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CustomizeItem: Copyable {
    
    let id: Int?
    let name: String?
    var price: Double?
    var isActive: Bool = false
    var quantity = 0
    var isCheck = false
    var isRadioSelectionEnabled = false
    
    required init(instance: CustomizeItem) {
        self.id = instance.id
        self.name = instance.name
        self.price = instance.price
        self.quantity = instance.quantity
        self.isCheck = instance.isCheck
        self.isActive = instance.isActive
        self.isRadioSelectionEnabled = instance.isRadioSelectionEnabled
    }
    
    required init(_ item: [String: AnyObject]) {
        
        if let id_ = item["id"] as? Int {
            self.id = id_
        } else {
            self.id = nil
        }
        if let name_ = item["name"] as? String {
            self.name = name_
        } else {
            self.name = nil
        }
        if let active_ = item["active"] as? Bool {
            self.isActive = active_
        }
        if let price_ = item["price"] as? Double {
            self.price = price_
        } else {
            self.price = nil
        }
    }

}
