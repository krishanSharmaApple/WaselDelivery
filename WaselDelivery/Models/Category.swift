//
//  Category.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 07/10/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

class Category: Unboxable {
    let id: Int?
    let parentId: Int?
    let name: String?
    var isFilterCusineSelected: Bool!
    
    required init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.parentId = try? unboxer.unbox(key: "parentId")
        self.name = try? unboxer.unbox(key: "name")
    }
}
