//
//  User.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 04/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

enum AccountType: Int, UnboxableEnum {
    case wasel = 1
    case facebook = 2
    case google = 3
    case apple = 4
    
    func getAccountTypeString() -> String {
        var accountTypeString = "SignUp"
        switch self.rawValue {
        case 2:
            accountTypeString = "Facebook"
        case 3:
            accountTypeString = "GooglePlus"
        case 4:
            accountTypeString = "Apple"
        default:
            accountTypeString = "SignUp"
        }
        return accountTypeString
    }
}

struct User: Unboxable {
    
    var name: String?
    var email: String?
    var imageUrl: String?
    let id: String?
    let mobile: String?
    var accountType: AccountType?
    var addresses: [Address]?
    var token: String?
    
    init(unboxer: Unboxer) throws {
        self.name = try? unboxer.unbox(key: "name")
        self.email = try? unboxer.unbox(key: "email")
        self.id = try? unboxer.unbox(key: "id")
        self.mobile = try? unboxer.unbox(key: "mobile")
        self.accountType = try? unboxer.unbox(key: "accountType")
        self.imageUrl = try? unboxer.unbox(key: "imageUrl")
        self.addresses = try? unboxer.unbox(key: "address")
        self.token = try? unboxer.unbox(key: "token")
    }
    
    init() {
        self.name = ""
        self.email = ""
        self.id = ""
        self.mobile = ""
        self.accountType = AccountType.wasel
        self.imageUrl = ""
        self.token = ""
    }
}
