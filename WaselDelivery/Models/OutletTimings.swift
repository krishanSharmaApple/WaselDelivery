//
//  OutletTimings.swift
//  WaselDelivery
//
//  Created by Purpletalk on 02/04/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

class OutletTimings: Unboxable {

    let id: Int?
    var daysOfWeek: String?
    var firstShiftStartDateAndTime: String?
    var firstShiftDateAndEndTime: String?
    var secondShiftDateAndStartTime: String?
    var secondShiftDateAndEndTime: String?

    let enableSecondShift: Bool?
    let is24hrs: Bool?
    let available: Bool?
    let dateFormatString = "HH:mm:ss"

    required init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.daysOfWeek = try? unboxer.unbox(key: "daysOfWeek")
        self.firstShiftStartDateAndTime = try? unboxer.unbox(key: "firstShiftStartTime")
        self.firstShiftDateAndEndTime = try? unboxer.unbox(key: "firstShiftEndTime")
        self.secondShiftDateAndStartTime = try? unboxer.unbox(key: "secondShiftStartTime")
        self.secondShiftDateAndEndTime = try? unboxer.unbox(key: "secondShiftEndTime")
        self.enableSecondShift = try? unboxer.unbox(key: "enableSecondShift")
        self.is24hrs = try? unboxer.unbox(key: "is24hrs")
        self.available = try? unboxer.unbox(key: "available")
    }

}
