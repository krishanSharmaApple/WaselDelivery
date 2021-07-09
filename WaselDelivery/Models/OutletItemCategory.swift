//
//  OutletItemCategory.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 30/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

struct OutletItemCategory {
    
    var name: String?
    var categories: [OutletItemSubCategory]?
    
    init(name_: String?, categories_: [OutletItemSubCategory]?) {
        self.name = name_
        self.categories = categories_
    }
}
