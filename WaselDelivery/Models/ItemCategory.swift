//
//  ItemCategory.swift
//  WaselDelivery
//
//  Created by sunanda on 11/16/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct ItemCategory: Unboxable {

    let id: Int?
    var name: String?
    let disable: Bool?
    let hideImage: Bool?
    let parent: Parent?
    
    init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.name = try? unboxer.unbox(key: "name")
        if let name_ = self.name, name_.count > 0 {} else {
            self.name = "Menu"
        }// didn't use guard as we hav to return
        self.disable = try? unboxer.unbox(key: "disable")
        self.hideImage = try? unboxer.unbox(key: "hideImage")
        self.parent = try? unboxer.unbox(key: "parent")
    }

}
