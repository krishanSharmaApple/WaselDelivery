//
//  PaymentCardInfo.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/12/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct PaymentCardInfo: Unboxable {

    var isCardSaved: Bool? = false
    var number: Int?
    var name: String?
    var expirationDate: String?
    var cvv: Int?

    init() {
        isCardSaved = false
    }

    init(unboxer: Unboxer) throws {
        self.number = try? unboxer.unbox(key: "number")
        self.name = try? unboxer.unbox(key: "name")
        self.cvv = try? unboxer.unbox(key: "cvv")
        self.expirationDate = try? unboxer.unbox(key: "expirationDate")
        self.isCardSaved = try? unboxer.unbox(key: "isCardSaved")
    }

}
