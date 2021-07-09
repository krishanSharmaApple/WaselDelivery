//
//  Coupon.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 24/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

enum OfferType: String, UnboxableEnum {
    case percentageBased = "PERCENTAGEBASED"
    case amountBased = "AMOUNTBASED"
}

struct Coupon: Unboxable {
    let id: Int?
    let name: String?
    let code: String?
    let description: String?
    let offerType: OfferType?
    let minOrderValue: Double?
    let percentageValue: Double?
    let discountAmount: Double?
    var isSelected = false
    
    init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.name = try? unboxer.unbox(key: "name")
        self.code = try? unboxer.unbox(key: "code")
        self.description = try? unboxer.unbox(key: "description")
        self.offerType = try? unboxer.unbox(key: "offerType")
        self.minOrderValue = try? unboxer.unbox(key: "minOrderValue")
        self.percentageValue = try? unboxer.unbox(key: "value")
        self.discountAmount = try? unboxer.unbox(key: "discountAmount")
    }
}
