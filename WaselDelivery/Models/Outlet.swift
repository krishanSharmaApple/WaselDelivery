//
//  Outlet.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 14/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

class Outlet: Unboxable {
    
    let id: Int?
    let name: String?
    var imageUrl: String?
    let amenity: Amenity?
    let rating: Double?
    let budget: Budget?
    var distance: String?
    var deliveryCharge: Double?
    var minimumOrderValue: Double?
    let description: String?
    let canAccessImages: Bool?
    let canAccessItems: Bool?
    let address: Address?
    var timing: String?
    var outletItems: [OutletItem]?
    var firstShiftStartTime: Date?
    var firstShiftEndTime: Date?
    var secondShiftStartTime: Date?
    var secondShiftEndTime: Date?
    var isPartnerOutLet: Bool?
    var closingTimeInMins: Int? = 0
    var apiHitTime: Date?
    var openStatus: Int?
    var opentime: String?
    let location: String?
    var isFleetOutLet: Bool?
    let ownFleetDescription: String?
    var showVendorMenu: Bool?
    var outletTimings: [OutletTimings]?

    var handleFee: Double = 0
    var handleFeeType: String?

    var isCardPaymentEnabled: Bool?
    var isCashPaymentEnabled: Bool?
    var isPayTabsPaymentEnabled: Bool?
    var isCashOrCardPaymentEnabled: Bool?
    var isCreditCardPaymentEnabled: Bool?
    var isMasterCardPaymentEnabled: Bool?
    var isBenfitPaymentEnabled: Bool?

    let cashOrCardDescription: String?
    let creditCardPaymentDescription: String?
    let benfitPayDescription: String?
    let preBookingTime: Int?
    
    required init(unboxer: Unboxer) throws {
        
        self.id = try? unboxer.unbox(key: "id")
        self.name = try? unboxer.unbox(key: "name")
        self.imageUrl = try? unboxer.unbox(key: "imageUrl")
        if self.imageUrl != nil {
            self.imageUrl = imageBaseUrl+(self.imageUrl ?? "")
        }
        self.rating = try? unboxer.unbox(key: "rating")
        self.budget = try? unboxer.unbox(key: "budget")
        self.distance = try? unboxer.unbox(key: "distance")
        let delCharge: String? = try? unboxer.unbox(key: "deliveryCharge")
        if let delCharge_ = delCharge {
            self.deliveryCharge = Double(delCharge_)
        } else {
            self.deliveryCharge = nil
        }

        self.handleFeeType = try? unboxer.unbox(key: "handleFeeType")
        self.handleFee = (try? unboxer.unbox(key: "handleFee")) ?? 0
        
        let minCharge: String? = try? unboxer.unbox(key: "minimumOrderValue")
        if let minCharge_ = minCharge {
            self.minimumOrderValue = Double(minCharge_)
        } else {
            self.minimumOrderValue = nil
        }
        
        self.description = try? unboxer.unbox(key: "description")
        self.canAccessImages = try? unboxer.unbox(key: "canAcessImages")
        self.canAccessItems = try? unboxer.unbox(key: "canAcessItems")
        self.address = try? unboxer.unbox(key: "address")
        self.amenity = try? unboxer.unbox(key: "amenity")
        self.isPartnerOutLet = try? unboxer.unbox(key: "partner")
        self.showVendorMenu = try? unboxer.unbox(key: "showVendorMenu")
        self.isFleetOutLet = try? unboxer.unbox(key: "ownFleet")
        self.ownFleetDescription = try? unboxer.unbox(key: "ownFleetDescription")
        self.closingTimeInMins = try? unboxer.unbox(key: "closeInMin")
        self.openStatus = try? unboxer.unbox(key: "status")
        self.opentime = try? unboxer.unbox(key: "opentime")
        self.location = try? unboxer.unbox(key: "location")
        self.preBookingTime = try? unboxer.unbox(key: "preBooking")

        self.isCashOrCardPaymentEnabled = try? unboxer.unbox(key: "enabledCashOrCard")
        self.isPayTabsPaymentEnabled = try? unboxer.unbox(key: "enabledPayTabs")
        self.isCreditCardPaymentEnabled = try? unboxer.unbox(key: "enabledCreditCardPayment")
         self.isMasterCardPaymentEnabled = true //unboxer.unbox(key: "enabledMasterCardPayment")
        self.isBenfitPaymentEnabled = try? unboxer.unbox(key: "enabledBenfitPay")
        self.cashOrCardDescription = try? unboxer.unbox(key: "cashOrCardDescription")
        self.creditCardPaymentDescription = try? unboxer.unbox(key: "creditCardPaymentDescription")
        self.benfitPayDescription = try? unboxer.unbox(key: "benfitPayDescription")

        self.apiHitTime = Date()

        let timeString: String? = try? unboxer.unbox(key: "opentime")
        if let timeString_ = timeString {
            getTimings(timeString: timeString_)
        }
        let items: [[String: AnyObject]]? = try? unboxer.unbox(key: "outletItems")
        if let items_ = items {
            getOutletItems(items: items_)
        }
        let outletTimings: [[String: AnyObject]]? = try? unboxer.unbox(key: "timings")
        if let outletTimings_ = outletTimings {
            getOutletTimings(timings: outletTimings_)
        }
    }
    
    func getTimings(timeString: String) {
        let timeShifts = timeString.split {$0 == "&"}.map(String.init)
        if timeString.contains("-") {
            let dateFormatString = "yyyy-MM-dd HH:mm:ss"
            for (index, shift) in timeShifts.enumerated() {
                let shiftTimings = shift.split {$0 == "-"}.map(String.init)
                let startTime = Utilities.getUTCDateFromUTCTime(utcDateString: shiftTimings[0], dateformatString: dateFormatString)
                let endTime = Utilities.getUTCDateFromUTCTime(utcDateString: shiftTimings[1], dateformatString: dateFormatString)
                if index == 0 {
                    self.firstShiftStartTime = startTime
                    self.firstShiftEndTime = endTime
                } else {
                    self.secondShiftStartTime = startTime
                    self.secondShiftEndTime = endTime
                }
            }
        } else {
            self.timing = timeString
        }
    }
    
    func getOutletItems(items: [[String: AnyObject]]) {
        
        do {
            var outletItemsArray = [OutletItem]()
            for outletItem in items {
                let outletItem_: OutletItem = try unbox(dictionary: outletItem)
                outletItemsArray.append(outletItem_)
            }
            self.outletItems = outletItemsArray
        } catch {

        }
    }
    
    func getOutletTimings(timings: [[String: AnyObject]]) {
        do {
            var outletTimingsArray = [OutletTimings]()
            for outletTiming in timings {
                let outletTimings_: OutletTimings = try unbox(dictionary: outletTiming)
                outletTimingsArray.append(outletTimings_)
            }
            self.outletTimings = outletTimingsArray
        } catch {
            
        }
    }

    func updateOutLetClosingTime() -> Int {
        if let apiHitTime_ = self.apiHitTime {
            let interval = Date().timeIntervalSince(apiHitTime_)
            if let outLetClosingTimeInMins = self.closingTimeInMins {
                if Int(interval/60) > (outLetClosingTimeInMins) {
                    return -1
                } else if Int(interval/60) < outLetClosingTimeInMins {
                    let timeDuration = outLetClosingTimeInMins - Int(interval/60)
                    return timeDuration
                } else if 60 == outLetClosingTimeInMins && Int(interval/60) == outLetClosingTimeInMins {
                    return outLetClosingTimeInMins
                }
                return -1
            }
        }
        return -1
    }
    
    func loadOutletDetails(_ aOutlet: Outlet, isOutletSelected: Bool, isDuplicatedOutlet: Bool) -> (address_: String, location_: String, hideAddressLabel: Bool, distanceAndCost_: NSAttributedString) {
        var address_ = ""
        // Display the full address if outlet names are same.
        if let locationName = aOutlet.location {
            address_ = locationName.trim()
        } else {
            address_ = aOutlet.name ?? ""
        }
        let hideAddressLabel = !isDuplicatedOutlet
        if false == isDuplicatedOutlet {
            address_ = ""
        }
        
        // Checking for outlet location from name(Split with "--" if it's exists display the location else display the full address)
        var location_ = ""
        if let outletName = aOutlet.name {
            let nameAndLocationStringArray = outletName.components(separatedBy: "--")
            if 1 < nameAndLocationStringArray.count {
                location_ = nameAndLocationStringArray.last?.trim() ?? ""
            } else {
                if let locationName = aOutlet.location {
                    location_ = locationName.trim()
                } else {
                    location_ = aOutlet.name ?? ""
                }
            }
        } else {
            if let locationName = aOutlet.location {
                location_ = locationName.trim()
            } else {
                location_ = aOutlet.name ?? ""
            }
        }
        
        let durationText = Utilities.getDistanceAttString(outlet: aOutlet)
        let costText = Utilities.getDeliveryChargeAttString(outlet: aOutlet)
        let attrString = NSMutableAttributedString()
        attrString.append(durationText)
        attrString.append(NSAttributedString(string: " - "))
        if true == aOutlet.isFleetOutLet {
            attrString.append(NSAttributedString(string: aOutlet.ownFleetDescription ?? ""))
        } else {
            attrString.append(costText)
        }
        let distanceAndCost_ = attrString
        return(address_, location_, hideAddressLabel, distanceAndCost_)
    }
}
