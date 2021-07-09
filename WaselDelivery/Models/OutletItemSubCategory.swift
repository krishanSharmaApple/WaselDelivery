//
//  OutletItemSubCategory.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 30/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OutletItemSubCategory {
    
    var name: String?
    var foodItems: [OutletItem]?
    var isExpanded: Bool?

    required init(name_: String?, items_: [OutletItem]?, isExpand: Bool? = false) {
        self.name = name_
        self.foodItems = items_
        self.isExpanded = isExpand
    }
}
