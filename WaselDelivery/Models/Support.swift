//
//  Support.swift
//  WaselDelivery
//
//  Created by sunanda on 1/24/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

struct Support: Unboxable {
    
    let mobile: String?
    let email: String?
    
    init(unboxer: Unboxer) throws {
        self.mobile = try? unboxer.unbox(key: "mobile")
        self.email = try? unboxer.unbox(key: "email")
    }
    
    init() {
        mobile = ""
        email = ""
    }
}
