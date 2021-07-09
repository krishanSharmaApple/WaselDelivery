//
//  APIDataService.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 05/10/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift

class APIDataService: WaselDeliveryService {
    
    fileprivate func getResponseErrorWithStatusCode(_ statusCode: Int) -> ResponseError {
        switch statusCode {
        case ResponseStatusCode.notFound.rawValue:
            return ResponseError.notFoundError
        case ResponseStatusCode.badRequest.rawValue:
            return ResponseError.badRequestError
        case ResponseStatusCode.timeout.rawValue:
             return ResponseError.timeoutError
        case ResponseStatusCode.internalServer.rawValue:
             return ResponseError.internalServerError
            
        default:
            return ResponseError.unkonownError
        }
    }
    
// MARK: - UserManagement API
    
    func registerUser(_ requestObj: Registration) -> Observable<User> {
        var request = [String: Any]()
        if let name = requestObj.name {
            request["name"] = name as AnyObject
        }
        if let email = requestObj.email {
            request["email"] = email  as AnyObject
        }
        if let mobile = requestObj.mobile {
            request["mobile"] = mobile as AnyObject
        }
        if let countryCode = requestObj.countryCode {
            request["countryCode"] = countryCode.code as AnyObject
        }
        request["accountType"] = requestObj.accountType.rawValue as AnyObject
        if requestObj.accountType == .wasel {
            if let password = requestObj.password {
                request["password"] = password as AnyObject
            }
        } else if requestObj.accountType == .facebook {
            if let id = requestObj.id {
                request["facebookUID"] = id as AnyObject
            }
        } else if requestObj.accountType == .google {
            if let id = requestObj.id {
                request["googleUID"] = id as AnyObject
            }
        } else if requestObj.accountType == .apple {
            if let id = requestObj.id {
                request["appleUID"] = id as AnyObject
            }
        }
        let appdelegate = UIApplication.shared.delegate as? AppDelegate
        if let deviceToken_ = appdelegate?.deviceToken {
            let item: [[String: AnyObject]] = [[IsAndroidKey: false as AnyObject,
                                                "deviceToken": deviceToken_ as AnyObject]]
            request["device"] = item as AnyObject?
        }
        Utilities.log(request as AnyObject, type: .info)

        return ApiManager.post(URI.register.rawValue, params: request as AnyObject?)
            .map {
                self.parseUser($0 as? [String: AnyObject])
            }.concat()
    }
    
    func loginUser(_ requestObj: [String: AnyObject]) -> Observable<User> {
        
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.login.rawValue, params: requestObj as AnyObject?)
            .map {
                self.parseUser($0 as? [String: AnyObject])
            }.concat()
    }
    
    func generateOTP(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.generateOtp.rawValue, params: requestObj as AnyObject?)
            .map {_ in  Observable.just(true) }.concat()
    }
    
    func verifyOTP(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.verifyOtp.rawValue, params: requestObj as AnyObject?)
            .map {_ in Observable.just(true) }.concat()
    }

    func savePassword(_ requestObj: [String: String]) -> Observable<Bool> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.savePassword.rawValue, params: requestObj as AnyObject?)
            .map {_ in Observable.just(true) }.concat()
    }
    
    func checkUserExistance(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.checkUserExistance.rawValue, params: requestObj as AnyObject?)
            .map { self.parseUser($0 as? [String: AnyObject]) }.concat()
    }

    func validateUser(_ requestObj: [String: String]) -> Observable<[String: AnyObject]> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.validateUser.rawValue, params: requestObj as AnyObject?)
            .map { self.parseValidUser($0 as? [String: AnyObject]) }.concat()
    }
    
    func syncUser(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.syncUser.rawValue, params: requestObj as AnyObject?)
            .map { self.parseUser($0 as? [String: AnyObject]) }.concat()
    }

// MARK: LandingPageAPI
    
    func getAmenities() -> Observable<[Amenity]> {
        return ApiManager.get(URI.amenityList.rawValue)
            .map { self.parseAmenities($0 as? [[String: AnyObject]])}.concat()
    }
    
    func getOutlets(_ requestObj: [String: AnyObject]) -> Observable<[OutletsInfo]> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.outletsList.rawValue, params: requestObj as AnyObject?)
            .map { self.parseOutlets($0 as? [[String: AnyObject]])}.concat()
    }
    
    func getCoupons() -> Observable<[Coupon]> {
        return ApiManager.get(URI.coupons.rawValue)
            .map { self.parseCoupons($0 as? [[String: AnyObject]])}.concat()
    }
    
    func verifyCoupon(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        let path = URI.verifyCoupon.rawValue + "\(requestObj["userId"] as? String ?? "")" + "/\(requestObj["couponId"] as? Int ?? 0)"
        Utilities.log(path as AnyObject, type: .info)
        return ApiManager.get(path).map {_ in Observable.just(true) }.concat()
    }
    
// MARK: - App Settings
    
    func fetchAppSettings() -> Observable<AppSettings> {
        return ApiManager.get(URI.appSettings.rawValue)
            .map { self.parseAppSettings($0 as? [String: AnyObject])}.concat()
    }

// MARK: - Versioning
    
    func getVersion() -> Observable<Version> {
        return ApiManager.get(URI.version.rawValue)
            .map { self.parseVersion($0 as? [String: AnyObject])}.concat()
    }
    
// MARK: - OutletItemDetailsAPI
    
    func getOutletItems(_ requestObj: [String: String]) -> Observable<[OutletItem]> {
        let path = URI.outletItems.rawValue + "\(requestObj["id"] ?? "")"
        Utilities.log(path as AnyObject, type: .info)
        return ApiManager.get(path)
            .map { self.parseOutletItems($0 as? [String: AnyObject])}.concat()
    }
    
// MARK: - User Profile
    
    func getUserProfile() -> Observable<User> {
        
        let url = URI.getProfile.rawValue+"/\(Utilities.shared.user?.id ?? "")"
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseUser($0 as? [String: AnyObject])}.concat()
    }
        
    func addUserAddress(_ requestObj: Address) -> Observable<User> {
        
        var request = [String: AnyObject]()
        let user = Utilities.getUser()
        
        request["id"] = user?.id as AnyObject
        var address = [String: AnyObject]()
        address["latitude"] = requestObj.latitude as AnyObject
        address["longitude"] = requestObj.longitude as AnyObject
        address["addressType"] = requestObj.addressType as AnyObject
        address["location"] = requestObj.location as AnyObject
        
        if let doorNumber = requestObj.doorNumber {
            address["doorNumber"] = doorNumber as AnyObject
        }
        
        if let landmark = requestObj.landmark {
            address["landmark"] = landmark as AnyObject
        }
        
        if let country = requestObj.country {
            address["country"] = country as AnyObject
        }
        
        if let countryCode = requestObj.countryCode {
            address["countryCode"] = countryCode as AnyObject
        }
        
        request["address"] = [address] as AnyObject

        Utilities.log(request as AnyObject, type: .info)
        return ApiManager.post(URI.updateProfile.rawValue, params: request as AnyObject?)
            .map {
                self.parseUser($0 as? [String: AnyObject])
            }.concat()
    }

    func deleteAddress(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.updateProfile.rawValue, params: requestObj as AnyObject?)
            .map {
                self.parseUser($0 as? [String: AnyObject])
            }.concat()
    }

    func updateProfile(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.updateProfile.rawValue, params: requestObj as AnyObject?)
            .map {
                self.parseUser($0 as? [String: AnyObject])
            }.concat()
    }

    func updateProfileImage(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.profileImage.rawValue, params: requestObj as AnyObject?, shouldUploadImage: true)
            .map {
                self.parseImage($0 as? [String: AnyObject])
            }.concat()
    }
    
    func updateProductImage(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.productImage.rawValue, params: requestObj as AnyObject?, shouldUploadImage: true)
            .map {
                self.parseImage($0 as? [String: AnyObject])
            }.concat()
    }

// MARK: - Saved Cards
    
    func getSavedCards(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        let url = URI.savedCardsList.rawValue+"\(requestObj["userId"] as? String ?? "")"
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseSavedCards($0 as? [[String: AnyObject]])}.concat()
    }

    func updateSavedCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        let url = URI.updateSavedCard.rawValue+"\(requestObj["id"] as? Int ?? -1)"
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseSavedCards($0 as? [[String: AnyObject]])}.concat()
    }

    func deleteSavedCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        let url = URI.deleteSavedCard.rawValue+"\(requestObj["id"] as? Int ?? -1)"
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseSavedCards($0 as? [[String: AnyObject]])}.concat()
    }
    
    func saveCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.saveCard.rawValue, params: requestObj as AnyObject?)
            .map { self.parseSavedCards($0 as? [[String: AnyObject]])}.concat()
    }
    
// MARK: - Order API
    
    func placeOrder(_ requestObj: [String: AnyObject]) -> Observable<Any> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.orderDispose.rawValue, params: requestObj as AnyObject?)
            .map { self.parseUnconfirmedOrder($0 as? [String: AnyObject])}.concat()
    }
    
    func paymentUpdate(_ requestObj: [String: AnyObject]) -> Observable<Any> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.paymentUpdate.rawValue, params: requestObj as AnyObject?)
            .map { self.parseConfirmedOrder($0 as? [String: AnyObject])}.concat()
    }

    func paymentUpdate2(_ requestObj: [String: AnyObject]) -> Observable<Any> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.paymentUpdate2.rawValue, params: requestObj as AnyObject?)
            .map { self.parseConfirmedOrder($0 as? [String: AnyObject])}.concat()
    }

// MARK: - OrderHistory API
    
    func getOrderHistory(_ requestObj: [String: AnyObject]) -> Observable<[Order]> {

        let url = URI.getOrderHistory.rawValue+"\(requestObj["id"] as? String ?? "")/\(requestObj["start"] as? Int ?? 0)/\(requestObj["limit"] as? Int ?? 0)"
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseOrders($0 as? [[String: AnyObject]])}.concat()
    }
    
// MARK: - Cancel Order API

    func cancelOrder(_ requestObj: [String: AnyObject]) -> Observable<Order> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.cancelOrder.rawValue, params: requestObj as AnyObject?)
            .map { self.parseOrder($0 as? [String: AnyObject])}.concat()
    }
    
// MARK: - Cancel Order Reasons API
    
    func cancelOrderReasons() -> Observable<[OrderCancelReason]> {
        
        let url = URI.cancelOrderReasons.rawValue
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseCancelReasons($0 as? [[String: AnyObject]])}.concat()
    }
    
// MARK: - OderDetail API
    
    func getOrderDetails(_ requestObj: [String: AnyObject]) -> Observable<Order> {
        
        let url = URI.getOrderDetails.rawValue+"\(requestObj["id"] as? Int ?? 0)"
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseOrder($0 as? [String: AnyObject])}.concat()
    }
    
// MARK: - Vehicle
    func deliveryChargesByVehicleType(_ requestObj: [String: AnyObject]) -> Observable<DeliveryCharge> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.deliveryChargesByVehicleType.rawValue, params: requestObj as AnyObject?)
            .map { self.parseVehicleDelivery($0 as? [String: AnyObject])}.concat()
    }
    
// MARK: - Search
    
    func searchItem(_ requestObj: [String: AnyObject]) -> Observable<[OutletsInfo]> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.searchResults.rawValue, params: requestObj as AnyObject?)
            .map { self.parseSearchOutlets($0 as? [[String: AnyObject]])}.concat()
    }
    
// MARK: - Feedback
    
    func giveFeedback(_ requestObj: [[String: AnyObject]]) -> Observable<Bool> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.giveFeedback.rawValue, params: requestObj as AnyObject?)
            .map {_ in  Observable.just(true) }.concat()
    }
    
    func getFeedbackOrders(_ requestObj: [String: AnyObject]) -> Observable<[Order]> {
        let url = URI.getFeedbackOrders.rawValue+"\(requestObj["id"] as? String ?? "")"
        Utilities.log(url as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseOrders($0 as? [[String: AnyObject]])}.concat()

    }

// MARK: - Logout
    
    func logout(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.logout.rawValue, params: requestObj as AnyObject?)
            .map {_ in  Observable.just(true) }.concat()
    }

// MARK: - App Version
    func fetchAppVersion(_ requestObj: String) -> Observable<AppVersion> {
        let url = URI.appVersion.rawValue+"\(requestObj)"
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.get(url)
            .map { self.parseAppVersion($0 as? [String: AnyObject])}.concat()
    }

// MARK: - UpdateDeviceToken
    
    func updateDeviceToken(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.deviceTokenUpdate.rawValue, params: requestObj as AnyObject?)
            .map {
                self.parseUser($0 as? [String: AnyObject])
            }.concat()
    }
    
    func updateDeviceTokenWithOutLogin(_ requestObj: [String: AnyObject]) -> Observable<User> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.deviceTokenUpdateWithOutLogin.rawValue, params: requestObj as AnyObject?)
            .map {
                self.parseUser($0 as? [String: AnyObject])
            }.concat()
    }

// MARK: - Delivery Charge
    
    func getDeliveryCharge(_ requestObj: [String: AnyObject]) -> Observable<[Address]> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.deliverycharge.rawValue, params: requestObj as AnyObject?)
            .map { self.parseAddresses($0 as? [[String: AnyObject]])}.concat()
    }

// MARK: - Help&Support
    
    func getHelpAndSupportDetails() -> Observable<Support> {
        return ApiManager.get(URI.support.rawValue)
            .map { self.parseSupport($0 as? [String: AnyObject])}.concat()
    }
    
// MARK: - Refresh AccessToken
    
    func refreshAccessToken(_ requestObj: [String: AnyObject]) -> Observable<[String: AnyObject]> {
        return ApiManager.post(URI.accessToken.rawValue, params: requestObj as AnyObject).map {
            self.parseAccessToken($0 as? [String: AnyObject])
            }.concat()
    }

}
