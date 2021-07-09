//
//  StaticDataService.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 05/10/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift

class StaticDataService: WaselDeliveryService {

// MARK: - UserManagement API
    
    func loginUser(_ requestObj: [String: AnyObject]) -> Observable<User> {
        
        let userObj: UnboxableDictionary = ["name": "Amarnath",
                                           "email": "amarnath@xcubelabs.com",
                                           "imageUrl": "",
                                           "id": "",
                                           "mobile": "",
                                           "accountType": AccountType.wasel]
        
        guard let user: User = try? unbox(dictionary: userObj) else {
            return Observable.just(User())
        }
        return Observable.just(user)
    }

    func registerUser(_ requestObj: Registration) -> Observable<User> {
        
        let userObj: UnboxableDictionary = ["name": "",
                                           "email": "",
                                           "imageUrl": "",
                                           "id": "",
                                           "mobile": "",
                                           "accountType": AccountType.wasel]
        
        guard let user: User = try? unbox(dictionary: userObj) else {
            return Observable.just(User())
        }
        return Observable.just(user)
    }
    
    func generateOTP(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        return Observable.just(true)
    }
    
    func verifyOTP(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        return Observable.just(true)
    }
    
    func savePassword(_ requestObj: [String: String]) -> Observable<Bool> {
        return Observable.just(true)
    }
    
    func checkUserExistance(_ requestObj: [String: AnyObject]) -> Observable<User> {
        let userObj: UnboxableDictionary = ["name": "",
                                           "email": "",
                                           "imageUrl": "",
                                           "id": "",
                                           "mobile": "",
                                           "accountType": AccountType.wasel]
        guard let user: User = try? unbox(dictionary: userObj) else {
            return Observable.just(User())
        }
        return Observable.just(user)
    }

    func validateUser(_ requestObj: [String: String]) -> Observable<[String: AnyObject]> {
        return Observable.just(["": "" as AnyObject])
    }
    
    func syncUser(_ requestObj: [String: AnyObject]) -> Observable<User> {
        let userObj: UnboxableDictionary = ["name": "",
                                           "email": "",
                                           "imageUrl": "",
                                           "id": "",
                                           "mobile": "",
                                           "accountType": AccountType.wasel]
        guard let user: User = try? unbox(dictionary: userObj) else {
            return Observable.just(User())
        }
        return Observable.just(user)
    }

// MARK: - LandingPageAPI
    
    func getAmenities() -> Observable<[Amenity]> {
        return self.parseAmenities(getJSONObj("amenities", false) as? [[String: AnyObject]])
    }

    func getOutlets(_ requestObj: [String: AnyObject]) -> Observable<[OutletsInfo]> {
        return self.parseOutlets(getJSONObj("outlet", false) as? [[String: AnyObject]])
    }
    
// MARK: - SavedCards
    
    func getSavedCards(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        return self.parseSavedCards(getJSONObj("paymentCard", false) as? [[String: AnyObject]])
    }

    func updateSavedCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        return self.parseSavedCards(getJSONObj("paymentCard", false) as? [[String: AnyObject]])
    }
    
    func deleteSavedCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        return self.parseSavedCards(getJSONObj("paymentCard", false) as? [[String: AnyObject]])
    }
    
    func saveCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]> {
        return self.parseSavedCards(getJSONObj("paymentCard", false) as? [[String: AnyObject]])
    }

// MARK: - OutletItemDetailsAPI

    func getOutletItems(_ requestObj: [String: String]) -> Observable<[OutletItem]> {
        return self.parseOutletItems(getJSONObj("menu", true) as? [String: AnyObject])
    }
    
// MARK: - Coupon API
    
    func getCoupons() -> Observable<[Coupon]> {
        return self.parseCoupons(getJSONObj("coupons", false) as? [[String: AnyObject]])
    }
    
    func verifyCoupon(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        return Observable.just(true)
    }

    // MARK: - User Profile
    
    func getUserProfile() -> Observable<User> {
        return self.parseUser(getJSONObj("user", true) as? [String: AnyObject])
    }
    
    func addUserAddress(_ requestObj: Address) -> Observable<User> {
        return self.parseUser(getJSONObj("user", true) as? [String: AnyObject])
    }
    
    func deleteAddress(_ requestObj: [String: AnyObject]) -> Observable<User> {
        return self.parseUser(getJSONObj("user", true) as? [String: AnyObject])
    }

    func updateProfile(_ requestObj: [String: AnyObject]) -> Observable<User> {
        return self.parseUser(getJSONObj("user", true) as? [String: AnyObject])
    }
    
    func updateProfileImage(_ requestObj: [String: AnyObject]) -> Observable<User> {
        return self.parseImage(getJSONObj("user", true) as? [String: AnyObject])
    }

    func updateProductImage(_ requestObj: [String: AnyObject]) -> Observable<User> {
        return self.parseImage(getJSONObj("user", true) as? [String: AnyObject])
    }

// MARK: - Order API

    func placeOrder(_ requestObj: [String: AnyObject]) -> Observable<Any> {
        return self.parseUnconfirmedOrder(getJSONObj("order", true) as? [String: AnyObject])
    }
    
    func paymentUpdate(_ requestObj: [String: AnyObject]) -> Observable<Any> {
        return self.parseConfirmedOrder(getJSONObj("order", true) as? [String: AnyObject])
    }
    
    func paymentUpdate2(_ requestObj: [String: AnyObject]) -> Observable<Any> {
        return self.parseConfirmedOrder(getJSONObj("order", true) as? [String: AnyObject])
    }

// MARK: - OrderHistory API
    
    func getOrderHistory(_ requestObj: [String: AnyObject]) -> Observable<[Order]> {
        return self.parseOrders(getJSONObj("orders", false) as? [[String: AnyObject]])
    }
    
// MARK: - OderDetail API
    
    func getOrderDetails(_ requestObj: [String: AnyObject]) -> Observable<Order> {
        return self.parseOrder(getJSONObj("order", true) as? [String: AnyObject])
    }
    
// MARK: - Delivery by Vehicle
    func deliveryChargesByVehicleType(_ requestObj: [String: AnyObject]) -> Observable<DeliveryCharge> {
        Utilities.log(requestObj as AnyObject, type: .info)
        return ApiManager.post(URI.deliveryChargesByVehicleType.rawValue, params: requestObj as AnyObject?)
            .map { self.parseVehicleDelivery($0 as? [String: AnyObject])}.concat()
    }
    
// MARK: Search -
    
    func searchItem(_ requestObj: [String: AnyObject]) -> Observable<[OutletsInfo]> {
        return self.parseSearchOutlets(getJSONObj("outlet", false) as? [[String: AnyObject]])
    }
    
// MARK: Cancel Order -

    func cancelOrder(_ requestObj: [String: AnyObject]) -> Observable<Order> {
        return self.parseOrder(getJSONObj("order", true) as? [String: AnyObject])
    }
    
// MARK: - Cancel Order API
    
    func cancelOrderReasons() -> Observable<[OrderCancelReason]> {
        return self.parseCancelReasons(getJSONObj("orders", false) as? [[String: AnyObject]])
    }
    
// MARK: - Feedback
    
    func giveFeedback(_ requestObj: [[String: AnyObject]]) -> Observable<Bool> {
        return Observable.just(true)
    }
    
    func getFeedbackOrders(_ requestObj: [String: AnyObject]) -> Observable<[Order]> {
        return self.parseOrders(getJSONObj("orders", false) as? [[String: AnyObject]])
    }

// MARK: - Logout
    
    func logout(_ requestObj: [String: AnyObject]) -> Observable<Bool> {
        return Observable.just(true)
    }
    
// MARK: - App Version
    
    func fetchAppVersion(_ requestObj: String) -> Observable<AppVersion> {
        let versionObj: UnboxableDictionary = ["version": "",
                                              "message": ""]
//        let appVersion: AppVersion = try! unbox(dictionary: versionObj)
//        return Observable.just(appVersion)
        
        guard let appVersion: AppVersion = try? unbox(dictionary: versionObj) else {
            return Observable.just(AppVersion())
        }
        return Observable.just(appVersion)
    }

// MARK: - Version
    
    func getVersion() -> Observable<Version> {
        let userObj: UnboxableDictionary = ["vesion": "",
                                           "s3BaseUrl": ""]
//        let user: Version = try! unbox(dictionary: userObj)
//        return Observable.just(user)
        
        guard let version: Version = try? unbox(dictionary: userObj) else {
            return Observable.just(Version())
        }
        return Observable.just(version)
    }
    
// MARK: - App Settings
    
    func fetchAppSettings() -> Observable<AppSettings> {
        let settingsObj: UnboxableDictionary = ["message": "",
                                           "open": "",
                                           "time": ""]
//        let appSettings: AppSettings = try! unbox(dictionary: settingsObj)
//        return Observable.just(appSettings)
        
        guard let appSettings: AppSettings = try? unbox(dictionary: settingsObj) else {
            return Observable.just(AppSettings())
        }
        return Observable.just(appSettings)
    }

// MARK: - Refresh AccessToken
    
    func refreshAccessToken(_ requestObj: [String: AnyObject]) -> Observable<[String: AnyObject]> {
        return Observable.just([:])
    }
    
// MARK: - Support
    
    func getHelpAndSupportDetails() -> Observable<Support> {
        let supportObj: UnboxableDictionary = ["email": "",
                                              "mobile": ""]
        guard let support: Support = try? unbox(dictionary: supportObj) else {
            return Observable.just(Support())
        }
        return Observable.just(support)
    }
    
// MARK: - UpdateDeviceToken
    
    func updateDeviceToken(_ requestObj: [String: AnyObject]) -> Observable<User> {
        return self.parseUser(getJSONObj("user", true) as? [String: AnyObject])
    }
    
    func updateDeviceTokenWithOutLogin(_ requestObj: [String: AnyObject]) -> Observable<User> {
        return self.parseUser(getJSONObj("user", true) as? [String: AnyObject])
    }

// MARK: - Delivery Charge
    
    func getDeliveryCharge(_ requestObj: [String: AnyObject]) -> Observable<[Address]> {
        return self.parseAddresses(getJSONObj("addresses", false) as? [[String: AnyObject]])
    }

// MARK: - Support Methods
    
    fileprivate func getJSONObj(_ fileName: String, _ asDictionary: Bool) -> Any? {
        let filePath = Bundle.main.path(forResource: fileName, ofType: "json")
        if let filePath_ = filePath {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath_))
                do {
                    if asDictionary {
                        let json  = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as?
                            [String: AnyObject]
                        return json
                    } else {
                        let json  = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as?
                            [[String: AnyObject]]
                        return json
                    }
                } catch {
                    return nil
                }
            } catch {
                return nil
            }
        }
        return nil
    }
}
