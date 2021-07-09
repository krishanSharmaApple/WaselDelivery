//
//  PaymentsMode.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/12/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct PaymentsMode: Unboxable {

    var paymentModeEnumDictionary: [PaymentMode] = [.creditCard, .benfit, .cashOrCard]
    var selectedMode = PaymentMode.cashOrCard

    init() {
        paymentModeEnumDictionary = [.benfit, .creditCard]
        selectedMode = paymentModeEnumDictionary.first ?? .cashOrCard
    }

    init(unboxer: Unboxer) throws {
        paymentModeEnumDictionary = [.benfit, .creditCard]
        selectedMode = paymentModeEnumDictionary.first ?? .cashOrCard
    }

}
