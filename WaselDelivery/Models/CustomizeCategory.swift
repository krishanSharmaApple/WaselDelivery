//
//  CustomizeCategory.swift
//  WaselDelivery
//
//  Created by sunanda on 11/25/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CustomizeCategory: Copyable {

    let id: Int?
    let name: String?
    var categoryMode: CategoryMode?
    var isActive: Bool = false
    var items: [CustomizeItem]?
    
    required init(instance: CustomizeCategory) {
        self.id = instance.id
        self.name = instance.name
        self.isActive = instance.isActive
        self.categoryMode = instance.categoryMode
        var customiseItems_ = [CustomizeItem]()
        if let items_ = instance.items {
            for item_ in items_ {
                let item = item_.copy()
                customiseItems_.append(item)
            }
            self.items = customiseItems_
        } else {
            self.items = nil
        }
    }
    
    required init(_ category: [String: AnyObject], _ items: [CustomizeItem]) {
        if let id_ = category["id"] as? Int {
            self.id = id_
        } else {
            self.id = nil
        }
        if let name_ = category["name"] as? String {
            self.name = name_
        } else {
            self.name = nil
        }
        if let active_ = category["active"] as? Bool {
            self.isActive = active_
        }
        if let type_ = category["selectionType"] as? String {
            switch type_ {
            case "MULTIPLE":
                self.categoryMode = .check
            case "ANY_ONE":
                self.categoryMode = .anyOne
            default:
                self.categoryMode = .count
            }
        } else {
            self.categoryMode = nil
        }
        self.items = items
        
        if let items = self.items {
            if self.categoryMode == .anyOne {
                items[0].isRadioSelectionEnabled = true
                items[0].quantity = 1
            }
        }
    }

}
