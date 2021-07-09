//
//  Amenity.swift
//  WaselDelivery
//
//  Created by sunanda on 11/14/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct Amenity: Unboxable {
    
    let id: String?
    let name: String?
    let imageUrl: String?
    var imageName: String?

    init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.name = try? unboxer.unbox(key: "name")
        self.imageUrl = try? unboxer.unbox(key: "imageUrl")
        if let id_ = self.imageUrl {
            self.imageName = "a_\(id_)"
        }
    }

    init(id: String?, name: String?, imageUrl: String?) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        if let id_ = self.imageUrl {
            self.imageName = "a_\(id_)"
        }
    }
}

extension Amenity: Equatable {
    static func == (lhs: Amenity, rhs: Amenity) -> Bool {
        return
            lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.imageUrl == rhs.imageUrl &&
            lhs.imageName == rhs.imageName
    }
}
