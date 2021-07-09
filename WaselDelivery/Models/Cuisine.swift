//
//  Cuisine.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 15/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

class Cuisine: Unboxable {
    
    let id: Int
    let name: String
    var isFilterCusineSelected: Bool!
    
    required init(unboxer: Unboxer) throws {
        self.id = (try? unboxer.unbox(key: "cuisine_id")) ?? -1
        self.name = (try? unboxer.unbox(key: "name")) ?? ""
        self.isFilterCusineSelected = false
    }
}
