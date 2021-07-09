//
//  WaselDeliveryService.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 05/10/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import Unbox
import Upshot

protocol WaselDeliveryService {

// MARK: - UserManagement API
    
    func loginUser(_ requestObj: [String: AnyObject]) -> Observable<User>
    
    func registerUser(_ requestObj: Registration) -> Observable<User>
    
    func generateOTP(_ requestObj: [String: AnyObject]) -> Observable<Bool>
    
    func verifyOTP(_ requestObj: [String: AnyObject]) -> Observable<Bool>
    
    func savePassword(_ requestObj: [String: String]) -> Observable<Bool>
    
    func checkUserExistance(_ requestObj: [String: AnyObject]) -> Observable<User>
    
    func validateUser(_ requestObj: [String: String]) -> Observable<[String: AnyObject]>

    func syncUser(_ requestObj: [String: AnyObject]) -> Observable<User>

// MARK: - LandingPageAPI
    
    func getAmenities() -> Observable<[Amenity]>
    
    func getOutlets(_ requestObj: [String: AnyObject]) -> Observable<[OutletsInfo]>
    
    func getSavedCards(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]>
    
    func updateSavedCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]>
    
    func deleteSavedCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]>
    
    func saveCard(_ requestObj: [String: AnyObject]) -> Observable<[PaymentCard]>
    
// MARK: - OutletItemDetailsAPI
    
    func getOutletItems(_ requestObj: [String: String]) -> Observable<[OutletItem]>

// MARK: - Coupons
    
    func getCoupons() -> Observable<[Coupon]>

    func verifyCoupon(_ requestObj: [String: AnyObject]) -> Observable<Bool>
    
// MARK: - User Profile
    
    func getUserProfile() -> Observable<User>
        
    func addUserAddress(_ requestObj: Address) -> Observable<User>
    
    func deleteAddress(_ requestObj: [String: AnyObject]) -> Observable<User>

    func updateProfile(_ requestObj: [String: AnyObject]) -> Observable<User>

    func updateProfileImage(_ requestObj: [String: AnyObject]) -> Observable<User>
    
    func updateProductImage(_ requestObj: [String: AnyObject]) -> Observable<User>
    
// MARK: - Order
    
    func placeOrder(_ requestObj: [String: AnyObject]) -> Observable<Any>
   
    func paymentUpdate(_ requestObj: [String: AnyObject]) -> Observable<Any>

    func paymentUpdate2(_ requestObj: [String: AnyObject]) -> Observable<Any>

    func getOrderHistory(_ requestObj: [String: AnyObject]) -> Observable<[Order]>
    
    func getOrderDetails(_ requestObj: [String: AnyObject]) -> Observable<Order>
    
// MARK: - Vehicle
    
    func deliveryChargesByVehicleType(_ requestObj: [String: AnyObject]) -> Observable<DeliveryCharge>
    
// MARK: - Search
    
    func searchItem(_ requestObj: [String: AnyObject]) -> Observable<[OutletsInfo]>
    
// MARK: Cancel Order -
    
    func cancelOrder(_ requestObj: [String: AnyObject]) -> Observable<Order>
    
// MARK: - Cancel Order Reasons API

    func cancelOrderReasons() -> Observable<[OrderCancelReason]>

// MARK: - Feedback
    
    func giveFeedback(_ requestObj: [[String: AnyObject]]) -> Observable<Bool>
    
    func getFeedbackOrders(_ requestObj: [String: AnyObject]) -> Observable<[Order]>
    
// MARK: - Logout
    
    func logout(_ requestObj: [String: AnyObject]) -> Observable<Bool>
    
// MARK: - Versioning
    
    func getVersion() -> Observable<Version>
    
// MARK: - App Settings
    
    func fetchAppSettings() -> Observable<AppSettings>
    
// MARK: - UpdateDeviceToken
    
    func updateDeviceToken(_ requestObj: [String: AnyObject]) -> Observable<User>
    
    func updateDeviceTokenWithOutLogin(_ requestObj: [String: AnyObject]) -> Observable<User>
    
// MARK: - Delivery Charge
    
    func getDeliveryCharge(_ requestObj: [String: AnyObject]) -> Observable<[Address]>

// MARK: - Help&Support
    
    func getHelpAndSupportDetails() -> Observable<Support>
    
    func fetchAppVersion(_ requestObj: String) -> Observable<AppVersion>
    
// MARK: - Refresh AccessToken
    
    func refreshAccessToken(_ requestObj: [String: AnyObject]) -> Observable<[String: AnyObject]>
}

extension WaselDeliveryService {
    
    func parseUser(_ userObject: [String: AnyObject]?) -> Observable<User> {
        do {
            if let userObject_ = userObject {
                let user: User = try unbox(dictionary: userObject_)
                Utilities.setAccessTokens(tokens: (access: userObject_["accessToken"] as? String, refresh: userObject_["refereshToken"] as? String))
                if var savedUser_ = Utilities.getUser() {
                    savedUser_.name = user.name
                    savedUser_.email = user.email
                    savedUser_.imageUrl = user.imageUrl
                    savedUser_.accountType = user.accountType
                    savedUser_.addresses = user.addresses
                    savedUser_.token = user.token

                    Utilities.shared.user = savedUser_
                    Utilities.setUserObject(savedUser_)
                    return Observable.just(savedUser_)
                } else if user.id != nil {
                    Utilities.shared.user = user
                    Utilities.setUserObject(user)
                    return Observable.just(user)
                }
            }
            let user: User = try unbox(dictionary: ["": ""])
            return Observable.just(user)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
    func parseImage(_ obj: [String: AnyObject]?) -> Observable<User> {
        do {
            if let obj_ = obj {

                let user: User = try unbox(dictionary: obj_)
                return Observable.just(user)
            }
            let user: User = try unbox(dictionary: ["": ""])
            return Observable.just(user)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
    func parseValidUser(_ obj: [String: AnyObject]?) -> Observable<[String: AnyObject]> {
        if let response_ = obj {
            return Observable.just(response_)
        }
        return Observable.just(["": "" as AnyObject])
    }
    
    func parseSavedCards(_ cardsObj: [[String: AnyObject]]?) -> Observable<[PaymentCard]> {
        
        do {
            var paymentCards_ = [PaymentCard]()
            if let rawCards_ = cardsObj {
                for card_ in rawCards_ {
                    let paymentCard: PaymentCard = try unbox(dictionary: card_)
                    paymentCards_.append(paymentCard)
                }
            }
            return Observable.just(paymentCards_)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
// MARK: - LandingPageParseMethods
    
    func parseAppVersion(_ orderObj: [String: AnyObject]?) -> Observable<AppVersion> {
        do {
            if let obj_ = orderObj {
                let version: AppVersion = try unbox(dictionary: obj_)
                return Observable.just(version)
            }
            let version: AppVersion = try unbox(dictionary: ["version": "",
                                                         "message": ""])
            return Observable.just(version)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }

    func parseAmenities(_ amenityObj: [[String: AnyObject]]?) -> Observable<[Amenity]> {
        
        do {
            var amenities = [Amenity]()
            if let rawAmenities = amenityObj {
                for amenity in rawAmenities {
                    let amenity_: Amenity = try unbox(dictionary: amenity)
                    amenities.append(amenity_)
                }
            }
            return Observable.just(amenities)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }

    func parseOutlets(_ outletObj: [[String: AnyObject]]?) -> Observable<[OutletsInfo]> {
        
        do {
            var outlets = [OutletsInfo]()
            if let rawOutlets = outletObj {
                for outlet in rawOutlets {
                   	 let amenity_: OutletsInfo = try unbox(dictionary: outlet)
                    outlets.append(amenity_)
                }
            }
            return Observable.just(outlets)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
    func parseSearchOutlets(_ outletObj: [[String: AnyObject]]?) -> Observable<[OutletsInfo]> {
        
        do {
            var outlets = [OutletsInfo]()
            if let rawOutlets = outletObj {
                for outlet in rawOutlets {
                    let amenity_: OutletsInfo = try unbox(dictionary: outlet)
                    outlets.append(amenity_)
                }
            }
            return Observable.just(outlets)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }

    func parseOutletItems(_ outletObj: [String: AnyObject]?) -> Observable<[OutletItem]> {
        
        do {
            var outletItems = [OutletItem]()
            if let rawOutlet = outletObj {
                if let items_ = rawOutlet["outletItems"] as? [[String: AnyObject]] {
                    for outletItem in items_ {
                        let outletItem_: OutletItem = try unbox(dictionary: outletItem)
                        outletItems.append(outletItem_)
                    }
                }
            }
            return Observable.just(outletItems)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
// MARK: - CouponsParseMethods

    func parseCoupons(_ couponsObj: [[String: AnyObject]]?) -> Observable<[Coupon]> {
        do {
            var coupons = [Coupon]()
            if let rawCoupons = couponsObj {
                for coupon in rawCoupons {
                    let coupon_: Coupon = try unbox(dictionary: coupon)
                    coupons.append(coupon_)
                }
            }
            return Observable.just(coupons)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }

// MARK: - OrderParseMethods
    
    func parseOrder(_ orderObj: [String: AnyObject]?) -> Observable<Order> {

        do {
            if let rawOrder = orderObj {
                if rawOrder["id"] != nil {
                    let order: Order = try unbox(dictionary: rawOrder)
                    return Observable.just(order)
                }
            }
            return Observable.error(ResponseError.parseError)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
    func parseUnconfirmedOrder(_ orderObj: [String: AnyObject]?) -> Observable<Any> {
        
        do {
            if let rawOrder = orderObj, let rawOrder_ = rawOrder["order"] as? [String: AnyObject] {
                let ordersCount = rawOrder["totalOrdersCount"] as? Int ?? 0
                let userInfo = BKUserInfo.init()
                let infoDict = ["OrdersCount": ordersCount]
                userInfo.others = infoDict
                userInfo.build(completionBlock: nil)
                
                if let removedItems_ = rawOrder_["removedItems"] as? [[String: AnyObject]], removedItems_.count > 0 {
                    var removedItems = [OutletItem]()
                    for outletItem in removedItems_ {
                        let outletItem_: OutletItem = try unbox(dictionary: outletItem)
                        removedItems.append(outletItem_)
                    }
                    return Observable.just(removedItems)
                } else if nil != rawOrder_["id"] {
                    let order: Order = try unbox(dictionary: rawOrder_)
                    return Observable.just(order)
                }
            }
            return Observable.error(ResponseError.parseError)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
    func parseConfirmedOrder(_ orderObj: [String: AnyObject]?) -> Observable<Any> {
        
        do {
            if let rawOrder_ = orderObj {
                if let removedItems_ = rawOrder_["removedItems"] as? [[String: AnyObject]], removedItems_.count > 0 {
                    var removedItems = [OutletItem]()
                    for outletItem in removedItems_ {
                        let outletItem_: OutletItem = try unbox(dictionary: outletItem)
                        removedItems.append(outletItem_)
                    }
                    return Observable.just(removedItems)
                } else if nil != rawOrder_["id"] {
                    let order: Order = try unbox(dictionary: rawOrder_)
                    return Observable.just(order)
                }
            }
            return Observable.error(ResponseError.parseError)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
// MARK: - OrderHistoryParse Method
    
    func parseOrders(_ ordersObj: [[String: AnyObject]]?) -> Observable<[Order]> {
        do {
            var orders = [Order]()
            if let rawOrders = ordersObj {
                for order in rawOrders {
                    let order_: Order = try unbox(dictionary: order)
                    orders.append(order_)
                }
            }
            return Observable.just(orders)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }

// MARK: - Cancel Order Reasons Method
    
    func parseCancelReasons(_ reasons: [[String: AnyObject]]?) -> Observable<[OrderCancelReason]> {
        do {
            var cancelReasons = [OrderCancelReason]()
            if let rawReasons = reasons {
                for reason_ in rawReasons {
                    let orderCancelReason: OrderCancelReason = try unbox(dictionary: reason_)
                    cancelReasons.append(orderCancelReason)
                }
            }
            return Observable.just(cancelReasons)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
// MARK: - VehicleDelivery
    
    func parseVehicleDelivery(_ vehicleDeliveryObj: [String: AnyObject]?) -> Observable<DeliveryCharge> {

        do {
            if let rawVehicleDeliveryObj = vehicleDeliveryObj {
                let vehicleDelivery: DeliveryCharge = try unbox(dictionary: rawVehicleDeliveryObj)
                return Observable.just(vehicleDelivery)
            }
            return Observable.error(ResponseError.parseError)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }

// MARK: - Version
    
    func parseAppSettings(_ orderObj: [String: AnyObject]?) -> Observable<AppSettings> {
        do {
            if let obj_ = orderObj {
                let appSetings: AppSettings = try unbox(dictionary: obj_)
                return Observable.just(appSetings)
            }
            let appSetings: AppSettings = try unbox(dictionary: ["": ""])
            return Observable.just(appSetings)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
// MARK: - Version
    
    func parseVersion(_ orderObj: [String: AnyObject]?) -> Observable<Version> {
        do {
            if let obj_ = orderObj {
                let version: Version = try unbox(dictionary: obj_)
                return Observable.just(version)
            }
            let version: Version = try unbox(dictionary: ["": ""])
            return Observable.just(version)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }

// MARK: - Support
    
    func parseSupport(_ orderObj: [String: AnyObject]?) -> Observable<Support> {
        do {
            if let obj_ = orderObj {
                let version: Support = try unbox(dictionary: obj_)
                return Observable.just(version)
            }
            let version: Support = try unbox(dictionary: ["mobile": "",
                                                         "email": ""])
            return Observable.just(version)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
// MARK: - DeliveryCharges
    
    func parseAddresses(_ addressObj: [[String: AnyObject]]?) -> Observable<[Address]> {
        
        do {
            var addresses = [Address]()
            if let rawAddresses = addressObj {
                for address in rawAddresses {
                    let address_: Address = try unbox(dictionary: address)
                    addresses.append(address_)
                }
            }
            return Observable.just(addresses)
        } catch {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
    
// MARK: - Refresh AccessToken
    
    func parseAccessToken(_ tokenObject: [String: AnyObject]?) -> Observable<[String: AnyObject]> {
        if let tokenObject_ = tokenObject {
            Utilities.setAccessTokens(tokens: (access: tokenObject_["accessToken"] as? String, refresh: tokenObject_["refreshToken"] as? String))
            return Observable.just(tokenObject_)
        } else {
            return Observable.error(ResponseError.unboxParseError)
        }
    }
}
