//
//  AppVersion.swift
//  WaselDelivery
//
//  Created by Purpletalk on 9/12/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

struct AppVersion: Unboxable {
    
    let version: String?
    let message: String?
    let forceUpdate: Bool?
    let appVersionbaseUrl: String?

    init(unboxer: Unboxer) throws {
        self.version = try? unboxer.unbox(key: "version")
        self.message = try? unboxer.unbox(key: "message")
        self.forceUpdate = try? unboxer.unbox(key: "forceUpdate")
        self.appVersionbaseUrl = try? unboxer.unbox(key: "s3BaseUrl")
    }
    
    init() {
        self.version = ""
        self.message = ""
        self.forceUpdate = false
        self.appVersionbaseUrl = ""
    }
}
