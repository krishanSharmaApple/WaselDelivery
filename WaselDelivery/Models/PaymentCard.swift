//
//  PaymentCard.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/03/08.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

struct PaymentCard: Unboxable {
    
    var cardBrand: String?
    var createdDate: String?
    var customerEmail: String?
    var customerPassword: String?
    var isDefaultCard: Bool?
    var first4Digits: String?
    var last4Digits: String?
    var token: String?
    let id: Int?

    init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.cardBrand = try? unboxer.unbox(key: "cardBrand")
        self.createdDate = try? unboxer.unbox(key: "createdDate")
        self.customerEmail = try? unboxer.unbox(key: "customerEmail")
        self.customerPassword = try? unboxer.unbox(key: "customerPassword")
        self.first4Digits = try? unboxer.unbox(key: "first4Digits")
        self.last4Digits = try? unboxer.unbox(key: "last4Digits")
        self.token = try? unboxer.unbox(key: "token")
        self.isDefaultCard = try? unboxer.unbox(key: "default")

        if let tokenString = token, false == tokenString.isEmpty {
            let key = publicKey
            let iv = publicKey
            let deCodedString = try? tokenString.aesDecrypt(key: key, iv: iv)
            debugPrint(deCodedString ?? "")
            if nil == deCodedString || true == deCodedString?.isEmpty {
                self.token = tokenString
            } else {
                self.token = deCodedString
            }
        }
        
        if let customerPassword_ = customerPassword, false == customerPassword_.isEmpty {
            let key = publicKey
            let iv = publicKey
            let deCodedPasswordString = try? customerPassword_.aesDecrypt(key: key, iv: iv)
            debugPrint(deCodedPasswordString ?? "")
            if nil == deCodedPasswordString || true == deCodedPasswordString?.isEmpty {
                self.customerPassword = customerPassword_
            } else {
                self.customerPassword = deCodedPasswordString
            }
        }
    }
}
