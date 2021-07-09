//
//  OrderCancelReason.swift
//  WaselDelivery
//
//  Created by Purpletalk on 01/02/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct OrderCancelReason: Unboxable {
    
    var id: Int?
    var reason: String?

    init() {
    }

    init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.reason = try? unboxer.unbox(key: "reason")
    }

}
