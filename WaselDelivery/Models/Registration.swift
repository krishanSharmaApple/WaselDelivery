//
//  Registration.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 08/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation

class Registration {
    var name: String?
    var password: String?
    var retypePassword: String?
    var mobile: String?
    var countryCode: CountryCode?
    var email: String?
    var id: String?
    var imageUrl: String?
    var accountType: AccountType = .wasel
    var shouldSync = false
}
