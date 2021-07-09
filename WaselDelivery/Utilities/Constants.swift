//
//  Constants.swift
//  WaselDelivery
//
//  Created by sunanda on 9/23/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import UIKit

// API Constants
// remember to change URLs before giving out a build

// private let localBaseUrl = "http://192.168.2.63:8071" // Local
//private let preProductionBaseUrl = "https://dev.waseldelivery.com/"

// new url = "dev.waseldelivery.com"
private let preProductionBaseUrl = "http://dev.waseldelivery.com/" //31.14.16.236:8072
private let productionBaseUrl = "https://dev.waseldelivery.com" //api.waseldelivery.com  // Production live server

#if DEBUG
    let baseUrl = preProductionBaseUrl
#elseif RELEASE
    let baseUrl = productionBaseUrl
#else // if HOCKEY
    let baseUrl = preProductionBaseUrl
#endif

let baseAPIURL = baseUrl+"/api/"
let imageBaseUrl = "https://wasel.s3.amazonaws.com/"
let headers = ["Accept": "application/json", "Content-Type": "application/json"]

// Change below key with client provided key
let GoogleAPIKey = "AIzaSyAmbhWPnsk9Jd7-3WGNmE8IOhP7w7DsQN4"
let publicKey = "wasel&:bh"

// Notification Constants

let EnableRestaurantTableViewScrollNotification = "EnableRestaurantTableViewScrollNotification"
let EnableItemTableViewScrollNotification = "EnableItemTableViewScrollNotification"
let ExpandCollapseSectionsNotification = "ExpandCollapseSectionsNotification"
let UpdateCustomizationNotification = "UpdateCustomizationNotification"
let UpdateFilterDictionaryNotification = "UpdateFilterDictionaryNotification"
let RefreshOrderHistoryNotification = "RefreshOrderHistoryNotification"
let RefreshOrderDetailsNotification = "RefreshOrderDetailsNotification"
let UpdateStatusAnimationNotification = "UpdateStatusAnimationNotification"
let UpdateCurrentLocationNotification = "UpdateCurrentLocationNotification"
let ProceedToCheckOutNotification = "ProceedToCheckOutNotification"
let OrderDetailsTableViewHeightNotification = "OrderDetailsTableViewHeightNotification"
let UpdateAppOpenCloseStatusNotification = "UpdateAppOpenCloseStatusNotification"
let UpdateOutletBusyBlinkNotification = "UpdateOutletBusyBlinkNotification"
let PayTabsPaymentNotification = "PayTabsPaymentNotification"
let RefreshOrderNotification = "RefreshOrderNotification"
let DeepLinkProductNotification = "DeepLinkProductNotification"
let DeepLinkCategoryNotification = "DeepLinkCategoryNotification"

let CurrentIndex = "currentIndex"
let OutletBusyMessage = NSLocalizedString("Busy - not accepting orders", comment: "")

let SpecialOrderInstructionsTag = 2001

// Location Constants

let UserSelectedLocation = "UserSelectedLocation"
let isCurrentLocation = "isCurrentLocation"
let LoggedInUser = "LoggedInUser"
let AccessToken = "AccessToken"
let RefreshToken = "RefreshToken"
let UserLoggedIn = "UserLoggedIn"
let LocationSearchHistory = "LocationSearchHistory"
let ItemsSearchHistory = "ItemsSearchHistory"
let isAppOpenState = "isAppOpen"
let appOpenCloseStatusMessage = "appOpenCloseStatusMessage"
let appVersionNumber = "appVersionNumber"

// let isEnabledCashPayment = "isEnabledCashPayment"
// let isEnabledCardPayment = "isEnabledCardPayment"
let isEnabledPayTabsPayment = "isEnabledPayTabsPayment"
let isEnabledCashOrCardPayment = "isEnabledCashOrCardPayment"
let isEnabledCreditCardPayment = "isEnabledCreditCardPayment"
let isEnabledCreditBenfitPayment = "isEnabledCreditBenfitPayment"
let isEnabledMasterCardPayment = "isEnabledMasterCardPayment"
let preBookingDaysKey = "preBooking"

let cashOrCardDescription = "cashOrCardDescription"
let creditCardPaymentDescription = "creditCardPaymentDescription"
let benfitPayDescription = "benfitPayDescription"
let masterCardDescription = "masterCardDescription"
let slectedPaymentMethod = "slectedPaymentMethod"
let isTutorialCompleted = "isTutorialCompleted"

let NotServingLocationMessage = "Not serving selected location"

// GetRestaurant API Keys

let LatitudeKey = "latitude"
let LongitudeKey = "longitude"
let PageNumberKey = "pageNo"
let FilterKey = "filter"
let CuisinesKey = "cuisines"
let BudgetsKey = "budgets"
let RatingKey = "rating"
let AmenityIdKey = "amenityId"
let PageStartKey = "start"
let MaxResultKey = "maxResult"
let SearchItemsKey = "search"
let TimeZoneKey = "timeZone"

// OrderDispose Keys

let OrderChargeKey = "orderCharge"
let DeliveryChargeKey = "deliveryCharge"
let GrandTotalKey = "grandTotal"
let DiscountAmountKey = "discountAmount"
let HandlingFee = "handlingFee"
let HandlingFeeType = "handlingFeeType"
let HandlingFeePercent = "handlingFeePercent"
let VehicleTypeKey = "vehicleType"
let PhoneNumberKey = "phoneNumber"
let EmailKey = "email"
let PaymentModeKey = "paymentType"
let OutletKey = "outlet"
let OrderTypeKey = "orderType"
let PickUpLocation = "pickUpLocation"
let IdKey = "id"
let CodeKey = "code"
let UserIdKey = "userId"
let UserKey = "user"
let CouponKey = "coupon"
let ItemsKey = "items"
let NameKey = "name"
let ItemIdKey = "itemId"
let CustomItemIdKey = "customItemId"
let QuantityKey = "quantity"
let ItemDescriptionKey = "description"
let PriceKey = "price"
let ItemInstructionKey = "instruction"
let CustomItemsKey = "customItems"
let OutletItemCustomFields = "outletItemCustomFields"
let ShippingAddressKey = "shippingAddress"
let LocationKey = "location"
let CountryKey = "country"
let AddressTypeKey = "addressType"
let DoorNoKey = "doorNumber"
let LandmarkKey = "landmark"
let ZipCodeKey = "zipCode"
let OrderInstructionsKey = "orderInstruction"
let IsAndroidKey = "isAndroid"
let DeviceTokenKey = "deviceToken"
let ImageURLKey = "imageUrl"
let IsRepeatKey = "isRepeat"
let OutletIdKey = "outletId"
let ProductImageKey = "imageUrls"
let ScheduledDateKey = "scheduledDate"
let TipAmountKey = "tipAmount"
let cartId = "cartId"

let DeliveryRatingKey = "deliveryRating"
let CommentsKey = "comment"
let OrderIdKey = "orderId"
let AccessTokenKey = "accessToken"
let RefreshTokenKey = "refereshToken"

// UIConstants

let ScreenWidth: CGFloat = UIScreen.main.bounds.width
let ScreenHeight: CGFloat = UIScreen.main.bounds.height
let TabBarHeight: CGFloat = 49.0
let NavigationBarHeight: CGFloat = 64
let HeaderHeight: CGFloat = 50
let ScrollOffset: CGFloat = 160.0 - NavigationBarHeight

let RestaurantsCellHeight: CGFloat = 120.0
let OrderAnythingViewHeight: CGFloat = 60
let SliderImageHeight: CGFloat = 160.0

// Info Messages
let OutOfBahrainMessage = "Bahrain.OutOfBahrainMessage".localized
let EmptyCartMessage = "Bahrain.EmptyCartMessage".localized
let EmptyOrderHistoryMessage = "Bahrain.EmptyOrderHistoryMessage".localized
let LoginFromHistoryMessage = "Bahrain.LoginFromHistoryMessage".localized
let EmptyOutletsMessage = "Bahrain.EmptyOutletsMessage".localized
let EmptyCardsMessage = "Bahrain.EmptyCardsMessage".localized

let EmptyMessageTitle = "Bahrain.Empty".localized
let EmptySearchMessageTitle = "Bahrain.EmptySearch".localized
let ComingSoonTitle = "Bahrain.ComingSoon".localized

// Validation Keys

let MaxMobileNumberCharacters = 15
let MaxEmailCharacters = 254
let MaxNameCharacters = 35
let MaxPasswordCharacters = 64
let MinPasswordCharacters = 6
let ItemMaxLimit = 99
let MaxCharacters = 240
let MaxTipCharacters = 3

struct BKConstants {
    
    static var APPLICATION_ID: String {
        if baseUrl == productionBaseUrl {
            return "1212035e-6b59-4492-9efa-75a084b1fceb" // Production
        }
        return "46e9ee6d-718b-40c8-91ba-ea5ccd3aa01f" // For Demo / Development / Testing
    }
    static let OWNER_ID = "f1653f73-445f-4445-b927-ddc394da202c" // Same for all environments
    
    // Screen names
    static let LOGIN_SCREEN = "LoginScreen"
    static let REGISTRATION_SCREEN = "RegistrationScreen"
    static let ENTER_MOBILE_NUMBER_SCREEN = "EnterMobileNumberScreen"
    static let MOBILENUMBER_VERIFICATION_SCREEN = "MobileNumberVerificationScreen"
    static let RESET_PASSWORD_SCREEN = "ResetPasswordScreen"
    static let LOCATION_SELECTION_SCREEN = "LocationSelectionScreen"
    static let HOME_SCREEN = "HomeScreen"
    static let LOCATION_SEARCH_SCREEN = "LocationSearchScreen"
    static let OUTLET_DETAILS_SCREEN = "OutletDetailsScreen"
    static let CART_SCREEN = "CartScreen"
    static let CONFIRM_ORDER_SCREEN = "ConfirmOrderScreen"
    static let APPLYCOUPONCODE_SCREEN = "ApplyCouponCodeScreen"
    static let CANCEL_ORDER_SCREEN = "CancelOrderScreen"
    static let ORDER_SUMMARY_SCREEN = "OrderSummaryScreen"
    static let FEEDBACK_SCREEN = "FeedBackScreen"
    static let SEARCH_SCREEN = "SearchScreen"
    static let ORDER_ANYTHING_SCREEN = "OrderAnythingScreen"
    static let PICKUP_LOCATION_SCREEN = "PickupLocationScreen"
    static let SAVE_ADDRESS_SCREEN = "SaveAddressScreen"
    static let ORDER_HISTORY_SCREEN = "OrderHistoryScreen"
    static let MANAGE_PROFILE_SCREEN = "ManageProfileScreen"
    static let EDIT_PROFILE_SCREEN = "EditProfileScreen"
    static let MANAGE_ADDRESS_SCREEN = "ManageAddressScreen"
    static let ADD_ADDRESS_SCREEN = "AddAddressScreen"
    static let MANAGE_CARDS_SCREEN = "ManageCardsScreen"
    static let OFFERS_SCREEN = "OffersScreen"
    static let GETIN_TOUCH_SCREEN = "GetinTouchScreen"
    static let HELP_SUPPORT_SCREEN = "HelpSupportScreen"
    static let ABOUT_WASEL_SCREEN = "AboutWaselScreen"
    static let LEGAL_SCREEN = "LegalScreen"
    static let TERMSOFSERVICES_SCREEN  = "TermsOfServicesScreen"
    static let PRIVACY_POLICY_SCREEN = "PrivacyPolicyScreen"
    
    // Tags
    static let VIEW_STORE_TAG = "ViewStore"
//    static let SEARCH_TAG = "Search"
    static let CATEGORY_SELECTION_TAG = "CategorySelection"
    static let REGISTRATION_SCREEN_TAG = "RegistrationScreen"
    static let LOCATION_SELECTION_TAG = "LocationSelectionScreen"
    static let HOME_SCREEN_TAG = "HomeScreen"
    static let LOCATION_SEARCH_TAG = "LocationSearchScreen"
    static let OUTLET_DETAILS_TAG = "OutletDetailsScreen"
    static let CART_SCREEN_TAG = "CartScreen"
    static let CONFIRM_ORDER_TAG = "ConfirmOrderScreen"
    static let APPLY_COUPONCODE_TAG = "ApplyCouponCodeScreen"
    static let CANCEL_ORDER_TAG = "CancelOrderScreen"
    static let SEARCH_SCREEN_TAG = "SearchScreen"
    static let ORDERANYTHING_SCREEN_TAG = "OrderAnythingScreen"
    static let PICKUP_LOCATION_TAG = "PickupLocationScreen"
    static let ORDER_HISTORY_SCREEN_TAG = "OrderHistoryScreen"
    static let OFFERS_SCREEN_TAG = "OffersScreen"

    // Event keys
    static let SKIP_EVENT = "Skip"
    static let TAPONREGISTER_EVENT = "TapOnRegister"
    static let OTPSTATUS_EVENT = "OTPStatus"
    static let REGISTER_EVENT = "Register"
    static let SIGNIN_EVENT = "SignIn"
    static let FORGOT_PASSWORD_EVENT = "ForgotPassword"
    static let CHOOSE_CATEGORY_EVENT = "ChooseCategory"
    static let SEARCH_EVENT = "Search"
    static let CLEAR_CART_EVENT = "ClearCart"
    static let CART_ACTIVITY_EVENT = "CartActivity"
    static let ORDERANYTHING_EVENT = "OrderAnything"
    static let CHECKOUT_EVENT = "CheckOut"
    static let CONFIRMORDER_EVENT = "ConfirmOrder"
    static let ORDERITEMS_EVENT = "OrderItems"
    static let CANCEL_ORDER_EVENT = "CancelOrder"
    static let VIEW_STORE_ORDER_EVENT = "ViewStore"
    static let CARD_ADDED_EVENT = "CardAdded"
    static let REORDER_EVENT = "ReOrder"
    static let CONFIRM_LOCATION_EVENT = "ConfirmLocation"
}
