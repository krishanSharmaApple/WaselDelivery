//
//  DeliveryCharge.swift
//  WaselDelivery
//
//  Created by Vali on 27/03/2020.
//

import UIKit
import Unbox

struct DeliveryCharge: Unboxable {

    let bikeDeliveryCharge: Double?
    let carDeliveryCharge: Double?
    let truckDeliveryCharge: Double?
    
    init(unboxer: Unboxer) throws {
        self.bikeDeliveryCharge = try? unboxer.unbox(key: "bikeDeliveryCharge")
        self.carDeliveryCharge = try? unboxer.unbox(key: "carDeliveryCharge")
        self.truckDeliveryCharge = try? unboxer.unbox(key: "truckDeliveryCharge")
    }
}
