//
//  OrderCustomItem.swift
//  WaselDelivery
//
//  Created by sunanda on 12/5/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct OrderCustomItem: Unboxable {

    let id: Int?
    let itemId: Int?
    let name: String?
    let price: Double?
    var quantity: Int?

    init(unboxer: Unboxer) throws {
        
        self.id = try? unboxer.unbox(key: "id")
        self.itemId = try? unboxer.unbox(key: "customItemId")
        self.name = try? unboxer.unbox(key: "name")
        self.price = try? unboxer.unbox(key: "price")
        self.quantity = try? unboxer.unbox(key: "quantity")
    }

}
