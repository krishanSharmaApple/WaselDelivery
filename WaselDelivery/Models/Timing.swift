//
//  Timing.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 06/10/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct Timing: Unboxable {
    
    let id: String?
    let weekDay: String?
    let firstShiftstartTime: Int?
    let firstShiftHrs: Int?
    let secondShiftstartTime: Int?
    let secondShiftHrs: Int?
    
    init(unboxer: Unboxer) throws {
        
        self.id = try? unboxer.unbox(key: "id")
        self.weekDay = try? unboxer.unbox(key: "daysOfWeek")
        self.firstShiftstartTime = try? unboxer.unbox(key: "firstShiftstartTime")
        self.firstShiftHrs = try? unboxer.unbox(key: "firstShiftHrs")
        self.secondShiftstartTime = try? unboxer.unbox(key: "secondShiftstartTime")
        self.secondShiftHrs = try? unboxer.unbox(key: "secondShiftHrs")
    }
}
