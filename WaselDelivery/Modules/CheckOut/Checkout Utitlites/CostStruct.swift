//
//  CostStruct.swift
//  WaselDelivery
//
//  Created by ramchandra on 10/12/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import Foundation

struct CostStruct {

    var orderCost: Double = 0.0
    var deliveryCharge: Double = 0.0
    var discount: Double = 0.0
    var tip: Double = 0.0
    var handlingFee: Double = 0
    var handlingFeeType: String = "PERCENTAGE" // PERCENTAGE & AMOUNT
    var isPartner: Bool = false

    var isFleetType = false
    var grandTotal: Double {
        return orderCost + tip + handlingFee(outlet: Utilities.shared.currentOutlet) - discount + (isFleetType == true ? 0.0 : deliveryCharge)
    }

    let orderChargeCellIndex = 0
    let deliveryChargeCellIndex = 1

    func getGrandTotalIndex() -> Int {
        var rowIndex = 2 // Order charge, Delivery charge, grand total
        if shouldDisplayHandlingFee() {
            rowIndex += 1 // Handle Fee
        }
        if 0 < discount {
            rowIndex += 1
        }
        if 0 < tip {
            rowIndex += 1
        }
        return rowIndex
    }

    func shouldDisplayHandlingFee() -> Bool {
        let outlet = Utilities.shared.currentOutlet
        if (outlet?.handleFee ?? 0) > 0 {
            return true
        } else if !(outlet?.isPartnerOutLet ?? false) {
            return (Utilities.shared.appSettings?.handleFee ?? 0) > 0
        }
        return false
    }

    func percentValueOfHandlingFee(outlet: Outlet?) -> Float {
        var percentValue: Float = 0

//        let outlet = Utilities.shared.currentOutlet
        if (outlet?.handleFee ?? 0) > 0 {
            percentValue = Float(outlet?.handleFee ?? 0)
        } else if !(outlet?.isPartnerOutLet ?? false) {
            percentValue = Float(Utilities.shared.appSettings?.handleFee ?? 0)
        }

        return percentValue
    }

    func handlingFee(outlet: Outlet? = nil) -> Double {
        var handleFee = outlet?.handleFee ?? self.handlingFee
        if (outlet?.handleFeeType ?? self.handlingFeeType) == "PERCENTAGE" {
            handleFee = (orderCost - discount) * handleFee / 100
        }
        if !(outlet?.isPartnerOutLet ?? isPartner) && handleFee == 0, let appSettings = Utilities.shared.appSettings {
            handleFee = appSettings.handleFee
            if appSettings.handleFeeType == "PERCENTAGE" {
                handleFee = (orderCost - discount) * handleFee / 100
            }
        }
        return handleFee
    }

    func getCostDetailsDataForCell(index: Int, outlet: Outlet? = nil) -> (titleString: String, priceString: String, hideDiscountLabel: Bool, showBDImage: Bool) {
        var titleString_ = ""
        var priceString_ = ""
        var hideDiscountLabel_ = true
        var showBDImage_ = true

        if orderChargeCellIndex == index {
            titleString_ = "Order Charge"
            priceString_ = String(format: "%.3f", Utilities.shared.getTotalCost())
        } else if deliveryChargeCellIndex == index {
            titleString_ = "Delivery Charge"
            priceString_ = (0 <= deliveryCharge) ? "\(String(format: "%.3f", deliveryCharge))" : "NA"

            if 0 > deliveryCharge {
                showBDImage_ = false
            }
            if let outlet_ = outlet, true == outlet_.isFleetOutLet {
                priceString_ = "NA"
                showBDImage_ = false
            }
        } else {
            let isDiscountAvailable = (0 < discount)
            let isTipAvailable = (0 < tip)

            if index == 2 && isDiscountAvailable { // Discount Details

                // return Discount Details
                hideDiscountLabel_ = false
                titleString_ = "Discount"
                priceString_ = String(format: "%.3f", discount)
                return (titleString_, priceString_, hideDiscountLabel_, showBDImage_)
            } else if (!isDiscountAvailable && isTipAvailable && index == 2) ||
                (isDiscountAvailable && isTipAvailable && index == 3) { // Tip Details

                // return Tip Details
                titleString_ = "Tip"
                priceString_ = String(format: "%.3f", tip)
                return (titleString_, priceString_, hideDiscountLabel_, showBDImage_)
            } else if shouldDisplayHandlingFee() &&
                ((index == 2 && !isDiscountAvailable && !isTipAvailable) ||
                (index == 3 && isDiscountAvailable && !isTipAvailable) ||
                (index == 3 && !isDiscountAvailable && isTipAvailable) ||
                (index == 4 && isDiscountAvailable && isTipAvailable)) { // Handling Fee Details

                // return Handling Fee Details
                titleString_ = "Handling Fee"
                let handleFee = Float(handlingFee(outlet: outlet))
                if handleFee > 0 {
                    priceString_ = String(format: "%.3f", handleFee)
                } else {
                    priceString_ = String(format: "%.2f%% of Order Charge", percentValueOfHandlingFee(outlet: Utilities.shared.currentOutlet))
                    showBDImage_ = false
                }
                return (titleString_, priceString_, hideDiscountLabel_, showBDImage_)
            }

            // return grand total Details
            titleString_ = "Grand Total"
            let totalPrice = orderCost + tip + deliveryCharge + handlingFee(outlet: outlet) - discount
            priceString_ = "\(String(format: "%.3f", max(0, totalPrice)))"

            if let outlet_ = outlet, true == outlet_.isFleetOutLet {
                let price = orderCost + tip + handlingFee(outlet: outlet_) - discount
                priceString_ = "\(String(format: "%.3f", max(0, price)))"
            }
        }

        return (titleString_, priceString_, hideDiscountLabel_, showBDImage_)
    }

}
