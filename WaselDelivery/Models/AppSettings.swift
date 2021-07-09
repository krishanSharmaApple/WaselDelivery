//
//  AppSettings.swift
//  WaselDelivery
//
//  Created by Purpletalk on 7/17/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import Foundation

struct AppSettings: Unboxable {
    
    let timeInMinutes: Int?
    let message: String?
    let openStatus: Bool?
    let isPayTabsPaymentEnabled: Bool?
    
    var isCashOrCardPaymentEnabled: Bool?
    var isCreditCardPaymentEnabled: Bool?
    var isMasterCardPaymentEnabled: Bool?
    var isBenfitPaymentEnabled: Bool?
    var appTimings: [OutletTimings]?

    let cashOrCardDescription: String?
    let creditCardPaymentDescription: String?
    let benfitPayDescription: String?
    let preBookingTime: Int?

    var handleFee: Double = 0
    var handleFeeType: String?

    init(unboxer: Unboxer) throws {
        self.timeInMinutes = try? unboxer.unbox(key: "time")
        self.openStatus = try? unboxer.unbox(key: "open")
        self.message = try? unboxer.unbox(key: "message")

        self.handleFee = (try? unboxer.unbox(key: "handleFee")) ?? 0
        self.handleFeeType = try? unboxer.unbox(key: "handleFeeType")
        
        self.isCashOrCardPaymentEnabled = try? unboxer.unbox(key: "enabledCashOrCard")
        self.isPayTabsPaymentEnabled = try? unboxer.unbox(key: "enabledPayTabs")
        self.isCreditCardPaymentEnabled = try? unboxer.unbox(key: "enabledCreditCardPayment")
        self.isMasterCardPaymentEnabled =  true //unboxer.unbox(key: "enabledMasterCardPayment")
        self.isBenfitPaymentEnabled = try? unboxer.unbox(key: "enabledBenfitPay")
        self.cashOrCardDescription = try? unboxer.unbox(key: "cashOrCardDescription")
        self.creditCardPaymentDescription = try? unboxer.unbox(key: "creditCardPaymentDescription")
        self.benfitPayDescription = try? unboxer.unbox(key: "benfitPayDescription")
        self.preBookingTime = try? unboxer.unbox(key: "preBooking")
        let appTimingsTimings: [[String: AnyObject]]? = try? unboxer.unbox(key: "timings")
        if let appTimingsTimings_ = appTimingsTimings {
            getAppTimings(timings: appTimingsTimings_)
        }
    }
    
    init() {
        self.timeInMinutes = 0
        self.openStatus = false
        self.message = ""
        
        self.isCashOrCardPaymentEnabled = false
        self.isPayTabsPaymentEnabled = false
        self.isCreditCardPaymentEnabled = false
        self.isBenfitPaymentEnabled = false
        self.cashOrCardDescription = ""
        self.creditCardPaymentDescription = ""
        self.benfitPayDescription = ""
        self.preBookingTime = 0
    }
    
    mutating func getAppTimings(timings: [[String: AnyObject]]) {
        do {
            var appTimingsArray = [OutletTimings]()
            for outletTiming in timings {
                let outletTimings_: OutletTimings = try unbox(dictionary: outletTiming)
                appTimingsArray.append(outletTimings_)
            }
            self.appTimings = appTimingsArray
        } catch {
            
        }
    }
}
