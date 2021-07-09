//
//  Order.swift
//  WaselDelivery
//
//  Created by sunanda on 11/29/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox

struct Order: Unboxable {
    
    let id: Int?
    let cartId: Int?
    let number: String?
    var status: OrderStatus?
    var vehicleType: VehicleType?
    let charge: Double?
    let deliveryCharge: Double?
    let grandTotal: Double?
    let discountAmount: Double?
    let instructions: String?
    let coupon: Coupon?
    var createdDate: Date?
    var orderCreatedDateTime: Date?
    let outlet: Outlet?
    let removedItems: [OrderItem]?
    let orderType: OrderType?
    let pickUpLocation: String?
    let shippingAddress: Address?
    var deliveryTracingLink: String?
    var pickupTrackingLink: String?
    var latitude: Double?
    var longitude: Double?
    let items: [OrderItem]?
    var isFromVendor: Bool?
    var isFleetOutLet: Bool?
    var cancelReason: String?
    var paymentType: String?
    var scheduledDate: Date?
    let tipAmount: Double?

    var handleFee: Double = 0
    var handleFeeType: String?
    var handlingFeePercent: Double = 0

    let txnResponseMessage: String?
    let responseCode: String?

    init(unboxer: Unboxer) throws {
        
        self.id = try? unboxer.unbox(key: "id")
        self.cartId = try? unboxer.unbox(key: "cartId")
        self.number = try? unboxer.unbox(key: "orderNumber")
        self.status = try? unboxer.unbox(key: "status")
        self.vehicleType = try? unboxer.unbox(key: "vehicleType")
        self.charge = try? unboxer.unbox(key: "orderCharge")
        self.deliveryCharge = try? unboxer.unbox(key: "deliveryCharge")
        self.grandTotal = try? unboxer.unbox(key: "grandTotal")
        self.discountAmount = try? unboxer.unbox(key: "discountAmount")
        self.instructions = try? unboxer.unbox(key: "orderInstruction")
        self.coupon = try? unboxer.unbox(key: "coupon")
        self.outlet = try? unboxer.unbox(key: "outlet")
        self.items = try? unboxer.unbox(key: "items")
        self.removedItems = try? unboxer.unbox(key: "removedItems")
        self.orderType = try? unboxer.unbox(key: "orderType")
        self.pickUpLocation = try? unboxer.unbox(key: "pickUpLocation")
        self.shippingAddress = try? unboxer.unbox(key: "shippingAddress")
        self.deliveryTracingLink = try? unboxer.unbox(key: "deliveryTracingLink")
        self.pickupTrackingLink = try? unboxer.unbox(key: "pickupTrackingLink")
        self.latitude = try? unboxer.unbox(key: "latitude")
        self.longitude = try? unboxer.unbox(key: "longitude")
        self.isFromVendor = try? unboxer.unbox(key: "vendor")
        self.isFleetOutLet = try? unboxer.unbox(key: "ownFleet")
        self.cancelReason = try? unboxer.unbox(key: "reason")
        self.paymentType = try? unboxer.unbox(key: "paymentTypeName")
        self.tipAmount = try? unboxer.unbox(key: "tipAmount")

        self.handleFeeType = try? unboxer.unbox(key: "handlingFeeType")
        self.handleFee = (try? unboxer.unbox(key: "handlingFee")) ?? 0
        self.handlingFeePercent = (try? unboxer.unbox(key: "handlingFeePercent")) ?? 0

        self.txnResponseMessage = try? unboxer.unbox(key: "txnResponseMessage")
        self.responseCode = try? unboxer.unbox(key: "responseCode")
        
        let scheduledDateObj: u_long? = try? unboxer.unbox(key: "scheduledDate")
        if let dateObj_ = scheduledDateObj {
            self.scheduledDate = Date(timeIntervalSince1970: TimeInterval(dateObj_ / 1000))
        }

        if .special == self.orderType && nil != self.id {
            self.isFromVendor = true
        } else {
            self.isFromVendor = false
        }
        
        let dateOrderObj: [String: AnyObject]? = try? unboxer.unbox(key: "orderCreatedDateTime")
        if let dateOrderObj_ = dateOrderObj {
            getOrderDate(dateObj: dateOrderObj_)
        }
        let dateObj: u_long? = try? unboxer.unbox(key: "createdDateTime")
        if let dateObj_ = dateObj {
            getDate(dateObj: dateObj_)
        }
    }

    private mutating func getDate(dateObj: u_long) {
        self.createdDate = Date(timeIntervalSince1970: TimeInterval(dateObj))
    }
    
    private mutating func getOrderDate(dateObj: [String: AnyObject]) {
        let date = dateObj["dayOfMonth"] as? Int ?? 0
        let month = dateObj["monthValue"] as? Int ?? 0
        let year = dateObj["year"] as? Int ?? 0
        let hour = dateObj["hour"] as? Int ?? 0
        let minute = dateObj["minute"] as? Int ?? 0
        let second = dateObj["second"] as? Int ?? 0
        let dateString = "\(year)-\(month)-\(date) \(hour):\(minute):\(second)"
        
        let utcDate = Utilities.getUtcDate(utcDateString: dateString, dateformatString: "yyyy-MM-dd HH:mm:ss")
        self.orderCreatedDateTime = utcDate
        
    }

    func isOrderProcessing() -> Bool {
        
        if let status_ = status {
            if status_ == .completed || status_ == .cancelled || status_ == .failed {
                return false
            }
            return true
        }
        return true
    }

}
