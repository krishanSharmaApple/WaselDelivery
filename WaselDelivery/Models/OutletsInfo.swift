//
//  Outlet.swift
//  WaselDelivery
//
//  Created by Purpletalk on 20/07/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

class OutletsInfo: Unboxable {
    
    let outlet: [Outlet]?
    let location: String?
    var selectedOutletIndex = -1
    
    required init(unboxer: Unboxer) throws {
        self.location = try? unboxer.unbox(key: "location")
        self.outlet = try? unboxer.unbox(key: "outlets")
    }
    
}
