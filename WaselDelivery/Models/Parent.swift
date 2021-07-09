//
//  Parent.swift
//  WaselDelivery
//
//  Created by Purpletalk on 11/16/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct Parent: Unboxable {

    let id: Int?
    let name: String?
    
    init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.name = try? unboxer.unbox(key: "name")
    }
}
