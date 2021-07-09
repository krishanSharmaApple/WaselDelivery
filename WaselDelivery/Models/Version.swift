//
//  Version.swift
//  WaselDelivery
//
//  Created by sunanda on 1/13/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

struct Version: Unboxable {
    
    let version: Int?
    let s3BaseUrl: String?
    
    init(unboxer: Unboxer) throws {
        self.version = try? unboxer.unbox(key: "version")
        self.s3BaseUrl = try? unboxer.unbox(key: "s3BaseUrl")
    }
    
    init() {
        self.version = 0
        self.s3BaseUrl = ""
    }
}
