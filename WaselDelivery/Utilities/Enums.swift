//
//  Enums.swift
//  WaselDelivery
//
//  Created by sunanda on 9/29/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

enum Budget: Int, UnboxableEnum {
    case none
    case low
    case medium
    case high
    
    static func unboxFallbackValue() -> Budget {
        return .low
    }
}

enum OrderType: String, UnboxableEnum {
    case normal = "NORMAL"
    case special = "SPECIAL"
}

enum APIServiceType {
    case apiService
    case staticService
}

enum ResponseError: Error {
    case notFoundError
    case badRequestError
    case timeoutError
    case internalServerError
    case parseError
    case unboxParseError
    case unkonownError
    case accessTokenExpireError
    case invalidResponseError
    case errorWithMessage(String)
    
    func description() -> String {
        switch self {
        case .notFoundError:
            return "URL not found!!!".localized
        case .badRequestError:
            return "Bahrain.API.BadRequest".localized
        case .timeoutError:
            return "Bahrain.API.RequestTimeout".localized
        case .internalServerError:
            return "Bahrain.API.InternalServerError".localized
        case .parseError:
            return "Bahrain.API.ParseError".localized
        case .unboxParseError:
            return "Bahrain.API.UnboxParseError".localized
        case .accessTokenExpireError:  
            return "Bahrain.API.AccessTokenExpireError".localized
        case .invalidResponseError:
            return "Bahrain.API.InvalidResponseError".localized
        case let .errorWithMessage(str):
            return str
        default:
            return "Bahrain.API.UnknownError".localized
        }
    }
    
    func getStatusCodeFromError() -> ResponseStatusCode {
        
        switch self {
        case .notFoundError:
            return ResponseStatusCode.notFound
        case .timeoutError:
            return ResponseStatusCode.timeout
        case .accessTokenExpireError:
            return ResponseStatusCode.accessTokenExpire
        case .badRequestError:
            return ResponseStatusCode.badRequest
        default:
            return ResponseStatusCode.internalServer
        }
    }
    
}

enum ResponseStatusCode: Int {
    case success = 200
    case orderFail = 303
    case accessTokenExpire = 401
    case notFound = 404
    case badRequest = 400
    case timeout = 408
    case internalServer = 500
    case requestTimeout = 1001
}

enum URI: String {
    
    case register = "v1/public/users/create/new/user"
    case login = "v1/public/user/login"
    case generateOtp = "v1/public/user/generate/otp"
    case amenityList = "v2/public/amenities/list"
    case verifyOtp = "v1/public/user/verifyotp"
    case savePassword = "v1/public/user/password/save"
    case checkUserExistance = "v1/public/users/checkUserExist"
    case validateUser = "v1/public/user/validate"
    case syncUser = "v1/public/user/sink"
    case outletsList = "v1/public/outlets/sortedList"
    case outletItems = "v1/public/outlets/get/"
    case coupons = "v1/public/order/coupons"
    case orderDispose = "/v2/security/order/disposal"
    case updateProfile = "v1/security/users/update"
    case getProfile = "v1/security/users/get"
    case getOrderHistory = "v1/security/order/get/histories/"
    case getOrderDetails = "v1/security/order/get/"
    case deliveryChargesByVehicleType = "v2/security/deliveryChargesByVehicleType"
    case searchResults = "v1/public/outlets/sortedSearch/"
    case profileImage = "v1/security/users/add/profile/image"
    case giveFeedback = "v1/security/order/feedback"
    case logout = "v1/security/users/logout"
    case getFeedbackOrders = "v1/security/order/get/completed/order/"
    case verifyCoupon = "v1/security/order/verify/coupon/"
    case version = "v1/public/app/detail"
    case deviceTokenUpdate = "v1/security/user/allow/notification"
    case deviceTokenUpdateWithOutLogin = "v1/public/mobile/devicetoken"
    case deliverycharge = "/v2/security/deliverycharge/"
    case support = "v1/public/app/help"
    case appSettings = "v1/public/appSettings"
    case appVersion = "v2/public/app/version/"
    case accessToken = "v1/public/accesstoken"
    case cancelOrder = "v1/security/order/cancel"
    case cancelOrderReasons = "v1/security/order/cancel/reasons"
    case productImage = "v1/public/upload"
    case savedCardsList = "v1/security/userpaymentcard/list/"
    case updateSavedCard = "v1/security/userpaymentcard/update/"
    case deleteSavedCard = "v1/security/userpaymentcard/delete/"
    case saveCard = "v1/security/userpaymentcard/save_by_session"
    case paymentUpdate = "v1/security/order/payment/update"
    case paymentUpdate2 = "v2/security/order/payment/update"
}

enum URIString {
    case verifyOtp(String)
}

enum NetworkMethod: String {
    
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    
}

enum StoryBoard: String {
    case main = "Main"
    case login = "Login"
    case checkOut = "CheckOut"
    case home = "Home"
    case orderHistory = "OrderHistory"
    case profile = "Profile"
    
    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }
    
    func viewController<T: UIViewController>(viewControllerClass: T.Type) -> T {
        return self.instance.instantiateViewController(withIdentifier: viewControllerClass.storyboardID) as? T ?? T()
    }
    
}

enum PaymentMode: String {
    case creditCard = "CREDIT_CARD"
    case benfit = "BENEFIT_PAY"
    case cashOrCard = "CASH"
    case masterCard = "MASTER_CARD"
}

enum CategoryMode: String {
    case count = "MULTIPLE"
    case check = "QTY"
    case anyOne = "ANY_ONE"
}

enum SaveAddressCellType: Int {
    case address
    case flatNumber
    case landMark
    case addressType
}

enum OrderStatus: String, UnboxableEnum {
    case pending = "PENDING"
    case confirm = "CONFIRM"
    case onTheWay = "ON_THE_WAY"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case accepted = "REQUEST_RECEIVED"
    case cancelled = "CANCELLED"

    static func hashValueFrom(status: OrderStatus) -> Int {
        
        switch status {
        case .pending:
            return 0
        case .confirm,
             .accepted:
            return 1
        case .onTheWay:
            return 2
        case .completed:
            return 3
        case .failed:
            return 4
        case .cancelled:
            return 6
        }
    }
    
    static func hashValueForFleetType(status: OrderStatus) -> Int {
        
        switch status {
        case .pending:
            return 2
        case .confirm, .completed:
            return 3
        case .failed:
            return 4
        case .cancelled:
            return 5
        default:
            return -1
        }
    }
    
    static func fromStringValue(hashValue: String) -> OrderStatus {
        switch hashValue {
        case "PENDING":
            return .pending
        case "CONFIRM":
            return .confirm
        case "ON_THE_WAY":
            return .onTheWay
        case "FAILED":
            return .failed
        case "COMPLETED":
            return .completed
        case "CANCELLED":
            return .cancelled
        default:
            return .accepted
        }
    }

}

enum AddressType: String, UnboxableEnum {
    case home = "HOME"
    case office = "OFFICE"
    case others = "OTHER"
    
    static func fromHashValue(hashValue: Int) -> AddressType {
        switch hashValue {
        case 0:
            return .home
        case 1:
            return .office
        case 2:
            return .others
        default:
            return .home
        }
    }
}

enum ChargeType: Int {
    
    case delivery
    case discount
    case grandTotal
    case tip
    case subTotal
    case handlingFee
}

enum OutletItemCustomFieldType: String {
    case cuisineType = "Veg"
    case spicy = "Spicy"
}

enum AddressEditMode: Int {
    
    case edit = 1
    case done = 2
}

enum SocialType: Int {
    
    case none = 0
    case facebook = 1
    case twitter = 2
    case instagram = 3
}

enum LoggingType {
    
    case trace
    case debug
    case info
    case warning
    case error
}

enum VehicleType: String, UnboxableEnum {
    case motorbike = "BIKE"
    case car = "CAR"
    case truck = "TRUCK"
}

enum ToastPositon {
    case top
    case middle
    case bottom
    var bottomOffset: CGFloat {
        switch self {
        case .top:
            return 30
        case .middle:
            return (UIScreen.main.bounds.size.height / 2)
        default:
            return 30
        }
    }
}

enum CartMessage {
    case allItemRemoved
    case fewItemRemoved
    case itemRemoved(String)
    case singleItemCustomizationRemoved(String)
    
    func description() -> String {
        switch self {
        case .allItemRemoved:
            return "All the items in this order are not available right now.".localized
        case .fewItemRemoved:
            return "Some of the items in your order are not available right now.".localized
        case let .itemRemoved(str):
            return "Currently \"\(str)\" is not available."
        case let .singleItemCustomizationRemoved(str):
            return "Some of the \"\(str)\" customizations are not available right now."
        }
    }
}

enum TutorialInfo: Int {
    case Page0 = 0, Page1, Page2

    static var count: Int = 3

    var middleLabelText: String {
        switch self {
        case .Page0:
            return NSLocalizedString("Your Wasel agent will buy it for you", comment: "")
        case .Page2:
            return NSLocalizedString("A picture is worth a 1000 words", comment: "")
        case .Page1:
            return NSLocalizedString("Provide Specific details", comment: "")
        }
    }
    
    var bottomLabelText: String {
        switch self {
        case .Page0:
            return NSLocalizedString("We can pickup whatever you want from this store. Just name it!", comment: "")
        case .Page2:
            return NSLocalizedString("Got a photo of the item? It's easier for you and your Wasel, just upload it", comment: "")
        case .Page1:
            return NSLocalizedString("e.g. Brand name, size or anything else to help your wasel get exactly what you’d like", comment: "")
        }
    }
}

enum CardInfo: Int {
    case CardNumber, ExpirationDate, CVV, CardHolderName
    static let count = 4
    
    var headerContent: String {
        switch self {
        case .CardNumber:
            return NSLocalizedString("Card Number", comment: "")
        case .ExpirationDate:
            return NSLocalizedString("Expiration Date", comment: "")
        case .CVV:
            return NSLocalizedString("CVV", comment: "")
        case .CardHolderName:
            return NSLocalizedString("Card Holder Name", comment: "")
        }
    }
    
    var placeHolderContent: String {
        switch self {
        case .CardNumber:
            return NSLocalizedString("Enter card number", comment: "")
        case .ExpirationDate:
            return NSLocalizedString("MM   /   YY", comment: "")
        case .CVV:
            return NSLocalizedString("CVV", comment: "")
        case .CardHolderName:
            return NSLocalizedString("Card holder name", comment: "")
        }
    }
}
